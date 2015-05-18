

# A tool for reading, manipulating and converting files containing
# tokamak data.

require 'getoptlong'

module CommandLineFlunky

  STARTUP_MESSAGE = "\n------CodeRunner Repository Manager------"

  MANUAL_HEADER = <<EOF

-------------CodeRunner Repository Manager Manual---------------

  Written by Edmund Highcock (2014)

NAME

  coderunnerrepo


SYNOPSIS

  coderunnerrepo <command> [arguments] [options]


DESCRIPTION

  Create and manipulate a coderunner repository: a collection of simulation
  folders and defaults files that a synchronised across systems using git. 

EXAMPLES

  $ coderunnerrepo init <name>

  $ coderunnerrepo clone <url>

  $ coderunnerrepo pull 

  $ coderunnerrepo pull -r <remote>

  $ coderunnerrepo push 

  $ coderunnerrepo add <folder>

  $ coderunnerrepo adrm <name> <url>


EOF

  COMMANDS_WITH_HELP = [
    ['add_remote', 'adrm', 2,  'Add a remote url to the repository. The url must end in \'.git\'', ['name', 'url'], [:Y]],
    ['add_folder', 'add', 1,  'Add the folder to the repository... this adds the directory tree and all coderunner data files to the repository, e.g. .code_runner_info.rb, script defaults, command histories etc. Note that this command must be issued in the root of the repository, or with the -Y flag giving the root of the repository.', ['folder'], [:Y]],
    ['bare_repo_command', 'brc', 1,  'Execute the given command within the twin bare repository', ['command'], [:Y]],
    ['init_repository', 'init', 1,  'Create a new repository with the given name. The name must not end in ".git". In fact, two repositories will be created, a working repo and a bare repo ending in .git. The bare repo is used to send and receive changes to remotes: the working repo should only push and pull to and from its twin bare repo.', ['name'], []],
    ['list_remotes', 'lsr', 0,  'List remotes in the bare repository (the working repository should only have one remote: origin.', [], [:Y]],
    ['pull_repository', 'pull', 0,  'Pull repository from all remotes, or from a comma-separated list of remotes given by the -r option.', [], [:r, :Y]],
    ['push_and_create_repository', 'pushcr', 0,  'Push to a comma-separated list of remotes given by the -r option; this command assumes that there is no repository on the remote and creates twin pair of a bare repo and a working checkout.', [], [:r, :Y]],
    ['push_repository', 'push', 0,  'Push repository to all remotes, or to a comma-separated list of remotes given by the -r option.', [], [:r, :Y]],
    ['remote_synchronize_down', 'rsyncd', 2,  'Bring the contents of the remote folder corresponding to the given folder (which must be a subfolder of a local coderunner repository) to the local system. The folder cannot be the top level of the repository. This command uses rsync to actually copy the files. The --delete option is not specified (i.e. files that do not exist on the remote will not be deleted).', ['remote', 'folder'], []],
    ['set_repo_metadata', 'mdata', 1,  "Give a hash of metadata to modify e.g., '{autocommit: false}. Things that can be modified are: autocommit: true/false, automatically commit repo changes made by CodeRunner, default true'.", ['hash'], [:Y]],

  ]



  COMMAND_LINE_FLAGS_WITH_HELP = [
    #['--boolean', '-b', GetoptLong::NO_ARGUMENT, 'A boolean option'],
    ['--remotes', '-r', GetoptLong::REQUIRED_ARGUMENT, 'A comma separated list of remotes.'],
    ['--other-folder', '-Y', GetoptLong::REQUIRED_ARGUMENT, 'Specify the path of the folder where you want to run this command.'],

    ]

  LONG_COMMAND_LINE_OPTIONS = [
  #["--no-short-form", "", GetoptLong::NO_ARGUMENT, %[This boolean option has no short form]],
  ]

  # specifying flag sets a bool to be true

  CLF_BOOLS = []

  CLF_INVERSE_BOOLS = [] # specifying flag sets a bool to be false

  PROJECT_NAME = 'coderunnerrepo'

  def self.method_missing(method, *args)
#     p method, args
    CodeRunner::RepositoryManager.send(method, *args)
  end

  #def self.setup(copts)
    #CommandLineFlunkyTestUtility.setup(copts)
  #end

  SCRIPT_FILE = __FILE__
end

$has_put_startup_message_for_code_runner = true
require 'coderunner'

class CodeRunner
  # A class for managing a coderunner repository, which consists of
  # a managed set of simulation folders and defaults files which are 
  # synchronised across systems using git. 
  class RepositoryManager
    class << self
      # This function gets called before every command
      # and allows arbitrary manipulation of the command
      # options (copts) hash
      def setup(copts)
        copts[:Y] ||= Dir.pwd
        copts[:Y] = File.expand_path(copts[:Y])
      end
      def verbosity
        2
      end
      def bare_repo_command(comm, copts)
        Dir.chdir(copts[:Y]) do
          repo = Repository.open_in_subfolder(Dir.pwd)
          Dir.chdir(repo.bare_repo.dir.to_s) do
            system comm
          end
        end
      end
      def init_repository(name, copts)
        Repository.init(name)
      end
      def add_remote(name, url, copts)
        url =~ Repository.url_regex
        barefolder = $~[:folder]
        unless barefolder =~ Repository.bare_ext_reg
          raise "Remotes must end in .cr.git for coderunnerrepo"
        end
        Dir.chdir(copts[:Y]){
          repo = Repository.open_in_subfolder(Dir.pwd)
          repo.bare_repo.add_remote(name, url)
        }
      end
      def try_system(str)
        puts str
        raise "Failed command: #{str}" unless system str
      end
      def push_and_create_repository(copts)
        Dir.chdir(copts[:Y]){
          repo = Repository.open_in_subfolder(Dir.pwd)
          bare_repo = repo.bare_repo
          if copts[:r]
            rems = copts[:r].split(/,/).map{|rname| bare_repo.remote(rname)} 
          else
            raise "Must specify remotes using the -r flag when calling push_and_create_repository"
          end
          repo.simple_push(repo.remote("origin"))
          rems.each do |r|
            #r.url =~ Repository.url_regex
            #namehost = $~[:namehost]
            #barefolder = $~[:folder]
            #unless barefolder =~ Repository.bare_ext_reg
              #puts "Remotes must end in cr.git for coderunnerrepo: skipping '#{r.url}'"
              #next
            #end
            #folder = barefolder.sub(Repository.bare_ext_reg, '')
            #p namehost, barefolder
            namehost, folder, barefolder = repo.split_url(r.name)
            #barefolder =folder.sub(/\/+$/, '') + '.git'
            #try_system %[git bundle create .tmpbundle --all]
            try_system %[ssh #{namehost} "mkdir -p #{barefolder} && cd #{barefolder} && git init --bare"]
            bare_repo.push(r)
            try_system %[ssh #{namehost} "git clone #{barefolder} #{folder}"]
            #try_system %[scp .tmpbundle #{namehost}:#{folder}/../.]
            #try_system %[rm .tmpbundle]
            #try_system %[ssh #{namehost} "cd #{folder} && git clone .tmpbundle #{repname = File.basename(repo.dir.to_s)} "]
            #try_system %[ssh #{namehost} "cd #{folder} && git clone ../.tmpbundle ."]
            #try_system %[ssh #{namehost} "cd #{folder}/#{repname} && git remote rm origin"]
            #try_system %[ssh #{namehost} "cd #{folder} && git remote rm origin"]
            #push_repository(copts.dup.absorb(r: r.name))
            bare_repo.remotes.each do |other_remote|
              next if other_remote.name == r.name
              try_system %[ssh #{namehost} "cd #{barefolder} && git remote add #{other_remote.name} #{other_remote.url}"]
              #try_system %[ssh #{namehost} "cd #{folder} && git remote add #{other_remote.name} #{other_remote.url}"]
            end
          end 
        }
      end
      def list_remotes(copts)
        Dir.chdir(copts[:Y]){
          repo = Repository.open_in_subfolder(Dir.pwd)
          repo.bare_repo.remotes.each do |r|
            puts "#{r.name} #{r.url}"
          end
        }
      end
      def push_repository(copts)
        Dir.chdir(copts[:Y]){
          repo = Repository.open_in_subfolder(Dir.pwd)
          if copts[:r]
            rems = copts[:r].split(/,/).map{|rname| repo.bare_repo.remote(rname)} 
          else
            rems = repo.bare_repo.remotes
          end
          rems.each{|r| repo.push(r)}
        }
      end
      def pull_repository(copts)
        Dir.chdir(copts[:Y]){
          repo = Repository.open_in_subfolder(Dir.pwd)
          if copts[:r]
            rems = copts[:r].split(/,/).map{|rname| repo.bare_repo.remote(rname)} 
          else
            rems = repo.bare_repo.remotes
          end
          rems.each{|r| repo.pull(r)}
        }
      end
      def add_folder(folder, copts)
        repo = Repository.open_in_subfolder(folder)
        repo.add_folder(folder)
      end
      def remote_synchronize_down(remote, folder, copts)
        repo = Repository.open_in_subfolder(folder)
        repo.rsyncd(remote, folder)
      end
      def remote_synchronize_up(remote, folder, copts)
        repo = Repository.open_in_subfolder(folder)
        repo.rsyncu(remote, folder)
      end

    end
  end
end


######################################
# This must be at the end of the file
#
require 'command-line-flunky'
###############################
#

if $0==__FILE__
  CommandLineFlunky.run_script
end
