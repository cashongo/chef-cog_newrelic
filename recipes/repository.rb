#
# Cookbook Name:: cog_newrelic
# Recipe:: repository
#
# Copyright (C) 2014 Cash on Go Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

case node['platform']
  when 'debian', 'ubuntu', 'redhat', 'centos', 'fedora', 'scientific', 'amazon'
    package 'wget'
end

case node['platform']
when 'debian', 'ubuntu'
  gpg_key_url   = "http://download.newrelic.com/#{node['cog_newrelic']['repository']['repository_key']}.gpg"
  gpg_key_file  = "#{Chef::Config[:file_cache_path]}/#{node['cog_newrelic']['repository']['repository_key']}.gpg"

  remote_file gpg_key_file do
    source gpg_key_url
    action :create
  end

  execute 'newrelic-add-apt-key' do
    command "apt-key add #{gpg_key_file}"
  end

  # configure the New Relic apt repository
  remote_file '/etc/apt/sources.list.d/newrelic.list' do
    source  'http://download.newrelic.com/debian/newrelic.list'
    owner   'root'
    group   'root'
    mode    0644

    notifies  :run, 'execute[newrelic-apt-get-update]', :immediately
    action    :create_if_missing
  end

  execute 'newrelic-apt-get-update' do
    command 'apt-get update'

    action :nothing
  end

when 'redhat', 'centos', 'fedora', 'scientific', 'amazon'

  if node['kernel']['machine'] == 'x86_64'
    machine = 'x86_64'
  else
    machine = 'i386'
  end

  remote_file "#{Chef::Config[:file_cache_path]}/newrelic-repo-5-3.noarch.rpm" do
    source "http://download.newrelic.com/pub/newrelic/el5/#{machine}/newrelic-repo-5-3.noarch.rpm"
    action :create_if_missing
  end

  package 'newrelic-repo' do
    source    "#{Chef::Config[:file_cache_path]}/newrelic-repo-5-3.noarch.rpm"
    provider  Chef::Provider::Package::Rpm

    action node['cog_newrelic']['repository']['repository_action']
  end
end
