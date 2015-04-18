#
# Cookbook Name:: cog_newrelic
# Recipe:: php_meetme

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

package 'libffi-devel'

include_recipe 'python'

python_pip 'requests[security]'
python_pip 'newrelic-plugin-agent'

python_pip 'newrelic-plugin-agent[mongodb]'

directory node['cog_new-relic']['plugin-log-path'] do
  recursive true
  mode      0777

  action :create
end

directory node['cog_new-relic']['plugin-run-path'] do
  recursive true
  mode      0777

  action :create
end

template '/etc/newrelic/newrelic-plugin-agent.cfg' do
  source    'newrelic-plugin-agent.cfg.erb'
  variables({
    :user         => node['cog_newrelic']['user'],
    :license_key  => newrelic_license['license_key'],
    :hostname     => node.hostname,
    :log_path     => node['cog_new-relic']['plugin-log-path'],
    :include_memcached  => node['cog_newrelic']['plugin-agent']['memcached'],
    :include_php_fpm    => node['cog_newrelic']['plugin-agent']['php-fpm'],
    :include_nginx      => node['cog_newrelic']['plugin-agent']['nginx'],
    :php_fpm_pool       => node['cog_newrelic']['plugin-agent']['php-fpm-pools']
  })

  notifies :restart, 'runit_service[newrelic-plugin-agent]'
  action :create
end

if node['cog_newrelic']['plugin-agent']['php-fpm']
  node['cog_newrelic']['plugin-agent']['php-fpm-pools'].each_pair do | pool,value |
    template "/etc/nginx/conf.d/status-newrelic-meetme-php-fpm-#{value[:name]}" do
     source    'nginx-status-plugins.conf.erb'
     variables({
       :location => "~ ^/(#{value[:port]}-status|#{value[:port]}-ping)$",
       :params => {
         'access_log'              => 'off',
         'allow'                   => '127.0.0.1',
         'deny'                    => 'all',
         'fastcgi_split_path_info' => '^(.+\.php)(.*)$',
         'fastcgi_param'           => 'SCRIPT_FILENAME $document_root$fastcgi_script_name',
         'fastcgi_param'           => 'SCRIPT_NAME     $fastcgi_script_name',
         'fastcgi_param'           => 'PATH_INFO       $fastcgi_path_info',
         'include'                 => 'fastcgi_params',
         'fastcgi_pass'            => "127.0.0.1:#{value[:port]}"
       }
     })

     notifies :restart, 'service[nginx]'
     action :create
    end
  end
end

if node['cog_newrelic']['plugin-agent']['nginx']
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
end

runit_service 'newrelic-plugin-agent' do
  default_logger true

  action [ :enable, :restart ]
end

service 'nginx' do

  action [ :enable, :start ]
end
