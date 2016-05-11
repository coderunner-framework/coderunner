# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-
# stub: coderunner 0.18.5 ruby lib
# stub: ext/extconf.rb

Gem::Specification.new do |s|
  s.name = "coderunner"
  s.version = "0.18.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Edmund Highcock"]
  s.date = "2016-05-11"
  s.description = "CodeRunner is a framework for the automated running and analysis of simulations. It automatically generates any necessary input files, organises the output data and analyses it. Because it is a modular system, it can easily be customised to work with any system and any simulation code. One of its greatest strengths is that it is independent of any one simulation code; thus it can easily plot and compare the data from different codes."
  s.email = "edmundhighcock@users.sourceforge.net"
  s.executables = ["coderunner", "coderunnerrepo"]
  s.extensions = ["ext/extconf.rb"]
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.md"
  ]
  s.files = [
    ".document",
    ".travis.yml",
    "CONTRIBUTING.md",
    "Gemfile",
    "LICENSE.txt",
    "README.md",
    "Rakefile",
    "VERSION",
    "bin/coderunner",
    "bin/coderunnerrepo",
    "coderunner.gemspec",
    "dependencies/Makefile",
    "dependencies/README.md",
    "dependencies/download_dependencies.sh",
    "dependencies/system_config_files/archer.sh",
    "dependencies/system_config_files/bluejoule.sh",
    "dependencies/system_config_files/helios.sh",
    "ext/code_runner_ext.c",
    "ext/extconf.rb",
    "ext/graph_kit.c",
    "include/code_runner_ext.h",
    "include/graph_kit.h",
    "index.html",
    "lib/code_runner_extension.rb",
    "lib/coderunner.rb",
    "lib/coderunner/class_methods.rb",
    "lib/coderunner/config.rb",
    "lib/coderunner/feedback.rb",
    "lib/coderunner/fortran_namelist.rb",
    "lib/coderunner/fortran_namelist_c.rb",
    "lib/coderunner/graphs_and_films.rb",
    "lib/coderunner/heuristic_run_methods.rb",
    "lib/coderunner/instance_methods.rb",
    "lib/coderunner/interactive_config.rb",
    "lib/coderunner/interactive_methods.rb",
    "lib/coderunner/long_regexen.rb",
    "lib/coderunner/merged_code_runner.rb",
    "lib/coderunner/remote_code_runner.rb",
    "lib/coderunner/repository.rb",
    "lib/coderunner/repository_manager.rb",
    "lib/coderunner/run.rb",
    "lib/coderunner/system_modules/archer.rb",
    "lib/coderunner/system_modules/blue_joule.rb",
    "lib/coderunner/system_modules/cori.rb",
    "lib/coderunner/system_modules/dirac.rb",
    "lib/coderunner/system_modules/edison.rb",
    "lib/coderunner/system_modules/franklin.rb",
    "lib/coderunner/system_modules/generic_linux.rb",
    "lib/coderunner/system_modules/genericlinux_testsystem.rb",
    "lib/coderunner/system_modules/hector.rb",
    "lib/coderunner/system_modules/helios.rb",
    "lib/coderunner/system_modules/hopper.rb",
    "lib/coderunner/system_modules/iridis.rb",
    "lib/coderunner/system_modules/juropa.rb",
    "lib/coderunner/system_modules/launcher.rb",
    "lib/coderunner/system_modules/load_leveler.rb",
    "lib/coderunner/system_modules/loki.rb",
    "lib/coderunner/system_modules/macosx.rb",
    "lib/coderunner/system_modules/moab.rb",
    "lib/coderunner/system_modules/new_hydra.rb",
    "lib/coderunner/system_modules/saturne.rb",
    "lib/coderunner/system_modules/slurm.rb",
    "lib/coderunner/system_modules/stampede.rb",
    "lib/coderunner/test.rb",
    "lib/coderunner/version.rb",
    "lib/cubecalccrmod.rb",
    "lib/cubecalccrmod/cubecalc.rb",
    "lib/cubecalccrmod/default_modlets/empty_defaults.rb",
    "lib/cubecalccrmod/defaults_files/cubecalc_defaults.rb",
    "lib/cubecalccrmod/defaults_files/sleep_defaults.rb",
    "lib/cubecalccrmod/deleted_variables.rb",
    "lib/cubecalccrmod/empty.rb",
    "lib/cubecalccrmod/namelists.rb",
    "lib/cubecalccrmod/sleep.rb",
    "lib/cubecalccrmod/with_namelist.rb",
    "test/cubecalc.in",
    "test/cubecalc_namelist.cc",
    "test/fortran_namelist.in",
    "test/helper.rb",
    "test/old_test.rb",
    "test/test_coderunner.rb"
  ]
  s.homepage = "http://coderunner-framework.github.io/coderunner"
  s.licenses = ["GPLv3"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.1")
  s.rubyforge_project = "coderunner"
  s.rubygems_version = "2.4.8"
  s.summary = "A framework for the automated running and analysis of simulations."

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<graphkit>, [">= 0.4.2"])
      s.add_runtime_dependency(%q<parallelpipes>, [">= 1.0.0"])
      s.add_runtime_dependency(%q<rubyhacks>, [">= 0.1.4"])
      s.add_runtime_dependency(%q<rb-gsl>, ["> 1.12.0"])
      s.add_runtime_dependency(%q<gsl_extras>, [">= 0.3.0"])
      s.add_runtime_dependency(%q<hostmanager>, ["> 0.1.0"])
      s.add_runtime_dependency(%q<command-line-flunky>, ["> 0.1.0"])
      s.add_runtime_dependency(%q<git>, [">= 1.2.9"])
      s.add_development_dependency(%q<shoulda>, [">= 0"])
      s.add_development_dependency(%q<rdoc>, ["~> 3.12"])
      s.add_development_dependency(%q<bundler>, ["> 1.0.0"])
      s.add_development_dependency(%q<jeweler>, [">= 2.0.0"])
    else
      s.add_dependency(%q<graphkit>, [">= 0.4.2"])
      s.add_dependency(%q<parallelpipes>, [">= 1.0.0"])
      s.add_dependency(%q<rubyhacks>, [">= 0.1.4"])
      s.add_dependency(%q<rb-gsl>, ["> 1.12.0"])
      s.add_dependency(%q<gsl_extras>, [">= 0.3.0"])
      s.add_dependency(%q<hostmanager>, ["> 0.1.0"])
      s.add_dependency(%q<command-line-flunky>, ["> 0.1.0"])
      s.add_dependency(%q<git>, [">= 1.2.9"])
      s.add_dependency(%q<shoulda>, [">= 0"])
      s.add_dependency(%q<rdoc>, ["~> 3.12"])
      s.add_dependency(%q<bundler>, ["> 1.0.0"])
      s.add_dependency(%q<jeweler>, [">= 2.0.0"])
    end
  else
    s.add_dependency(%q<graphkit>, [">= 0.4.2"])
    s.add_dependency(%q<parallelpipes>, [">= 1.0.0"])
    s.add_dependency(%q<rubyhacks>, [">= 0.1.4"])
    s.add_dependency(%q<rb-gsl>, ["> 1.12.0"])
    s.add_dependency(%q<gsl_extras>, [">= 0.3.0"])
    s.add_dependency(%q<hostmanager>, ["> 0.1.0"])
    s.add_dependency(%q<command-line-flunky>, ["> 0.1.0"])
    s.add_dependency(%q<git>, [">= 1.2.9"])
    s.add_dependency(%q<shoulda>, [">= 0"])
    s.add_dependency(%q<rdoc>, ["~> 3.12"])
    s.add_dependency(%q<bundler>, ["> 1.0.0"])
    s.add_dependency(%q<jeweler>, [">= 2.0.0"])
  end
end

