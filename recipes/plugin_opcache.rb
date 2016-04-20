#
# Cookbook Name:: cog_newrelic
# Recipe:: php_opcache

chef_gem 'chef-vault' do
  compile_time true if respond_to?(:compile_time)
end

include_recipe 'chef-vault'

newrelic_license = chef_vault_item('newrelic', 'license_key')

# make sure nginx is installed to query the stats
package 'nginx' do
  action :install
end

template '/etc/nginx/nginx.conf' do
  source 'nginx.conf.erb'
  subscribes :install, 'package[nginx]', :delayed
  notifies :restart, 'service[nginx]'
  action :nothing
end

template '/etc/nginx/conf.d/status.conf' do
  source 'nginx-status.conf.erb'
  notifies :restart, 'service[nginx]'
  action :create
end

php_fpm_service 'php55-fpm' do
  pid '/var/run/php-fpm/php-fpm-5.5.pid'
  fpm_options 'process_control_timeout' => node['peachy_frontend']['php-fpm_process_control_timeout']
  action :create
end

php_fpm_pool 'opcache-status' do
  config_file 'opcache-status.conf'
  service_name 'php-fpm'
  process_manager 'dynamic'
  pool_user 'newrelic'
  pool_group 'newrelic'
  listen "127.0.0.1:#{node['cog_newrelic']['php']['php-fpm-port']}"
  allowed_clients '127.0.0.1'
  max_children        '1'
  start_servers       '1'
  min_spare_servers   '1'
  max_spare_servers   '1'
  max_requests        '100'
  pm_status_path('/' + node['peachy_frontend']['php-fpm_port'] + '-status')
  ping_path('/' + node['peachy_frontend']['php-fpm_port'] + '-ping')
  pool_options('php_admin_flag[log_errors]' => 'on',
               'php_admin_value[error_log]' => "#{node['cog_newrelic']['plugin-log-path']}/opcache-status.error.log")
  action :create
  notifies :restart, 'service[php-fpm]'
end

# package manager on Amazon linux installs www pool by default, get rid of it
case node['platform_family']
when 'rhel', 'fedora'
  if node['platform'] == 'amazon'
    php_fpm_pool 'www' do
      config_file "www.conf"
      action :remove
    end
  end
end

remote_file "#{Chef::Config[:file_cache_path]}/newrelic-phpopcache-#{node['cog_newrelic']['plugin_opcache']['version']}.tar.gz" do
  source "https://bitbucket.org/sking/newrelic-phpopcache/downloads/newrelic-phpopcache-#{node['cog_newrelic']['plugin_opcache']['version']}.tar.gz"
  action :create_if_missing
end

bash 'extract_plugin' do
  cwd Chef::Config[:file_cache_path]
  code <<-EOH
    tar xzf #{Chef::Config[:file_cache_path]}/newrelic-phpopcache-#{node['cog_newrelic']['plugin_opcache']['version']}.tar.gz -C #{node['cog_newrelic']['plugin-path']}
    chown -R newrelic:newrelic "#{node['cog_newrelic']['plugin-path']}/newrelic-phpopcache-#{node['cog_newrelic']['plugin_opcache']['version']}"
    chmod +x "#{node['cog_newrelic']['plugin-path']}/newrelic-phpopcache-#{node['cog_newrelic']['plugin_opcache']['version']}"
    EOH
  not_if { ::File.exist?("#{node['cog_newrelic']['plugin-path']}/newrelic-phpopcache-#{node['cog_newrelic']['plugin_opcache']['version']}") }
end

template '/etc/newrelic/newrelic-phpopcache.ini' do
  source 'newrelic_plugin_opcache.ini.erb'
  variables(hostname: node.hostname,
            nr_license: newrelic_license['license_key'],
            server_instance: node.hostname,
            poll_cycle: 60)
  action :create
end

template '/etc/nginx/conf.d/status-newrelic-phpopcache' do
  source 'nginx-status-plugins.conf.erb'
  variables(location: '/newrelic-phpopcache.php',
            params: {
              'alias' => "#{node['cog_newrelic']['plugin-path']}/newrelic-phpopcache-#{node['cog_newrelic']['plugin_opcache']['version']}/bin/newrelic-phpopcache.php",
              'access_log'              => 'off',
              'include'                 => 'fastcgi_params',
              'fastcgi_param'           => 'SCRIPT_FILENAME $request_filename',
              'fastcgi_pass'            => "127.0.0.1:#{node['cog_newrelic']['php']['php-fpm-port']}"
            })
  notifies :restart, 'service[nginx]'
  action :create
end

cron 'newrelic-phpopcache' do
  command 'curl http://localhost/newrelic-phpopcache.php 2&>1 > /dev/null'
end

service 'nginx' do
  action [:enable, :start]
end

service 'php-fpm' do
  action [:enable, :start]
end
