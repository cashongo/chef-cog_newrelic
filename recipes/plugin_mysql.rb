#
# Cookbook Name:: cog_newrelic
# Recipe:: plugin_mysql

chef_gem 'chef-vault' do
  compile_time true if respond_to?(:compile_time)
end

include_recipe 'chef-vault'

newrelic_license  = chef_vault_item("newrelic", "license_key")
mysql_access      = chef_vault_item("mysql_passwords_#{node.chef_environment}", "mysql")

# plugin dependencies
package 'java-1.7.0-openjdk'

directory node['cog_newrelic']['plugin-log-path'] do
  recursive true
  mode      0777

  action :create
end

directory node['cog_newrelic']['plugin-run-path'] do
  recursive true
  mode      0777

  action :create
end

directory node['cog_newrelic']['plugin-path'] do
  recursive true
  mode      0777

  action :create
end

# plugin installation & configuration
remote_file "#{Chef::Config[:file_cache_path]}/newrelic-mysql-#{node['cog_newrelic']['plugin_mysql']['version']}.tar.gz" do
  source  "https://github.com/newrelic-platform/newrelic_mysql_java_plugin/blob/master/dist/newrelic_mysql_plugin-#{node['cog_newrelic']['plugin_mysql']['version']}.tar.gz"

  action :create_if_missing
end

bash 'extract_plugin' do
  cwd Chef::Config[:file_cache_path]
  code <<-EOH
    tar xzf #{Chef::Config[:file_cache_path]}/newrelic-mysql-#{node['cog_newrelic']['plugin_mysql']['version']}.tar.gz -C #{node['cog_newrelic']['plugin-path']}
    chmod 0644 "#{node['cog_newrelic']['plugin-path']}/newrelic_mysql_plugin-#{node['cog_newrelic']['plugin_mysql']['version']}"
    EOH

  not_if { ::File.exists?("#{node['cog_newrelic']['plugin-path']}/newrelic_mysql_plugin-#{node['cog_newrelic']['plugin_gearman']['version']}") }
end

template "#{node['cog_newrelic']['plugin-path']}/newrelic_mysql_plugin-#{node['cog_newrelic']['plugin_mysql']['version']}/plugin.json" do
  source    'newrelic-plugin-mysql.json.cfg.erb'
  variables({
    :name     => node.hostname,
    :metrics  => node['cog_newrelic']['plugin_mysql']['metrics'],
    :user     => node['cog_newrelic']['user'],
    :passwd   => mysql_access['newrelic']
  })

  notifies :restart, 'runit_service[newrelic-plugin-mysql]'
  action :create
end

template "#{node['cog_newrelic']['plugin-path']}/newrelic_mysql_plugin-#{node['cog_newrelic']['plugin_mysql']['version']}/newrelic.json" do
  source    'newrelic.json.cfg.erb'
  variables({
    :license_key  => newrelic_license['license_key'],
    :log_level    => 'info',
    :log_path     => node['cog_newrelic']['plugin-log-path']
  })

  notifies :restart, 'runit_service[newrelic-plugin-mysql]'
  action :create
end

runit_service 'newrelic-plugin-mysql' do
  default_logger true

  action [ :enable, :start ]
end
