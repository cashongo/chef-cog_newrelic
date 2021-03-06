#
# Cookbook Name:: cog_newrelic
# Recipe:: php_gearman

chef_gem 'chef-vault' do
  compile_time true if respond_to?(:compile_time)
end

include_recipe 'chef-vault'

newrelic_license = chef_vault_item('newrelic', 'license_key')

# plugin dependencies
yum_package 'ruby-devel'
gem_package 'io-console'
gem_package 'bundler'

# plugin installation & configuration
remote_file "#{Chef::Config[:file_cache_path]}/newrelic-gearman-#{node['cog_newrelic']['plugin_gearman']['version']}.tar.gz" do
  source "https://github.com/channelgrabber/newrelic-gearman-plugin/archive/#{node['cog_newrelic']['plugin_gearman']['version']}.tar.gz"

  action :create_if_missing
end

bash 'extract_plugin' do
  cwd Chef::Config[:file_cache_path]
  code <<-EOH
    tar xzf #{Chef::Config[:file_cache_path]}/newrelic-gearman-#{node['cog_newrelic']['plugin_gearman']['version']}.tar.gz -C #{node['cog_newrelic']['plugin-path']}
    chmod 0644 "#{node['cog_newrelic']['plugin-path']}/newrelic-gearman-plugin-#{node['cog_newrelic']['plugin_gearman']['version']}"
    EOH

  not_if { ::File.exist?("#{node['cog_newrelic']['plugin-path']}/newrelic-gearman-plugin-#{node['cog_newrelic']['plugin_gearman']['version']}") }
end

# run bundler
execute 'bundle install' do
  cwd "#{node['cog_newrelic']['plugin-path']}/newrelic-gearman-plugin-#{node['cog_newrelic']['plugin_gearman']['version']}"
  not_if "bundle check --gemfile='#{node['cog_newrelic']['plugin-path']}/newrelic-gearman-plugin-#{node['cog_newrelic']['plugin_gearman']['version']}'/Gemfile"
end

template "#{node['cog_newrelic']['plugin-path']}/newrelic-gearman-plugin-#{node['cog_newrelic']['plugin_gearman']['version']}/config/newrelic_plugin.yml" do
  source 'newrelic-plugin-gearman.cfg.erb'
  variables(hostname: node.hostname,
            license_key: newrelic_license['license_key'])
  action :create
end

runit_service 'newrelic-plugin-gearman' do
  default_logger true
  action [:enable, :start]
end

# buggy gearman monitor should be restarted once a display_errors
cron 'newrelic-plugin-gearman' do
  minute '45'
  hour '2'
  command '/sbin/service newrelic-plugin-gearman stop 2&>1 > /dev/null && /sbin/service newrelic-plugin-gearman start 2&>1 > /dev/null'
  user 'root'
end
