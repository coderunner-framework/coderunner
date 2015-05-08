
require 'helper'
require 'rbconfig'

$coderunner_folder = File.dirname(File.expand_path(__FILE__)) + '/../'

module Test::Unit::Assertions
	def assert_system(string)
		assert(system(string), "System Command: '#{string}'")
	end
end

$ruby_command = "#{RbConfig::CONFIG['bindir']}/#{RbConfig::CONFIG['ruby_install_name']}"
$coderunnerrepo_command = "#{$ruby_command}  -I #{$coderunner_folder}lib/ #{$coderunner_folder}/lib/coderunner/repository_manager.rb"

class TestCreate < Test::Unit::TestCase
  def tfolder
    'test/createrepo'
  end
  def setup
    FileUtils.rm_r(tfolder)
    FileUtils.makedirs(tfolder)
  end
  def test_create
    Dir.chdir(tfolder) {
      assert_system("#$coderunnerrepo_command init myrepo")
      assert_system("#$coderunnerrepo_command adrm local ssh://edmundhighcock@localhost/#{Dir.pwd}/remote -Y myrepo")
      assert_system("#$coderunnerrepo_command pushcr -r local -Y myrepo")
    }
  end
  def teardown
    #FileUtils.rm_r(testfolder)
  end
end
