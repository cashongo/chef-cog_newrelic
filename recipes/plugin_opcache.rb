#
# Cookbook Name:: cog_newrelic
# Recipe:: php_opcache

chef_gem 'chef-vault' do
  compile_time true if respond_to?(:compile_time)
end

include_recipe 'chef-vault'

newrelic_license = chef_vault_item("newrelic", "license_key")

# make sure nginx is installed to query the stats
package 'nginx' do
  action :install
end

template "/etc/nginx/nginx.conf" do
  source    'nginx.conf.erb'
  notifies  :restart, 'service[nginx]'
  action    :create
end

template "/etc/nginx/conf.d/status.conf" do
  source    'nginx-status.conf.erb'
  notifies  :restart, 'service[nginx]'
  action    :create
end

package 'php55-fpm' do
  action :install
end

php_fpm_pool "opcache-status" do
    process_manager     'dynamic'
    user                'newrelic'
    group               'newrelic'
    listen              "127.0.0.1:#{node['cog_newrelic']['php']['php-fpm-port']}"
    allowed_clients     '127.0.0.1'
    max_children        '1'
    start_servers       '1'
    min_spare_servers   '1'
    max_spare_servers   '1'
    max_requests        '100'
    php_options          'php_admin_flag[log_errors]'         => 'on',
                         'php_admin_value[error_log]'         => "/var/log/newrelic/opcache-status.php-fpm.error.log"
    enable true
end

# package manager on Amazon linux installs www pool by default, get rid of it
case node['platform_family']
when 'rhel', 'fedora'
  if node['platform'] == 'amazon'
    php_fpm_pool 'www' do
      enable false
    end
  end
end

remote_file "#{Chef::Config[:file_cache_path]}/newrelic-phpopcache-#{node['cog_newrelic']['plugin_opcache']['version']}.tar.gz" do
  source  "https://bitbucket.org/sking/newrelic-phpopcache/downloads/newrelic-phpopcache-#{node['cog_newrelic']['plugin_opcache']['version']}.tar.gz"
  action :create_if_missing
end

directory node['cog_newrelic']['plugin-path'] do
  recursive true
  mode      0775
  action    :create
end

bash 'extract_plugin' do
  cwd Chef::Config[:file_cache_path]
  code <<-EOH
    tar xzf #{Chef::Config[:file_cache_path]}/newrelic-phpopcache-#{node['cog_newrelic']['plugin_opcache']['version']}.tar.gz -C #{node['cog_newrelic']['plugin-path']}
    chown -R nginx:root "#{node['cog_newrelic']['plugin-path']}/newrelic-phpopcache-#{node['cog_newrelic']['plugin_opcache']['version']}"
    EOH
  not_if { ::File.exists?("#{node['cog_newrelic']['plugin-path']}/newrelic-phpopcache-#{node['cog_newrelic']['plugin_opcache']['version']}") }
end

template '/etc/newrelic/newrelic-phpopcache.ini' do
  source    'newrelic_plugin_opcache.ini.erb'
  variables({
    :hostname         => node.hostname,
    :nr_license       => newrelic_license['license_key'],
    :server_instance  => node.hostname,
    :poll_cycle       => 60
  })
  action :create
end

template '/etc/nginx/conf.d/status-newrelic-phpopcache' do
  source    'nginx-status-plugins.conf.erb'
  variables({
    :location => '/newrelic-phpopcache.php',
    :params => {
      'alias'                   => "#{node['cog_newrelic']['plugin-path']}/newrelic-phpopcache-#{node['cog_newrelic']['plugin_opcache']['version']}/bin/newrelic-phpopcache.php",
      'access_log'              => 'off',
      'include'                 => 'fastcgi_params',
      'fastcgi_param'           => 'SCRIPT_FILENAME $request_filename',
      'fastcgi_pass'            => "127.0.0.1:#{node['cog_newrelic']['php']['php-fpm-port']}"
    }
  })
  notifies :restart, 'service[nginx]'
  action :create
end

template '/etc/nginx/conf.d/status-php-fpm-status' do
  source    'nginx-status-plugins.conf.erb'
  variables({
    :location => '~ ^/(status|ping)$',
    :params => {
      'include'                 => 'fastcgi_params',
      'fastcgi_pass'            => "127.0.0.1:#{node['cog_newrelic']['php']['php-fpm-port']}"
    }
  })
  notifies :restart, 'service[nginx]'
  action :create
end

cron 'newrelic-phpopcache' do
  command 'curl http://localhost/newrelic-phpopcache.php 2&>1 > /dev/null'
end

service 'nginx' do
  action [ :enable, :start ]
end

service 'php-fpm-5.5' do
  action [ :enable, :start ]
end
