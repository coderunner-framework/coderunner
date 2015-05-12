require 'git'
class CodeRunner
  def is_in_repo?(folder=@root_folder)
    Repository.repo_folder(folder) ?  true : false
  end
  class Run
    # Add CodeRunner files within the run folder to git. If
    # the run_class for this run defines the run class property
    # repo_file_match, also add any files which match any of 
    def add_to_repo
      Dir.chdir(@directory) do
        repo = Repository.open_in_subfolder
        repo.add("code_runner_info.rb")
        repo.add("code_runner_results.rb")
        Dir.entries.each do |f|
          repo.add(f) if rcp.repo_file_match? and f =~ rcp.repo_file_match
        end
        repo.autocommit("Submitted simulation id #{id} in folder #{repo.relative_path(@runner.root_folder)}")
      end
    end
  end
  class Repository < Git::Base
    # If the folder is within a coderunner repository
    # return the root folder of the repository; else 
    # return nil
    def self.repo_folder(folder = Dir.pwd)
      f2 = File.expand_path(folder)
      while not (Dir.entries(f2).include?('.git') and 
            Dir.entries(f2).include?('.code_runner_repo_metadata'))
        f2 = File.expand_path(f2 + '/..')
        (f2=nil; break) if f2 == '/' 
        p 'f2 is ', f2
      end
      return f2
    end
    # Open a git object from within a subfolder of a repository
    # Checks to see if the subfolder actually is inside a CodeRunner
    # repository.
    def self.open_in_subfolder(folder = Dir.pwd)
      f2 = repo_folder(folder)
      raise "#{folder} is not a coderunner repository " if not f2
      return open(f2)
    end
    def relative_path(folder=Dir.pwd)
      File.expand_path(folder).sub(File.expand_path(dir.to_s) + '/', '')
    end
    def repo_file(path)
      "#{dir}/#{path}"
    end
    def init_readme
      File.open(repo_file("README.md"), "w"){|f| f.puts readme_text}
      add(repo_file("README.md"))
      autocommit_all('Added README.md')
    end
    def init_metadata
      Hash.phoenix(repo_file('.code_runner_repo_metadata')) do |hash|
        hash[:creation_time] = Time.now.to_i
        hash[:autocommit] = true
      end
      add(repo_file('.code_runner_repo_metadata'))
      autocommit_all('Added metadata')
    end
    def metadata
      Hash.phoenix(repo_file('.code_runner_repo_metadata'))
    end
    def add_folder(folder)
      Dir.chdir(folder) do
        require 'find'
        #files = []
        Find.find('.') { |e| (puts e; add(e)) if
          e =~ /code_runner_info.rb/ or
          e =~ /code_runner_results.rb/ or 
          e =~ /.code-runner-irb-save-history/ or
          e =~ /.code_runner_script_defaults.rb/ or
          (Dir.entries(Dir.pwd).include?('.code_runner_script_defaults') and
           (repo_file_match = (
             rcp = CodeRunner.fetch_runner(Y: folder, U: true).run_class.rcp; 
             rcp.repo_file_match? ? rcp.repo_file_match : false); 
             repo_file_match =~ m
           )
          )
        }
      end
      autocommit_all("Added folder #{relative_path(folder)}")
    end
    def autocommit(*args)
      commit(*args) if metadata[:autocommit]
    end
    def autocommit_all(*args)
      commit_all(*args) if metadata[:autocommit]
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
      autocommit_all('Added defaults folder')
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
