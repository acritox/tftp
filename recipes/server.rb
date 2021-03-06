#
# Author:: Matt Ray <matt@chef.io>
# Cookbook Name:: tftp
# Recipe:: server
#
# Copyright 2011-2012, Chef Software, Inc
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

case node["platform"]
when "centos", "redhat", "scientific", "oracle", "amazon", "fedora"
  package "tftp-server"

  service "xinetd" do
    supports :restart => true, :status => true, :reload => true
    action [ :enable, :start ]
  end

  directory node['tftp']['directory'] do
    owner "nobody"
    group "nobody"
    mode 0755
    recursive true
    action :create
  end

  template "/etc/xinetd.d/tftp" do
    source "tftp.erb"
    owner "root"
    group "root"
    mode 0644
    notifies :restart, "service[xinetd]"
  end

  if !node["tftp"]["remap"].empty?
    r = resources(template: '/etc/xinetd.d/tftp')
    r.variables(
      :remap_option => " -m /etc/tftpd-hpa.map"
    )
    template "/etc/tftpd.map" do
      owner "root"
      group "root"
      mode 0644
      source "tftp-map.erb"
      notifies :reload, "service[tftpd-hpa]", :delayed
    end
  end

when "debian", "ubuntu"
  package "tftpd-hpa"

  service "tftpd-hpa" do
    provider Chef::Provider::Service::Upstart if node["platform"] == "ubuntu"
    supports :restart => true, :status => true, :reload => true
    action [ :enable, :start ]
  end

  directory node['tftp']['directory'] do
    owner "root"
    group "root"
    mode 0755
    recursive true
    action :create
  end

  template "/etc/default/tftpd-hpa" do
    owner "root"
    group "root"
    mode 0644
    source "tftpd-hpa.erb"
    notifies :restart, "service[tftpd-hpa]"
  end

  if !node["tftp"]["remap"].empty?
    r = resources(template: '/etc/default/tftpd-hpa')
    r.variables(
      :remap_option => " -m /etc/tftpd-hpa.map"
    )
    template "/etc/tftpd-hpa.map" do
      owner "root"
      group "root"
      mode 0644
      source "tftp-map.erb"
      notifies :reload, "service[tftpd-hpa]", :delayed
    end
  end
else
  Chef::Log.warn("#{cookbook_name}::#{recipe_name} recipe is not supported on #{node['platform']}")
end
