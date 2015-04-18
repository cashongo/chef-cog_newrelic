default['cog_newrelic']['license']                            = nil
default['cog_newrelic']['user']                               = 'newrelic'
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
default['cog_newrelic']['server_monitoring']['hostname']        = nil
default['cog_newrelic']['server_monitoring']['pidfile']         = nil
default['cog_newrelic']['server_monitoring']['collector_host']  = nil
default['cog_newrelic']['server_monitoring']['timeout']         = nil

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

default['cog_new-relic']['plugin-path']                                   = '/opt/newrelic'
default['cog_new-relic']['plugin-log-path']                               = '/var/log/newrelic-plugins'
default['cog_new-relic']['plugin-run-path']                               = '/var/run/newrelic'
default['cog_new-relic']['plugin_opcache']['version']                     = '1.0.3'

default['cog_newrelic']['plugin-agent']['memcached']                      = nil
default['cog_newrelic']['plugin-agent']['php-fpm']                        = nil
default['cog_newrelic']['plugin-agent']['nginx']                          = nil
default['cog_newrelic']['plugin-agent']['php-fpm-pools']                  = nil #expects a hash of hashes: [ 'www' => { :name => 'www', :path => '/php-status-www', :port = '9000'} ]

default['cog_newrelic']['version']                      = '5.5'
default['cog_newrelic']['php']['ini_file']              = '/etc/php-5.5.ini'
default['cog_newrelic']['user']                         = nil
default['cog_newrelic']['group']                        = nil
default['cog_newrelic']['pool_conf_dir']                = '/etc/php-fpm.d'
default['cog_newrelic']['conf_file']                    = '/etc/php-fpm.conf'
default['cog_newrelic']['pid']                          = '/var/run/php-fpm/php-fpm-5.5.pid'
default['cog_newrelic']['error_log']                    = '/var/log/php-fpm/error.log'
default['cog_newrelic']['fpm-log-dir']                  = '/var/log/php-fpm'
default['cog_newrelic']['log_level']                    = 'notice'
default['cog_newrelic']['emergency_restart_threshold']  = 0
default['cog_newrelic']['emergency_restart_interval']   = 0
default['cog_newrelic']['process_control_timeout']      = 10
default['cog_newrelic']['php-fpm-port']                 = 9100
