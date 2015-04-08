class CodeRunner
	require SCRIPT_FOLDER + '/system_modules/slurm.rb'
	module Stampede
		include Slurm
		#def batch_script
			#raise "Please specify project" unless @project
			#super
		#end
		def max_ppn
			16
		end
		def run_command
	# 		"qsub #{batch_script_file}"
			if (ENV['CODE_RUNNER_LAUNCHER'].size > 0 rescue false)
				return %[ibrun -n #{@nprocs} -o 0 #{executable_location}/#{executable_name} #{parameter_string} > #{output_file} 2> #{error_file}]
			else
				"ibrun #{executable_location}/#{executable_name} #{parameter_string}"
			end
		end
		def batch_script
			raise "Please specify the queue to submit to using the -Q (or Q:) flag" unless @queue
			super
		end	
	end
end
