require 'fog/azurerm'

total_start_time = Time.now.to_i

#set the proxy if it exists as a cloud var
Utils.set_proxy(node['workorder']['payLoad']['OO_CLOUD_VARS'])

# get platform resource group and availability set
include_recipe 'azure::get_platform_rg_and_as'

tags = Utils.get_resource_tags(node)

OOLog.info("tags are: #{tags.inspect}")

vm_manager = AzureCompute::VirtualMachineManager.new(node)
vm_manager.tags = tags

compute_service = vm_manager.compute_service

credentials = {
    tenant_id: compute_service[:tenant_id],
    client_secret: compute_service[:client_secret],
    client_id: compute_service[:client_id],
    subscription_id: compute_service[:subscription]
}
# must do this until all is refactored to use the util above.

node.set['azureCredentials'] = credentials

# check whether the VM with given name exists already
virtual_machine_lib = AzureCompute::VirtualMachine.new(credentials)
node.set['VM_exists'] = virtual_machine_lib.check_vm_exists?(vm_manager.resource_group_name, vm_manager.server_name)

action = node['workorder']['rfcCi']['rfcAction']

vm_exists_and_action_update = node['VM_exists'] && action.eql?('update')

# create the vm / get if already exists
if vm_exists_and_action_update
  OOLog.info("Action: Update. VM Exists? True. Fetching VM #{vm_manager.server_name} to populate further values on node.")
  vm = virtual_machine_lib.get(vm_manager.resource_group_name, vm_manager.server_name)
else
  vm = vm_manager.create_or_update_vm
end

zone = {

    "fault_domain" => vm.platform_fault_domain,
    "update_domain" => vm.platform_update_domain
}
puts "***RESULT:vm_size=#{vm.vm_size}"
puts "***RESULT:zone=" + JSON.dump(zone)
puts "***RESULT:instance_id=" + vm.id
puts "***RESULT:instance_osdisk_id=" + vm.os_disk_name
puts "***RESULT:instance_nic_id=" + vm.network_interface_card_ids[0]
node.set[:fast_image] = vm_manager.fast_image_flag

# set the ip type
node.set['ip_type'] = (compute_service['express_route_enabled'].eql? 'true') ? 'private' : 'public'

# set the initial user
node.set['initial_user'] = vm_manager.initial_user

ci_id = vm_manager.compute_ci_id

# set the ip on the node as the private ip
if vm_exists_and_action_update
  nic_lib = AzureNetwork::NetworkInterfaceCard.new(credentials)
  nic_lib.rg_name = vm_manager.resource_group_name

  nic_platform_ci_id = node['workorder']['box']['ciId'] if Utils.is_new_cloud(node)
  nic_name = Utils.get_component_name('nic', ci_id, nic_platform_ci_id)

  nic = nic_lib.get(nic_name)

  node.set['ip'] = nic.private_ip_address

  # In case the OS is centos-7.4
  accelerated_flag = node[:workorder][:rfcCi][:ciAttributes][:accelerated_flag]
  nic_accelerated_flag = nic.enable_accelerated_networking.to_s

  if node[:ostype].eql?('centos-7.4') && accelerated_flag != nic_accelerated_flag
    nic.enable_accelerated_networking = accelerated_flag
    nic_lib.create_update(nic)
    OOLog.info('Accelerated Networking Updated Successfully')
  end
else
  node.set['ip'] = vm_manager.private_ip
end
# write the ip information to stdout for the inductor to pick up and use.

ip_type = node['ip_type']

if ip_type == 'private'
  puts "***RESULT:private_ip=#{node['ip']}"
  puts "***RESULT:public_ip=#{node['ip']}"
  puts "***RESULT:dns_record=#{node['ip']}"
else
  puts "***RESULT:private_ip=#{node['ip']}"
end

# for public deployments we need to get the public ip address after the vm
# is created
if ip_type == 'public'
  # need to get the public ip that was assigned to the VM
  begin
    # get the pip name
    public_ip_name = Utils.get_component_name('publicip', ci_id)
    OOLog.info("public ip name: #{public_ip_name}")

    pip = AzureNetwork::PublicIp.new(credentials)
    publicip_details = pip.get(vm_manager.resource_group_name, public_ip_name)
    pubip_address = publicip_details.ip_address
    OOLog.info("public ip found: #{pubip_address}")
    # set the public ip and dns record on stdout for the inductor
    puts "***RESULT:public_ip=#{pubip_address}"
    puts "***RESULT:dns_record=#{pubip_address}"
    node.set['ip'] = pubip_address
  rescue MsRestAzure::AzureOperationError => e
    OOLog.fatal("Error getting pip from Azure: #{e.body}")
  rescue => ex
    OOLog.fatal("Error getting pip from Azure: #{ex.message}")
  end
end

unless compute_service[:ostype].include?("windows")
  include_recipe "compute::ssh_port_wait"
end

owner = node['workorder']['payLoad']['Assembly'][0]['ciAttributes']['owner'] || 'na'
node.set['max_retry_count_add'] = 30

mgmt_url = "https://#{node['mgmt_domain']}"
if node.has_key?('mgmt_url') && !node['mgmt_url'].empty?
  mgmt_url = node['mgmt_url']
end

metadata = {
    "owner" => owner,
    "mgmt_url" => mgmt_url,
    "organization" => node['workorder']['payLoad']['Organization'][0]['ciName'],
    "assembly" => node['workorder']['payLoad']['Assembly'][0]['ciName'],
    "environment" => node['workorder']['payLoad']['Environment'][0]['ciName'],
    "platform" => node['workorder']['box']['ciName'],
    "component" => node['workorder']['payLoad']['RealizedAs'][0]['ciId'].to_s,
    "instance" => node['workorder']['rfcCi']['ciId'].to_s
}

puts "***RESULT:metadata=#{JSON.dump(metadata)}"
total_end_time = Time.now.to_i
duration = total_end_time - total_start_time
OOLog.info("Total Time for azure::add_node recipe is #{duration} seconds")
