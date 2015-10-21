#
# Cookbook Name:: chef-cloudfuse
# Recipe:: default
#
# Copyright (C) 2015 PE, pf.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

if node['chef-cloudfuse']['install_script'] != ''
 bash 'wget installèscript' do
  code "cd /tmp && wget #{node['chef-cloudfuse']['install_script']}"
 end
else
 cookbook_file '/tmp/install-cloudfuse.sh' do
  source 'install-cloudfuse.sh'
  owner 'root'
  group 'root'
  mode '0500'
  action :create
  notifies :run, "execute[install-cloudfuse.sh]", :immediately
 end
end

directory '/media/cloudfuse/' do
 owner 'root'
 group 'root'
 mode '0755'
 action :create
end

execute 'install-cloudfuse.sh' do
 command "/tmp/install-cloudfuse.sh #{node['chef-cloudfuse']['source']}"
end

template '/root/.cloudfuse' do
 source 'cloudfuse.erb'
 owner 'root'
 group 'root'
 mode '0600'
 variables({
  :username => node['chef-cloudfuse']['username'],
  :password => node['chef-cloudfuse']['password'],
  :authurl => node['chef-cloudfuse']['authurl']
 })
end

