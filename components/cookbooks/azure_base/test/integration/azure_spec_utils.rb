require '/opt/oneops/inductor/circuit-oneops-1/components/cookbooks/azure_base/test/integration/spec_utils'

class AzureSpecUtils < SpecUtils
  def initialize(node)
    @node = node
  end

  def get_azure_creds
    cloud_name = get_cloud_name
    app_type = get_app_type
    svc = get_service

    credentials = {
        tenant_id: svc['tenant_id'],
        client_secret: svc['client_secret'],
        client_id: svc['client_id'],
        subscription_id: svc['subscription']
    }

    credentials
  end
  def get_resource_group_name
    nsPathParts = get_ns_path_parts
    org = nsPathParts[1]
    assembly = nsPathParts[2]
    environment = nsPathParts[3]

    svc = get_service
    location = svc['location']

    resource_group_name = org[0..15] + '-' + assembly[0..15] + '-' + @node['workorder']['box']['ciId'].to_s + '-' + environment[0..15] + '-' + Utils.abbreviate_location(location)
    resource_group_name
  end
  def set_attributes_on_node_required_for_vm_manager
    @node.set['image_id'] = get_image_id
    @node.set['platform-resource-group'] = get_resource_group_name
  end
  def is_express_route_enabled
    svc = get_service

    express_route_enabled = true
    if svc[:express_route_enabled].nil?
      # We cannot assume express route is enabled if it is not set
      express_route_enabled = false
    elsif svc[:express_route_enabled] == 'false'
      express_route_enabled = false
    end

    express_route_enabled
  end
end