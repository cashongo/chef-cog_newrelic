default['cog_newrelic']['license']                            = nil
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
  default['cog_newrelic']['server_monitor_agent']['config_file_group']  = 'cog_newrelic'
end

default['cog_newrelic']['server_monitor_agent']['service_notify_action']  = :restart
default['cog_newrelic']['server_monitor_agent']['service_actions']        = [:enable, :start] 
default['cog_newrelic']['server_monitor_agent']['config_file_user']       = 'root'
default['cog_newrelic']['server_monitor_agent']['template']['cookbook']   = 'cog_newrelic'
default['cog_newrelic']['server_monitor_agent']['template']['source']     = 'agent/server_monitor/nrsysmond.cfg.erb'
