# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "coderunner"
  s.version = "0.11.14"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Edmund Highcock"]
  s.date = "2012-11-29"
  s.description = "CodeRunner is a framework for the automated running and analysis of simulations. It automatically generates any necessary input files, organises the output data and analyses it. Because it is a modular system, it can easily be customised to work with any system and any simulation code. One of its greatest strengths is that it is independent of any one simulation code; thus it can easily plot and compare the data from different codes."
  s.email = "edmundhighcock@sourceforge.net"
  s.executables = ["coderunner"]
  s.extensions = ["ext/extconf.rb"]
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.md",
    "README.rdoc"
  ]
  s.files = [
    ".document",
    "Gemfile",
    "LICENSE.txt",
    "README.md",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "bin/coderunner",
    "coderunner.gemspec",
    "ext/code_runner_ext.c",
    "ext/extconf.rb",
    "ext/graph_kit.c",
    "include/code_runner_ext.h",
    "include/graph_kit.h",
    "lib/code_runner_extension.rb",
    "lib/coderunner.rb",
    "lib/coderunner/class_methods.rb",
    "lib/coderunner/feedback.rb",
    "lib/coderunner/fortran_namelist.rb",
    "lib/coderunner/graphs_and_films.rb",
    "lib/coderunner/heuristic_run_methods.rb",
    "lib/coderunner/instance_methods.rb",
    "lib/coderunner/interactive_methods.rb",
    "lib/coderunner/long_regexen.rb",
    "lib/coderunner/merged_code_runner.rb",
    "lib/coderunner/remote_code_runner.rb",
    "lib/coderunner/run.rb",
    "lib/coderunner/system_modules/franklin.rb",
    "lib/coderunner/system_modules/generic_linux.rb",
    "lib/coderunner/system_modules/genericlinux_testsystem.rb",
    "lib/coderunner/system_modules/hector.rb",
    "lib/coderunner/system_modules/helios.rb",
    "lib/coderunner/system_modules/iridis.rb",
    "lib/coderunner/system_modules/juropa.rb",
    "lib/coderunner/system_modules/macosx.rb",
    "lib/coderunner/system_modules/moab.rb",
    "lib/coderunner/system_modules/new_hydra.rb",
    "lib/coderunner/system_modules/slurm.rb",
    "lib/coderunner/test.rb",
    "lib/coderunner/version.rb",
    "lib/cubecalccrmod.rb",
    "lib/cubecalccrmod/cubecalc_defaults.rb",
    "lib/cubecalccrmod/default_modlets/empty_defaults.rb",
    "lib/cubecalccrmod/defaults_files/sleep_defaults.rb",
    "lib/cubecalccrmod/empty.rb",
    "lib/cubecalccrmod/sleep.rb",
    "test/cubecalc.cc",
    "test/helper.rb",
    "test/test_coderunner.rb"
  ]
  s.homepage = "http://coderunner.sourceforge.net"
  s.licenses = ["GPLv3"]
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.1")
  s.rubyforge_project = "coderunner"
  s.rubygems_version = "1.8.24"
  s.summary = "A framework for the automated running and analysis of simulations."

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<graphkit>, [">= 0.2.0"])
      s.add_runtime_dependency(%q<parallelpipes>, [">= 1.0.0"])
      s.add_runtime_dependency(%q<rubyhacks>, [">= 0.1.1"])
      s.add_runtime_dependency(%q<gsl>, [">= 1.12.0"])
      s.add_runtime_dependency(%q<gsl_extras>, [">= 0.3.0"])
      s.add_runtime_dependency(%q<hostmanager>, ["> 0.1.0"])
      s.add_development_dependency(%q<shoulda>, [">= 0"])
      s.add_development_dependency(%q<rdoc>, ["~> 3.12"])
      s.add_development_dependency(%q<bundler>, ["> 1.0.0"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.8.4"])
    else
      s.add_dependency(%q<graphkit>, [">= 0.2.0"])
      s.add_dependency(%q<parallelpipes>, [">= 1.0.0"])
      s.add_dependency(%q<rubyhacks>, [">= 0.1.1"])
      s.add_dependency(%q<gsl>, [">= 1.12.0"])
      s.add_dependency(%q<gsl_extras>, [">= 0.3.0"])
      s.add_dependency(%q<hostmanager>, ["> 0.1.0"])
      s.add_dependency(%q<shoulda>, [">= 0"])
      s.add_dependency(%q<rdoc>, ["~> 3.12"])
      s.add_dependency(%q<bundler>, ["> 1.0.0"])
      s.add_dependency(%q<jeweler>, ["~> 1.8.4"])
    end
  else
    s.add_dependency(%q<graphkit>, [">= 0.2.0"])
    s.add_dependency(%q<parallelpipes>, [">= 1.0.0"])
    s.add_dependency(%q<rubyhacks>, [">= 0.1.1"])
    s.add_dependency(%q<gsl>, [">= 1.12.0"])
    s.add_dependency(%q<gsl_extras>, [">= 0.3.0"])
    s.add_dependency(%q<hostmanager>, ["> 0.1.0"])
    s.add_dependency(%q<shoulda>, [">= 0"])
    s.add_dependency(%q<rdoc>, ["~> 3.12"])
    s.add_dependency(%q<bundler>, ["> 1.0.0"])
    s.add_dependency(%q<jeweler>, ["~> 1.8.4"])
  end
end

