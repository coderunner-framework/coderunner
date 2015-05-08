

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
    ['init_repository', 'init', 1,  'Create a new repository with the given name.', ['name'], []],
    ['add_remote', 'adrm', 2,  'Add a remote url to the repository.', ['name', 'url'], [:Y]],
    ['push_repository', 'push', 2,  'Push repository to all remotes, or to a comma-separated list of remotes given by the -r option.', ['name', 'url'], [:r, :Y]],
    ['push_and_create_repository', 'pushcr', 2,  'Push to a comma-separated list of remotes given by the -r option; this command assumes that there is no repository on the remote and creates one there before pushing.', ['name', 'url'], [:r, :Y]],
    ['pull_repository', 'pull', 2,  'Pull repository from all remotes, or from a comma-separated list of remotes given by the -r option.', ['name', 'url'], [:r, :Y]],

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
      def init_repository(name, copts)
        repo = Repository.init(name)
        repo.init_readme
        repo.init_defaults_folder
      end
      def add_remote(name, url, copts)
        Dir.chdir(copts[:Y]){
          repo = Repository.open(Dir.pwd)
          repo.add_remote(name, url)
        }
      end
      def push_and_create_repository(copts)
        Dir.chdir(copts[:Y]){
          repo = Repository.open(Dir.pwd)
          if copts[:r]
            rems = copts[:r].split(/,/).map{|rname| repo.remote(rname)} 
          else
            raise "Must specify remotes using the -r flag when calling push_and_create_repository"
          end
          rems.each do |r|
            r.url =~ (/ssh:\/\/(?<namehost>[^\/]+)(?<folder>.*$)/)
            namehost = $~[:namehost]
            folder = $~[:folder]
            p namehost, folder
            system %[git bundle create .tmpbundle --all]
            system %[ssh #{namehost} "mkdir -p #{folder}"]
            system %[scp .tmpbundle #{namehost}:#{folder}/.]
            system %[ssh #{namehost} "cd #{folder} && git clone .tmpbundle #{repname = File.basename(repo.dir.to_s)} "]
            system %[ssh #{namehost} "cd #{folder}/#{repname} && git remote rm origin"]
            #push_repository(copts.dup.absorb(r: r.name))
            repo.remotes.each do |other_remote|
              next if other_remote.name == r.name
              system %[ssh #{namehost} "cd #{folder}/#{repname} && git remote add #{other_remote.name} #{other_remote.url}"]
            end
          end 
        }
      end
      def push_repository(copts)
        Dir.chdir(copts[:Y]){
          repo = Repository.open(Dir.pwd)
          if copts[:r]
            rems = copts[:r].split(/,/).map{|rname| repo.remote(rname)} 
          else
            rems = repo.remotes
          end
          rems.each{|r| repo.push(r)}
        }
      end
      def pull_repository(copts)
        Dir.chdir(copts[:Y]){
          repo = Repository.open(Dir.pwd)
          if copts[:r]
            rems = copts[:r].split(/,/).map{|rname| repo.remote(rname)} 
          else
            rems = repo.remotes
          end
          rems.each{|r| repo.pull(r)}
        }
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
