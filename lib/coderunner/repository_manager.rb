

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
    ['add_remote', 'adrm', 2,  'Add a remote url to the repository.', ['name', 'url'], []],

  ]



  COMMAND_LINE_FLAGS_WITH_HELP = [
    #['--boolean', '-b', GetoptLong::NO_ARGUMENT, 'A boolean option'],
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
