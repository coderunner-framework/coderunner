class CodeRunner

  # A module containing methods for submitting runs using the CodeRunner
  # launcher. Typically this would be used on a home Linux system or in
  # an interactive session on a supercomputer.
  module Launcher
    def launcher_prefix
		  ENV['CODE_RUNNER_LAUNCHER']
    end
    def use_launcher
      launcher_prefix and launcher_prefix.size > 0
    end
    def queue_status_launcher
			%x[cat #{ENV['HOME']}/.coderunner_to_launch_#{prefix}/queue_status.txt]  +
			%x[cat #{ENV['HOME']}/.coderunner_to_launch_#{prefix}/queue_status2.txt] 
    end 
    def execute_launcher
      launch_id = "#{Time.now.to_i}#{$$}"
      fname = ENV['HOME'] + "/.coderunner_to_launch_#{prefix}/#{launch_id}"
      File.open(fname + '.start', 'w'){|file| file.puts "cd #{Dir.pwd};#{run_command}"}
      sleep 1 until FileTest.exist? fname + '.pid'
      pid = File.read(fname + '.pid').to_i
      FileUtils.rm fname + '.pid'
      return pid
    end
    def cancel_job_launcher
      fname = ENV['HOME'] + "/.coderunner_to_launch_#{prefix}/#{$$}.stop"
      File.open(fname, 'w'){|file| file.puts "\n"}
    end
  end
end
