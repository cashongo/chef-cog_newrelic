#
# Cookbook Name:: cog_newrelic
# Recipe:: php_gearman

chef_gem 'chef-vault' do
  compile_time true if respond_to?(:compile_time)
end

include_recipe 'chef-vault'

newrelic_license = chef_vault_item("newrelic", "license_key")

remote_file "#{Chef::Config[:file_cache_path]}/newrelic-gearman-#{node['cog_new-relic']['plugin_gearman']['version']}.tar.gz" do
  source  "https://github.com/channelgrabber/newrelic-gearman-plugin/archive/#{node['cog_new-relic']['plugin_gearman']['version']}.tar.gz"

  action :create_if_missing
end

directory node['cog_new-relic']['plugin-path'] do
  recursive true
  mode      0777

  action :create
end

bash 'extract_plugin' do
  cwd Chef::Config[:file_cache_path]
  code <<-EOH
    tar xzf #{Chef::Config[:file_cache_path]}/newrelic-gearman-#{node['cog_new-relic']['plugin_gearman']['version']}.tar.gz -C #{node['cog_new-relic']['plugin-path']}
    chmod 0644 "#{node['cog_new-relic']['plugin-path']}/newrelic-gearman-#{node['cog_new-relic']['plugin_gearman']['version']}"
    EOH

  not_if { ::File.exists?("#{node['cog_new-relic']['plugin-path']}/newrelic-gearman-#{node['cog_new-relic']['plugin_gearman']['version']}") }
end

# runb bundler

template "#{node['cog_new-relic']['plugin-path']}/newrelic-gearman-#{node['cog_new-relic']['plugin_gearman']['version']}/config/newrelic_plugin.yml" do
  source    'newrelic-plugin-gearman.cfg.erb'
  variables({
    :hostname         => node.hostname,
    :nr_license       => newrelic_license['license_key'],
  })

  action :create
end
