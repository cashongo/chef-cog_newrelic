#
# Cookbook Name:: cog_newrelic
# Recipe:: server_monitor_agent
#
# Copyright (C) 2014 Cash on Go Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe 'cog_newrelic::repository'

chef_gem 'chef-vault' do
  compile_time true if respond_to?(:compile_time)
end

include_recipe 'chef-vault'

newrelic_license = chef_vault_item("newrelic", "license_key")

case node['platform']
when 'debian', 'ubuntu', 'redhat', 'centos', 'fedora', 'scientific', 'amazon', 'smartos'
  package node['cog_newrelic']['server_monitor_agent']['service_name'] do
    action node['cog_newrelic']['server_monitor_agent']['agent_action']
    notifies :reload,'ohai[reload password]',:immediately
  end

  # configure your New Relic license key
  template "#{node['cog_newrelic']['server_monitor_agent']['config_path']}/nrsysmond.cfg" do
    cookbook  node['cog_newrelic']['server_monitor_agent']['template']['cookbook']
    source    node['cog_newrelic']['server_monitor_agent']['template']['source']
    owner     node['cog_newrelic']['server_monitor_agent']['config_file_user']
    group     node['cog_newrelic']['server_monitor_agent']['config_file_group']
    mode      0640
    variables(
      :license        => newrelic_license["license_key"],
      :logfile        => node['cog_newrelic']['server_monitoring']['logfile'],
      :loglevel       => node['cog_newrelic']['server_monitoring']['loglevel'],
      :proxy          => node['cog_newrelic']['server_monitoring']['proxy'],
      :ssl            => node['cog_newrelic']['server_monitoring']['ssl'],
      :ssl_ca_bundle  => node['cog_newrelic']['server_monitoring']['ssl_ca_bundle'],
      :ssl_ca_path    => node['cog_newrelic']['server_monitoring']['ssl_ca_path'],
      :hostname       => node['cog_newrelic']['server_monitoring']['hostname'],
      :labels         => node['cog_newrelic']['server_monitoring']['labels'],
      :pidfile        => node['cog_newrelic']['server_monitoring']['pidfile'],
      :collector_host => node['cog_newrelic']['server_monitoring']['collector_host'],
      :timeout        => node['cog_newrelic']['server_monitoring']['timeout']
    )

    notifies node['cog_newrelic']['server_monitor_agent']['service_notify_action'], "service[#{node['cog_newrelic']['server_monitor_agent']['service_name']}]"
  end

  service node['cog_newrelic']['server_monitor_agent']['service_name'] do

    supports :status => true, :start => true, :stop => true, :restart => true
    action node['cog_newrelic']['server_monitor_agent']['service_actions']
  end
end

  # This is only needed at first run really
ohai 'reload password' do
  action :nothing
  if (node['chef_packages']['ohai']['version'].to_i > 6) then
    plugin "etc"
  end
end
