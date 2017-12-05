cloud_name = node[:workorder][:cloud][:ciName]
cloud_type = node[:workorder][:services][:filestore][cloud_name][:ciClassName].split('.').last.downcase
ciAttr = node[:workorder][:services][:filestore][cloud_name][:ciAttributes]

case cloud_type
  when /swift/
    creds = {
        :provider           => 'OpenStack',
        :openstack_api_key  => ciAttr[:password],
        :openstack_username => ciAttr[:username],
        :openstack_tenant   => ciAttr[:tenant],
        :openstack_auth_url => ciAttr[:endpoint] + '/tokens',
        :openstack_region   => ciAttr[:regionname]
    }
  when /azure/
    require 'fog/azurerm'
    creds = {
        :tenant_id       => ciAttr[:tenant_id],
        :client_id       => ciAttr[:client_id],
        :client_secret   => ciAttr[:client_secret],
        :subscription_id => ciAttr[:subscription]
    }
    conn = Fog::Storage::AzureRM.new(creds)
    access_keys = nil
    storage_account_name = ciAttr[:storage_account_name]
    conn.storage_accounts.each do |storage_acc|
      if storage_acc.name.eql?(storage_account_name)
        access_keys = storage_acc.get_access_keys
      end
    end
    creds[:azure_storage_access_key] = access_keys[1].value unless access_keys.nil?
    creds[:azure_storage_account_name] = storage_account_name
    creds[:provider] = 'Azure'
end

require 'json'
file '/etc/objectstore_creds.json' do
  content creds.to_json
end

cookbook_file 'objectstore' do
  mode '0755'
  path '/usr/local/bin/objectstore'
end

execute 'fix_dependency' do
  command 'gem uninstall fog-profitbricks -v 2.0.1 ; true'
  action :run
end