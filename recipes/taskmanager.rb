#
# Cookbook Name:: openstack-database-service
# Recipe:: taskmanager
#
# Copyright 2013, SUSE Linux GmbH
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

class ::Chef::Recipe
  include ::Openstack
end

platform_options = node["openstack"]["database-service"]["platform"]

platform_options["taskmanager_packages"].each do |pkg|
  package pkg
end

service "trove-taskmanager" do
  service_name platform_options["taskmanager_service"]
  supports :status => true, :restart => true

  action [ :enable ]
end

db_user = node["openstack"]["database-service"]["db"]["username"]
db_pass = get_password 'db', "openstack-database-service"
db_uri = db_uri("database-service", db_user, db_pass).to_s

identity_uri = endpoint("identity-api")
compute_uri = endpoint("compute-api").to_s.gsub(/%\(tenant_id\)s/, '')
block_storage_uri = endpoint("block-storage-api").to_s.gsub(/%\(tenant_id\)s/, "")
object_storage_uri = endpoint("object-storage-api")

rabbit = node['openstack']['mq']['database-service']['rabbit']
rabbit_pass = get_password('user', rabbit['userid'])

template "/etc/trove/trove-taskmanager.conf" do
  source "trove-taskmanager.conf.erb"
  owner node["openstack"]["database-service"]["user"]
  group node["openstack"]["database-service"]["group"]
  mode 00640
  variables(
    :database_connection => db_uri,
    :rabbit => rabbit,
    :rabbit_pass => rabbit_pass,
    :identity_uri => identity_uri,
    :compute_uri => compute_uri,
    :block_storage_uri => block_storage_uri,
    :object_storage_uri => object_storage_uri
    )

  notifies :restart, "service[trove-taskmanager]", :immediately
end
