name             'Azureobjectstore'
maintainer       '@WalmartLabs'
maintainer_email 'umullangi@walmartlabs.com'
license          'All rights reserved'
description      'Installs/Configures azure objectstore service'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'
depends          'azure'
grouping 'default',
         :access => 'global',
         :packages => %w[base service.filestore mgmt.cloud.service cloud.service cloud.zone.service],
         :namespace => true

attribute 'tenant_id',
          :description => 'Tenant ID',
          :required => 'required',
          :default => '',
          :format => {
            :help => 'tenant id',
            :category => '2.Authentication',
            :order => 1
          }

attribute 'client_id',
          :description => 'Client ID',
          :required => 'required',
          :default => '',
          :format => {
            :help => 'client id',
            :category => '2.Authentication',
            :order => 2
          }

attribute 'subscription',
          :description => 'Subscription ID',
          :required => 'required',
          :default => '',
          :format => {
            :help => 'subscription id in azure',
            :category => '2.Authentication',
            :order => 3
          }

attribute 'client_secret',
          :description => 'Client Secret',
          :required => 'required',
          :encrypted => true,
          :default => '',
          :format => {
            :help => 'client secret azure',
            :category => '2.Authentication',
            :order => 4
          }

attribute 'storage_account_name',
          :description => 'Storage Account Name',
          :required => 'required',
          :format => {
            :help => 'Storage Account Name',
            :category => '2.Authentication',
            :order => 5
          }

recipe 'azure_subscription_status', 'Check Azure Subscription Status'
