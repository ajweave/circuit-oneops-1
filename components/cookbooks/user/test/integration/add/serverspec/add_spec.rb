
require 'spec_helper'

describe user($node['user']['username']) do
  it { should exist }
  it { should have_login_shell $node['user']['login_shell'] }
  it { should have_home_directory "/home/#{$node['user']['username']}" }
end
if !$node['user']['username'].to_s.empty?
  describe user($node['user']['username']) do
    it { should belong_to_group $node['user']['group'] }
  end
end