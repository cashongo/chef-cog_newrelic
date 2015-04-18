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

template "/etc/nginx/conf.d/status.conf" do
 source    'nginx-status.conf.erb'

 notifies :restart, 'service[nginx]'
 action :create
end

package 'php55-fpm' do
  action :install
end

php_fpm_pool "opcache-status" do
    process_manager     'dynamic'
    user                'newrelic'
    group               'newrelic'
    listen              "127.0.0.1:9100"
    allowed_clients     '127.0.0.1'
    max_children        '1'
    start_servers       '1'
    min_spare_servers   '1'
    max_spare_servers   '1'
    max_requests        '100'
end

remote_file "#{Chef::Config[:file_cache_path]}/newrelic-phpopcache-#{node['cog_new-relic']['plugin_opcache']['version']}.tar.gz" do
  source  "https://bitbucket.org/sking/newrelic-phpopcache/downloads/newrelic-phpopcache-#{node['cog_new-relic']['plugin_opcache']['version']}.tar.gz"

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
    tar xzf #{Chef::Config[:file_cache_path]}/newrelic-phpopcache-#{node['cog_new-relic']['plugin_opcache']['version']}.tar.gz -C #{node['cog_new-relic']['plugin-path']}
    chmod 0644 "#{node['cog_new-relic']['plugin-path']}/newrelic-phpopcache-#{node['cog_new-relic']['plugin_opcache']['version']}"
    EOH

  not_if { ::File.exists?("#{node['cog_new-relic']['plugin-path']}/newrelic-phpopcache-#{node['cog_new-relic']['plugin_opcache']['version']}") }
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
    :location => '~ "^(.+\.php)($|/)"',
    :root     => "#{node['cog_new-relic']['plugin-path']}/newrelic-phpopcache-#{node['cog_new-relic']['plugin_opcache']['version']}/bin",
    :params => {
      'access_log'              => 'off',
      'allow'                   => '127.0.0.1',
      'deny'                    => 'all',
      'fastcgi_param'           => 'SCRIPT_FILENAME $request_filename',
      'include'                 => 'fastcgi_params',
      'fastcgi_pass'            => '127.0.0.1:9000'
    }
  })

  notifies :restart, 'service[nginx]'
  action :create
end

cron 'newrelic-phpopcache' do
  hour '5'
  minute '0'
  command 'curl http://localhost/newrelic-phpopcache.php 2&>1 > /dev/null'
end

service 'nginx' do

  action [ :enable, :start ]
end

service 'php-fpm-5.5' do

  action [ :enable, :start ]
end
