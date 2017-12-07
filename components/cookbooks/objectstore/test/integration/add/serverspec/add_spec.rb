is_windows = ENV['OS'] == 'Windows_NT'
$circuit_path = "#{is_windows ? 'C:/Cygwin64' : ''}/home/oneops"
require "#{$circuit_path}/circuit-oneops-1/components/spec_helper.rb"

describe file('/usr/local/bin/objectstore') do
  it { should exist }
end

describe file('/usr/local/bin/objectstore') do
  it { should be_executable }
end

describe file('/etc/objectstore_creds.json') do
  it { should exist }
end

describe command('objectstore list') do
  its(:exit_status) { should eq 0 }
end
