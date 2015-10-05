#
# Cookbook Name:: cog_newrelic
# Recipe:: plugin_meetme

chef_gem 'chef-vault' do
  compile_time true if respond_to?(:compile_time)
end

include_recipe 'chef-vault'

newrelic_license = chef_vault_item("newrelic", "license_key")

#plugin dependencies
case node['platform_family']

when 'rhel'
  package 'openssl-devel'
  package 'libffi-devel'
  package 'python27-devel'
end

include_recipe 'python::package'
include_recipe 'python::pip'

python_pip 'requests[security]'
python_pip 'newrelic-plugin-agent'

directory node['cog_newrelic']['plugin-log-path'] do
  recursive true
  mode      0777
  action    :create
end

directory node['cog_newrelic']['plugin-run-path'] do
  recursive true
  mode      0777
  action    :create
end

directory node['cog_newrelic']['plugin-path'] do
  recursive true
  mode      0777
  action    :create
end

# plugin installation & configuration
template '/etc/newrelic/newrelic-plugin-agent.cfg' do
  source    'newrelic-plugin-agent.cfg.erb'
  variables({
    :user         => node['cog_newrelic']['user'],
    :license_key  => newrelic_license['license_key'],
    :hostname     => node.hostname,
    :log_path     => node['cog_newrelic']['plugin-log-path'],
    :include_memcached  => node['cog_newrelic']['plugin-agent']['memcached'],
    :include_php_fpm    => node['cog_newrelic']['plugin-agent']['php-fpm'],
    :php_fpm_pool       => node['cog_newrelic']['plugin-agent']['php-fpm-pools'],
    :include_nginx      => node['cog_newrelic']['plugin-agent']['nginx'],
    :include_mongodb    => node['cog_newrelic']['plugin-agent']['mongodb'],
    :mongodb_admin      => node['cog_newrelic']['plugin-agent']['mongodb-admin'],
    :mongodb_dbs        => node['cog_newrelic']['plugin-agent']['mongodb-dbs']
  })

  notifies :restart, 'runit_service[newrelic-plugin-agent]'
  action :create
end

# PLUGIN PHP-FPM
if node['cog_newrelic']['plugin-agent']['php-fpm']
  # plugin dependencies
  package 'nginx' do
    action    :install
  end

  template '/etc/nginx/nginx.conf' do
    source    'nginx.conf.erb'
    subscribes :install, 'package[nginx]', :delayed
    notifies  :restart, 'service[nginx]'
    action    :nothing
  end

  template "/etc/nginx/conf.d/status.conf" do
   source   'nginx-status.conf.erb'
   notifies :restart, 'service[nginx]'
   action   :create
  end

  node['cog_newrelic']['plugin-agent']['php-fpm-pools'].each_pair do | pool,value |
    template "/etc/nginx/conf.d/status-newrelic-meetme-php-fpm-#{value[:name]}" do
     source    'nginx-status-plugins.conf.erb'
     variables({
       :location => "~ ^/(#{value[:port]}-status|#{value[:port]}-ping)$",
       :params => {
         'access_log'              => 'off',
         'allow'                   => '127.0.0.1',
         'deny'                    => 'all',
         'fastcgi_param'           => 'SCRIPT_FILENAME $request_filename',
         'include'                 => 'fastcgi_params',
         'fastcgi_pass'            => "127.0.0.1:#{value[:port]}"
       }
     })
     notifies :restart, 'service[nginx]'
     action :create
    end
  end

  service 'nginx' do
    action [ :enable, :start ]
  end
end

# PLUGIN NGINX
if node['cog_newrelic']['plugin-agent']['nginx']
  # plugin dependencies
  package 'nginx' do
    action    :install
  end

  template '/etc/nginx/nginx.conf' do
    source    'nginx.conf.erb'
    subscribes :install, 'package[nginx]', :delayed
    notifies  :restart, 'service[nginx]'
    action    :nothing
  end

  template "/etc/nginx/conf.d/status.conf" do
   source    'nginx-status.conf.erb'

   notifies :restart, 'service[nginx]'
   action :create
  end

  template '/etc/nginx/conf.d/status-newrelic-meetme-nginx' do
   source    'nginx-status-plugins.conf.erb'
   variables({
     :location => '/nginx_stub_status',
     :params => {
       'access_log'              => 'off',
       'allow'                   => '127.0.0.1',
       'deny'                    => 'all',
       'stub_status'             => 'on'
       }
     })

   notifies :restart, 'service[nginx]'
   action :create
  end

  service 'nginx' do
    action [ :enable, :start ]
  end
end

# PLUGIN MONGODB
if node['cog_newrelic']['plugin-agent']['mongodb']
  python_pip 'newrelic-plugin-agent[mongodb]'
end

runit_service 'newrelic-plugin-agent' do
  default_logger true

  action [ :enable, :start ]
end
