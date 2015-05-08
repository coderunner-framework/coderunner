require 'git'
class CodeRunner
  class Repository < Git::Base
    def repo_file(path)
      "#{dir}/#{path}"
    end
    def init_readme
      File.open(repo_file("README.md"), "w"){|f| f.puts readme_text}
      add(repo_file("README.md"))
      commit_all('Added README.md')
    end
    def init_defaults_folder
      FileUtils.makedirs(repo_file("defaults_files"))
      File.open(repo_file("defaults_files/README"), "w"){|f|
         f.puts  <<EOF
This folder is where defaults files for codes should be placed, with
paths such as defaults_files/<code>crmod/my_defaults.rb. This folder 
will automatically be checked for defaults files when submitting simulations
within this repository.
EOF
      
      }
      add(repo_file("defaults_files/README"))
      commit_all('Added defaults folder')
    end
    def readme_text
      return <<EOF
#{File.basename(dir.path)} CodeRunner Repository
================================================

This is a coderunner repository, which consists of
a managed set of simulation folders and defaults files which are 
synchronised across systems using git. 

This readme is a stub which was created automatically...
feel free to modify this and describe this repo.

Created on: #{Time.now.to_s}

EOF
    end
  end

end
