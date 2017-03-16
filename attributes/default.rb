default['cog_newrelic']['license']                            = nil
default['cog_newrelic']['user']                               = 'newrelic'
# FIXME: under user is redefined as nil ?
default['cog_newrelic']['daemon_user']                        = 'newrelic'
default['cog_newrelic']['server_monitoring']['license']       = nil
default['cog_newrelic']['application_monitoring']['license']  = nil

default['cog_newrelic']['proxy']                                      = nil
default['cog_newrelic']['server_monitoring']['proxy']                 = node['cog_newrelic']['proxy']
default['cog_newrelic']['application_monitoring']['daemon']['proxy']  = node['cog_newrelic']['proxy']

default['cog_newrelic']['server_monitoring']['logfile']         = nil
default['cog_newrelic']['server_monitoring']['loglevel']        = nil
default['cog_newrelic']['server_monitoring']['ssl']             = nil
default['cog_newrelic']['server_monitoring']['ssl_ca_bundle']   = nil
default['cog_newrelic']['server_monitoring']['ssl_ca_path']     = nil
default['cog_newrelic']['server_monitoring']['hostname']        = node['fqdn']
default['cog_newrelic']['server_monitoring']['pidfile']         = nil
default['cog_newrelic']['server_monitoring']['collector_host']  = nil
default['cog_newrelic']['server_monitoring']['timeout']         = nil
default['cog_newrelic']['server_monitoring']['labels']          = nil

default['cog_newrelic']['repository']['repository_key'] = '548C16BF'
default['cog_newrelic']['repository']['repository_action'] = :install

default['cog_newrelic']['server_monitor_agent']['agent_action'] = :install

case node['platform']
when 'smartos'
  default['cog_newrelic']['server_monitor_agent']['service_name']       = 'nrsysmond'
  default['cog_newrelic']['server_monitor_agent']['config_file_group']  = 'root'
  default['cog_newrelic']['server_monitor_agent']['config_path']        = '/opt/local/etc'
else
  default['cog_newrelic']['server_monitor_agent']['service_name']       = 'newrelic-sysmond'
  default['cog_newrelic']['server_monitor_agent']['config_path']        = '/etc/newrelic'
  default['cog_newrelic']['server_monitor_agent']['config_file_group']  = 'newrelic'
end

default['cog_newrelic']['server_monitor_agent']['service_notify_action']  = :restart
default['cog_newrelic']['server_monitor_agent']['service_actions']        = [:enable, :start]
default['cog_newrelic']['server_monitor_agent']['config_file_user']       = 'root'
default['cog_newrelic']['server_monitor_agent']['template']['cookbook']   = 'cog_newrelic'
default['cog_newrelic']['server_monitor_agent']['template']['source']     = 'nrsysmond.cfg.erb'

default['cog_newrelic']['php_agent']['app_name']                          = 'CoG App'
default['cog_newrelic']['php_agent']['framework']                         = ''

default['cog_newrelic']['plugin-path']                                   = '/opt/newrelic'
default['cog_newrelic']['plugin-log-path']                               = '/var/log/newrelic-plugins'
default['cog_newrelic']['plugin-run-path']                               = '/var/run/newrelic'
default['cog_newrelic']['plugin_opcache']['version']                     = '1.0.3'
default['cog_newrelic']['plugin_opcache']['php-fpm-version']             = 'php55-fpm'
default['cog_newrelic']['plugin_opcache']['php-fpm-version-string'] = '5.5'
default['cog_newrelic']['plugin_opcache']['php-fpm-port']                = 9100
default['cog_newrelic']['plugin_gearman']['version']                     = '0.2.0'
default['cog_newrelic']['plugin_mysql']['version']                       = '2.0.0'
default['cog_newrelic']['plugin_mysql']['metrics']                       = 'status,newrelic'

if platform_family == 'rhel' && platform_version[0, 1] == '7'
  default['cog_newrelic']['plugin_mysql']['java_package'] = 'java-1.8.0-openjdk'
  default['cog_newrelic']['plugin_mysql']['init_style'] = 'systemd'
else
  default['cog_newrelic']['plugin_mysql']['java_package'] = 'java-1.7.0-openjdk'
  default['cog_newrelic']['plugin_mysql']['init_style'] = 'runit'
end

default['cog_newrelic']['plugin-agent']['memcached']                      = nil
default['cog_newrelic']['plugin-agent']['php-fpm']                        = nil
default['cog_newrelic']['plugin-agent']['nginx']                          = nil
default['cog_newrelic']['plugin-agent']['mongodb']                        = nil
default['cog_newrelic']['plugin-agent']['postgresql']                     = nil
default['cog_newrelic']['plugin-agent']['php-fpm-pools']                  = nil # expects a hash of hashes: { 'www' => { :name => 'www', :path => '/php-status-www', :port = '9000'} }
default['cog_newrelic']['plugin-agent']['mongodb-admin']                  = nil # expects a hash { :user => 'user', :pass => 'secret'}
default['cog_newrelic']['plugin-agent']['mongodb-dbs']                    = nil # expects a hash of hashes: { 'peachy_prod' => { :first_user => 'secret1', :second_user => 'secret2'} }
default['cog_newrelic']['plugin-agent']['postgresql_dbs']                 = nil
default['cog_newrelic']['postgresql_secrets_vault']                       = nil
