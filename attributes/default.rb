#
# Cookbook Name:: chef-cloudfuse
# Attributes:: chef-cloudfuse
#
default['chef-cloudfuse']['source'] = 'https://github.com/redbo/cloudfuse.git'
default['chef-cloudfuse']['username'] = 'system:root'
default['chef-cloudfuse']['password'] = 'testpass'
default['chef-cloudfuse']['authurl'] = 'http://swiftauth:8080/auth/v1.0'
