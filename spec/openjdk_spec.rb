require 'spec_helper'

describe 'java::openjdk' do
  platforms = {
    'ubuntu-10.04' => {
      'packages' => ['openjdk-6-jdk', 'openjdk-6-jre-headless'],
      'platform_family' => 'debian',
      'update_alts' => true
    },
    'ubuntu-12.04' => {
      'packages' => ['openjdk-6-jdk', 'openjdk-6-jre-headless'],
      'platform_family' => 'debian',
      'update_alts' => true
    },
    'debian-6' => {
      'packages' => ['openjdk-6-jdk', 'openjdk-6-jre-headless'],
      'platform_family' => 'debian',
      'update_alts' => true
    },
    'debian-7' => {
      'packages' => ['openjdk-6-jdk', 'openjdk-6-jre-headless'],
      'platform_family' => 'debian',
      'update_alts' => true
    },
    'centos-6.4' => {
      'packages' => ['java-1.6.0-openjdk', 'java-1.6.0-openjdk-devel'],
      'platform_family' => 'rhel',
      'update_alts' => true
    },
    'smartos-joyent_20130111T180733Z' => {
      'packages' => ['sun-jdk6', 'sun-jre6'],
      'platform_family' => 'smartos',
      'update_alts' => false
    }
  }

  platforms.each do |platform, data|
    parts = platform.split('-')
    os = parts[0]
    version = parts[1]
    context "On #{os} #{version}" do
      let(:chef_run) do
        runner = ChefSpec::Runner.new('platform' => os, 'version' => version)
        runner.node.set['platform_family'] = data['platform_family']
        runner.converge(described_recipe)
      end

      data['packages'].each do |pkg|
        it "installs package #{pkg}" do
          expect(chef_run).to install_package(pkg)
        end
      end

      it 'sends notification to update-java-alternatives' do
        if data['update_alts']
          expect(chef_run).to notify('java_alternatives[set-java-alternatives]').to(:set)
        else
          expect(chef_run).to_not notify('java_alternatives[set-java-alternatives]').to(:set)
        end
      end
    end
  end

  describe 'conditionally includes set attributes' do
    context 'when java_home and openjdk_packages are set' do
      let(:chef_run) do
        runner = ChefSpec::Runner.new(
          'platform' => 'ubuntu',
          'version' => '12.04'
        )
        runner.node.set['java']['java_home'] = "/some/path"
        runner.node.set['java']['openjdk_packages'] = ['dummy','stump']
        runner.converge(described_recipe)
      end

      it 'does not include set_attributes_from_version' do
        expect(chef_run).to_not include_recipe('java::set_attributes_from_version')
      end
    end

    context 'when java_home and openjdk_packages are not set' do
      let(:chef_run) do
        runner = ChefSpec::Runner.new(
          'platform' => 'ubuntu',
          'version' => '12.04'
        )
        runner.converge(described_recipe)
      end

      it 'does not include set_attributes_from_version' do
        expect(chef_run).to include_recipe('java::set_attributes_from_version')
      end
    end
  end

  describe 'license acceptance file' do
    {'centos' => '6.3','ubuntu' => '12.04'}.each_pair do |platform, version|
      context platform do
        let(:chef_run) do
          ChefSpec::Runner.new(:platform => platform, :version => version).converge('java::openjdk')
        end

        it 'does not write out license file' do
          expect(chef_run).not_to create_file("/opt/local/.dlj_license_accepted")
        end
      end
    end

    context 'smartos' do
      let(:chef_run) do
        ChefSpec::Runner.new(:platform => 'smartos', :version => 'joyent_20130111T180733Z', :evaluate_guards => true)
      end

      context 'when auto_accept_license is true' do
        it 'writes out a license acceptance file' do
          chef_run.node.set['java']['accept_license_agreement'] = true
          expect(chef_run.converge(described_recipe)).to create_file("/opt/local/.dlj_license_accepted")
        end
      end

      context 'when auto_accept_license is false' do
        it 'does not write license file' do
          chef_run.node.set['java']['accept_license_agreement'] = false
          expect(chef_run.converge(described_recipe)).not_to create_file("/opt/local/.dlj_license_accepted")
        end
      end
    end

  end
end
