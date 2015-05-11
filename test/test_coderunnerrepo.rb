
require 'helper'
require 'rbconfig'
require 'coderunner/repository_manager'

unless $cpp_command = ENV['CPP']
	raise "Please specify the environment variable CPP (the C++ compiler)"
end
$coderunner_folder = File.dirname(File.expand_path(__FILE__)) + '/../'

module Test::Unit::Assertions
	def assert_system(string)
		assert(system(string), "System Command: '#{string}'")
	end
end

$ruby_command = "#{RbConfig::CONFIG['bindir']}/#{RbConfig::CONFIG['ruby_install_name']}"
$coderunnerrepo_command = "#{$ruby_command}  -I #{$coderunner_folder}lib/ #{$coderunner_folder}/lib/coderunner/repository_manager.rb"

class Dummy
  include CodeRunner::InteractiveMethods
end
class TestCreate < Test::Unit::TestCase
  def tfolder
    'test/createrepo'
  end
  def dffolder
    'myrepo/crdummyfiles'
  end
  def setup
    FileUtils.rm_r(tfolder)
    FileUtils.makedirs(tfolder)
		string = $cpp_command + ' ../cubecalc.cc -o cubecalc'
		Dir.chdir('test'){CodeRunner.generate_cubecalc}
		Dir.chdir(tfolder){assert_system string}
  end
  def test_create
    Dir.chdir(tfolder) {
      assert_system("#$coderunnerrepo_command init myrepo")
      assert_system("#$coderunnerrepo_command adrm local ssh://edmundhighcock@localhost/#{Dir.pwd}/remote -Y myrepo")
      assert_system("#$coderunnerrepo_command adrm dummy ssh://edmundhighcock@nohost/#{Dir.pwd}/remote -Y myrepo")
      assert_system("#$coderunnerrepo_command pushcr -r local -Y myrepo")
      #assert_equal(false, system("#$coderunnerrepo_command pushcr -r local -Y myrepo"))
      assert_system("cd myrepo; git remote rm dummy")
      assert_system("#$coderunnerrepo_command pull -Y myrepo")
      FileUtils.makedirs(dffolder)
      FileUtils.touch(dffolder + '/code_runner_info.rb')
      FileUtils.touch(dffolder + '/code_runner_results.rb')
      #assert_system("#$coderunnerrepo_command add myrepo/crdummyfiles -Y myrepo")
      CodeRunner::RepositoryManager.add_folder('myrepo/crdummyfiles', {})
      FileUtils.makedirs('myrepo/sims')
      Dir.chdir('myrepo/sims') do
        CodeRunner.submit(C: 'cubecalc', m: 'empty', X: '../../cubecalc')
        FileUtils.touch('.code-runner-irb-save-history')
        Dummy.new.setup_interactive
      end
    }
  end
  def teardown
    #FileUtils.rm_r(testfolder)
  end
end
