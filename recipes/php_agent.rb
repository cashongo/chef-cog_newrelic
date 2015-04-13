#
# Cookbook Name:: cog_newrelic
# Recipe:: php_agent
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

template '/etc/newrelic/newrelic.cfg' do
  source 'newrelic_php_daemon.cfg.erb'
  mode      0644
  owner     'root'
  group     'root'
  variables({
  })
end

yum_package 'newrelic-php5' do

  action :install
end

template '/etc/php.d/newrelic.ini' do
  source 'newrelic.ini.erb'
  mode      0644
  owner     'root'
  group     'root'
  variables({
    :license_key    => newrelic_license["license_key"],
    :app_name       => node['cog_newrelic']['php_agent']['app_name'],
    :framework      => node['cog_newrelic']['php_agent']['framework']
  })

#TODO: make this version agnostic
  notifies :restart, 'service[php-fpm-5.5]'
end
