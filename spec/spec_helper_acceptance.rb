#! /usr/bin/env ruby -S rspec

# This file comes from puppetlabs-stdlib
# which is licensed under the Apache-2.0 License.
# https://github.com/puppetlabs/puppetlabs-stdlib
# (c) 2015-2015 Puppetlabs and puppetlabs-stdlib contributors

require 'puppet'
require 'puppet/util/package'
require 'beaker-rspec'
require 'beaker/puppet_install_helper'

UNSUPPORTED_PLATFORMS = [].freeze

run_puppet_install_helper

RSpec.configure do |c|
  # Project root
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    if ENV['FUTURE_PARSER'] == 'yes'
      default[:default_apply_opts] ||= {}
      default[:default_apply_opts][:parser] = 'future'
    end

    puppet_version = get_puppet_version
    if Puppet::Util::Package.versioncmp(puppet_version, '4.0.0') < 0
      copy_root_module_to(default, source: proj_root, module_name: 'corosync', target_module_path: '/etc/puppet/modules')
    else
      copy_root_module_to(default, source: proj_root, module_name: 'corosync')
    end


    hosts.each do |host|
      on host, puppet('module', 'install', 'puppetlabs-stdlib'), acceptable_exit_codes: [0, 1]
      if fact('osfamily') =~ %r{RedHat}i and Puppet::Util::Package.versioncmp(fact('operatingsystemmajrelease'), '7.0') < 0
        shell('git clone https://github.com/kbon/puppet-cman /etc/puppetlabs/code/modules/cman')
        on host, puppet('apply', '-e', 'include cman')
        on host, puppet('apply', '-e', 'cman_cluster { "test": ensure => present, multicast => "10.1.1.1", altmulticast => "10.1.1.2", }')
        on host, puppet('apply', '-e', 'cman_clusternode { "127.0.0.1": ensure => present, }')
        on host, puppet('apply', '-e', 'include cman::service')
      end
    end
  end
end

def is_future_parser_enabled?
  # rubocop:disable Style/GuardClause
  if default[:type] == 'aio'
    # rubocop:enable Style/GuardClause
    return true
  elsif default[:default_apply_opts]
    return default[:default_apply_opts][:parser] == 'future'
  end
  false
end

# rubocop:disable Style/AccessorMethodName
def get_puppet_version
  (on default, puppet('--version')).output.chomp
end
# rubocop:enable Style/AccessorMethodName

RSpec.shared_context 'with faked facts' do
  let(:facts_d) do
    puppet_version = get_puppet_version
    if fact('osfamily') =~ %r{windows}i
      if fact('kernelmajversion').to_f < 6.0
        'C:/Documents and Settings/All Users/Application Data/PuppetLabs/facter/facts.d'
      else
        'C:/ProgramData/PuppetLabs/facter/facts.d'
      end
    elsif Puppet::Util::Package.versioncmp(puppet_version, '4.0.0') < 0 && fact('is_pe', '--puppet') == 'true'
      '/etc/puppetlabs/facter/facts.d'
    else
      '/etc/facter/facts.d'
    end
  end

  before :each do
    # No need to create on windows, PE creates by default
    shell("mkdir -p '#{facts_d}'") if fact('osfamily') !~ %r{windows}i
  end

  after :each do
    shell("rm -f '#{facts_d}/fqdn.txt'", acceptable_exit_codes: [0, 1])
  end

  def fake_fact(name, value)
    shell("echo #{name}=#{value} > '#{facts_d}/#{name}.txt'")
  end
end
