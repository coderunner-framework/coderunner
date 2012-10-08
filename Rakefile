# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "coderunner"
  gem.homepage = "http://coderunner.sourceforge.net"
  gem.license = "GPLv3"
	gem.rubyforge_project = gem.name
  gem.summary = %Q{A framework for the automated running and analysis of simulations.}
  gem.description = %Q{CodeRunner is a framework for the automated running and analysis of simulations. It automatically generates any necessary input files, organises the output data and analyses it. Because it is a modular system, it can easily be customised to work with any system and any simulation code. One of its greatest strengths is that it is independent of any one simulation code; thus it can easily plot and compare the data from different codes.}
  gem.email = "edmundhighcock@sourceforge.net"
  gem.authors = ["Edmund Highcock"]
	gem.extensions = "ext/extconf.rb"
	gem.files.include('ext/*.c', 'include/*.h', 'ext/*.rb')
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end


#require 'rcov/rcovtask'
#Rcov::RcovTask.new do |test|
  #test.libs << 'test'
  #test.pattern = 'test/**/test_*.rb'
  #test.verbose = true
  #test.rcov_opts << '--exclude "gems/*"'
#end

task :default => :test

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "coderunner #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
