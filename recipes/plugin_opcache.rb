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

package 'php-fpm' do
  action :install
end

remote_file "#{Chef::Config[:file_cache_path]}/newrelic-phpopcache-#{node['cog_new-relic']['plugin_opcache']['version']}" do
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
    tar xzf newrelic-phpopcache-#{node['cog_new-relic']['plugin_opcache']['version']}.tar.gz -C node['cog_new-relic']['plugin-path']
    chmod 0644 "#{node['cog_new-relic']['plugin-path']}/newrelic-phpopcache-#{node['cog_new-relic']['plugin_opcache']['version']}"
    EOH

  not_if { ::File.exists?("#{node['cog_new-relic']['plugin-path']}/newrelic-phpopcache-#{node['cog_new-relic']['plugin_opcache']['version']}") }
end

template '/etc/newrelic/newrelic-phpopcache.ini' do
  source    'newrelic-phpopcache.ini.erb'
  variables({
    :hostname         => node.hostname,
    :nr_license       => newrelic_license,
    :server_instance  => node.hostname,
    :poll_cycle       => '60'
  })

  action :create
end

template '/etc/nginx/conf.d/status-newrelic-phpopcache.conf' do
  source    'nginx-status-plugins.conf.erb'
  variables({
    :location => '~ "^(.+\.php)($|/)"',
    :root     => "#{node['cog_new-relic']['plugin-path']}/newrelic-phpopcache-#{node['cog_new-relic']['plugin_opcache']['version']}",
    :params => {
      'access_log'              => 'off',
      'allow'                   => '127.0.0.1',
      'deny'                    => 'all',
      'fastcgi_split_path_info' => '^(.+\.php)(.*)$',
      'fastcgi_param'           => 'SCRIPT_FILENAME $document_root$fastcgi_script_name',
      'fastcgi_param'           => 'SCRIPT_NAME     $fastcgi_script_name',
      'fastcgi_param'           => 'PATH_INFO       $fastcgi_path_info',
      'include'                 => 'fastcgi_params',
      'fastcgi_pass'            => '127.0.0.1:9000'
    }
  })

  notifies :restart, 'service[nginx]'
end

  action :create
end

service 'nginx' do

  action [ :enable, :start ]
end

service 'php-fpm' do

  action [ :enable, :start ]
end
