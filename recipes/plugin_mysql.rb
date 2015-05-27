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
package node['cog_newrelic']['plugin_mysql']['java_package']

if (node['cog_newrelic']['plugin_mysql']['init_style'] == "systemd" ) then
  notifyname = 'service[newrelic-plugin-mysql]'
else
  notifyname = 'runit_service[newrelic-plugin-mysql]'
end

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
  mode      0700
  owner node['cog_newrelic']['daemon_user']

  action :create
end

# plugin installation & configuration
remote_file "#{Chef::Config[:file_cache_path]}/newrelic-mysql-#{node['cog_newrelic']['plugin_mysql']['version']}.tar.gz" do
  source  "https://github.com/newrelic-platform/newrelic_mysql_java_plugin/blob/master/dist/newrelic_mysql_plugin-#{node['cog_newrelic']['plugin_mysql']['version']}.tar.gz?raw=true"

  action :create_if_missing
end

bash 'extract_plugin' do
  cwd Chef::Config[:file_cache_path]
  code <<-EOH
    tar xzf #{Chef::Config[:file_cache_path]}/newrelic-mysql-#{node['cog_newrelic']['plugin_mysql']['version']}.tar.gz -C #{node['cog_newrelic']['plugin-path']}
    chmod 0755 "#{node['cog_newrelic']['plugin-path']}/newrelic_mysql_plugin-#{node['cog_newrelic']['plugin_mysql']['version']}"
    EOH

  not_if { ::File.exists?("#{node['cog_newrelic']['plugin-path']}/newrelic_mysql_plugin-#{node['cog_newrelic']['plugin_mysql']['version']}") }
end

template "#{node['cog_newrelic']['plugin-path']}/newrelic_mysql_plugin-#{node['cog_newrelic']['plugin_mysql']['version']}/config/plugin.json" do
  source    'newrelic-plugin-mysql.json.cfg.erb'
  variables ({
    :name     => node.hostname,
    :metrics  => node['cog_newrelic']['plugin_mysql']['metrics'],
    :user     => node['cog_newrelic']['daemon_user'],
    :passwd   => mysql_access['newrelic']
  })

  notifies :restart, notifyname
  action :create
end

template "#{node['cog_newrelic']['plugin-path']}/newrelic_mysql_plugin-#{node['cog_newrelic']['plugin_mysql']['version']}/config/newrelic.json" do
  source    'newrelic.json.cfg.erb'
  variables({
    :license_key  => newrelic_license['license_key'],
    :log_level    => 'info',
    :log_path     => node['cog_newrelic']['plugin-log-path']
  })

  notifies :restart, notifyname
  action :create
end

if (node['cog_newrelic']['plugin_mysql']['init_style'] == 'systemd') then

  # This is only needed at first run really
  ohai "reload_passwd" do
    action :reload
    if (node['chef_packages']['ohai']['version'].to_i > 6) then
      plugin "etc"
    end
  end

  template '/usr/lib/systemd/system/newrelic-plugin-mysql.service' do
    source 'newrelic_mysql_plugin.systemd.erb'
    owner 'root'
    group 'root'
    mode '0644'
    action :create
    variables lazy {
      {
      :user => node['cog_newrelic']['daemon_user'],
      :group => node['etc']['passwd'][node['cog_newrelic']['daemon_user']]['gid'],
      :workdir => "#{node['cog_newrelic']['plugin-path']}/newrelic_mysql_plugin-#{node['cog_newrelic']['plugin_mysql']['version']}/"
      }
    }
    notifies :run,'execute[systemd-reload]', :immediately
  end

  execute 'systemd-reload' do
    command 'systemctl daemon-reload'

    action :nothing
  end
  service 'newrelic-plugin-mysql' do
    action [:enable, :start]
  end
else
  runit_service 'newrelic-plugin-mysql' do
    default_logger true

    action [ :enable, :start ]
  end
end
