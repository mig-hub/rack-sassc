require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.warning = false
  t.options = '--pride'
end

desc "Run tests"
task :default => :test

