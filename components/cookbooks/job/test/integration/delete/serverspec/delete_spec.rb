require 'spec_helper'

describe cron do
  entries = `crontab -l`
  expect(entries).not_to include("#{$node['workorder']['rfcCi']['ciAttributes']['minute']} #{$node['workorder']['rfcCi']['ciAttributes']['hour']} #{$node['workorder']['rfcCi']['ciAttributes']['day']} #{$node['workorder']['rfcCi']['ciAttributes']['month']} #{$node['workorder']['rfcCi']['ciAttributes']['weekday']} #{$node['workorder']['rfcCi']['ciAttributes']['cmd']}") if !entries.empty?
end
