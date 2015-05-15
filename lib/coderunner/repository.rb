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
  # This is a class which implements methods 
  # for managing a CodeRunner repository, which is a
  # slightly customised git repository. It contains 
  # methods for initializing standard files, and maintains
  # a small amount of metadata about the repository.
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
    def split_url(remote_name)
      remote(remote_name).url =~ (/ssh:\/\/(?<namehost>[^\/]+)(?<folder>.*$)/)
      namehost = $~[:namehost]
      folder = $~[:folder]
      return [namehost, folder]
    end
    def changed_in_folder(folder)
      status.changed.find_all{|k,f| File.expand_path(dir.to_s + '/' + f.path).include?(File.expand_path(folder))}
    end
    # Bring all files in the given folder from 
    # the given remote. (Obviously folder must 
    # be a subfolder within the repository).
    def rsyncd(remote_name, folder)
      #f2 = File.expand_path(folder)
      namehost, remote_folder = split_url(remote_name)
      rpath = relative_path(folder)
      if File.expand_path(folder) == File.expand_path(dir.to_s)
        raise "Cannot run rsyncd in the top level of a repository"
      end 
      string =  "rsync -av #{namehost}:#{remote_folder}/#{rpath}/ #{folder}/"
      #Dir.chdir(folder) do
        #FileUtils.touch('dummyfile')
        #add('dummyfile')
        #autocommit_all('--Added dummyfile')
        #system "echo 'Hello' >> dummyfile"
        ##add('dummyfile')
      #end
      #p status.changed.map{|k,f| [p1=File.expand_path(folder), p2=File.expand_path(dir.to_s + '/' + f.path), p2.include?(p1), p1.include?(p2)]}
      #p changed_in_folder(folder).map{|k,f| f.path}
      if changed_in_folder(folder).size > 0
        raise "You have some uncommitted changes in the folder #{folder}. Please commit these changes before calling rsyncd"
      end
      puts string
      system string
    end
    # Send all files in the given folder to 
    # the given remote. (Obviously folder must 
    # be a subfolder within the repository).
    def rsyncu(remote_name, folder)
      #f2 = File.expand_path(folder)
      namehost, remote_folder = split_url(remote_name)
      rpath = relative_path(folder)
      if File.expand_path(folder) == File.expand_path(dir.to_s)
        raise "Cannot run rsyncd in the top level of a repository"
      end 
      string =  "rsync -av  #{folder}/ #{namehost}:#{remote_folder}/#{rpath}/"
      #p status.changed.map{|k,f| [p1=File.expand_path(folder), p2=File.expand_path(dir.to_s + '/' + f.path), p2.include?(p1), p1.include?(p2)]}
      #p changed_in_folder(folder).map{|k,f| f.path}

      cif = `ssh #{namehost} "cd #{remote_folder}/#{rpath} && echo "START" && git status"`
      #p cif
      if cif =~ /START.*modified/m
        raise "You have some uncommitted changes in the remote folder #{rpath}. Please commit these changes before calling rsyncu"
      end
      puts string
      system string
    end

    def add_remote(name, url)
      url =~ (/ssh:\/\/(?<namehost>[^\/]+)(?<folder>.*$)/)
      barefolder = $~[:folder]
      unless barefolder =~ /\.git$/
        raise "All remotes must end in .git for coderunnerrepo"
      end
      super(name, url)
    end

    def pull(remote)
      remote.url =~ (/ssh:\/\/(?<namehost>[^\/]+)(?<folder>.*$)/)
      namehost = $~[:namehost]
      barefolder = $~[:folder]
      p namehost, barefolder
      unless barefolder =~ /\.git$/
        raise "All remotes must end in .git for coderunnerrepo"
      end
      folder = barefolder.sub(/.git$/, '')
      try_system %[ssh #{namehost} "cd #{folder} && git push origin"]
      super(remote)
    end
    def push(remote)
      remote.url =~ (/ssh:\/\/(?<namehost>[^\/]+)(?<folder>.*$)/)
      namehost = $~[:namehost]
      barefolder = $~[:folder]
      p namehost, barefolder
      unless barefolder =~ /\.git$/
        raise "All remotes must end in .git for coderunnerrepo"
      end
      folder = barefolder.sub(/.git$/, '')
      super(remote)
      try_system %[ssh #{namehost} "cd #{folder} && git pull origin"]
    end
    def try_system(str)
      RepositoryManager.try_system(str)
    end
  end

end
