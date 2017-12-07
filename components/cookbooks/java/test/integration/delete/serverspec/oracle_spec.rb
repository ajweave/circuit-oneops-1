require 'spec_helper'


if $node['java']['flavor'] == 'oracle'
  describe file('/etc/profile.d/java.sh') do
    it { should_not exist }
  end
end