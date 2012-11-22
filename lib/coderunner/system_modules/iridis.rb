class CodeRunner
	require SCRIPT_FOLDER + '/system_modules/moab.rb'
	module Iridis
		include Moab
		def batch_script
			raise "Please specify project" unless @project
			super
		end
		def max_ppn
			12
		end
		def mpi_prog
			"mpirun"
		end
		def execute
			if ((prefix = ENV['CODE_RUNNER_LAUNCHER']).size > 0 rescue false)
				launch_id = "#{Time.now.to_i}#{$$}"
				fname = ENV['HOME'] + "/.coderunner_to_launch_#{prefix}/#{launch_id}"
				File.open(fname + '.start', 'w'){|file| file.puts "cd #{Dir.pwd};#{run_command}"}
				sleep 1 until FileTest.exist? fname + '.pid'
				pid = File.read(fname + '.pid').to_i
				FileUtils.rm fname + '.pid'
				return pid
			else
				File.open(batch_script_file, 'w'){|file| file.puts batch_script + run_command + "\n"}
				pid = %x[qsub -q #@project #{batch_script_file}].to_i
			end
	end
	end
end
