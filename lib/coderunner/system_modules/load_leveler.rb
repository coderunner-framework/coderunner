class CodeRunner
module LoadLeveler


				
	def queue_status
		if ((prefix = ENV['CODE_RUNNER_LAUNCHER']).size > 0 rescue false)
			%x[cat #{ENV['HOME']}/.coderunner_to_launch_#{prefix}/queue_status.txt]  +
			%x[cat #{ENV['HOME']}/.coderunner_to_launch_#{prefix}/queue_status2.txt] 
		else
			%x[llq -W | grep $USER].gsub(/^bglogin\d\./, '')
		end
	end

	#def mpi_prog
		#"aprun -n #{nprocstot} -N #{ppn}"
	#end

	def nodes
			nodes, ppn = @nprocs.split(/x/)
			nodes
	end
	def ppn
			nodes, ppn = @nprocs.split(/x/)
			ppn
	end
	def nprocstot
			nodes, ppn = @nprocs.split(/x/)
			nprocstot = nodes.to_i * ppn.to_i
	end
	def run_command
# 		"qsub #{batch_script_file}"
		if (ENV['CODE_RUNNER_LAUNCHER'].size > 0 rescue false)
			return %[mpiexec -np #{@nprocs} #{executable_location}/#{executable_name} #{parameter_string} > #{output_file} 2> #{error_file}]
		else
			#nodes, ppn = @nprocs.split(/x/)
			#nprocstot = nodes.to_i * ppn.to_i
			"runjob --env-all --exe #{executable_location}/#{executable_name} --np #{nprocstot} --ranks-per-node #{ppn} --args \"#{parameter_string}\""
		end
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
			File.open(batch_script_file, 'w'){|file| file.puts batch_script + "\n" + run_command + "\n"}
			%x[llsubmit #{batch_script_file}].to_i
			return nil
		end
	end

	def batch_script_file
		"#{executable_name}_#{job_identifier}.sh"
	end

	def max_ppn
		raise "Please define max_ppn for your system"
	end
	
	def batch_script

		nodes, ppn = @nprocs.split(/x/)
		eputs "Warning: You must use 128 nodes or greater on a BlueGene Q: This may fail." if  nodes.to_i < 128
		eputs "Warning: Underuse of nodes (#{ppn} cores per node instead of #{max_ppn})" if ppn.to_i < max_ppn 
		eputs "Warning: processes per node excedes cores per node: #{max_ppn}" if ppn.to_i > max_ppn
		ppn ||= max_ppn
		if @wall_mins
			ep @wall_mins
			hours = (@wall_mins / 60).floor
			mins = @wall_mins.to_i % 60
			secs = ((@wall_mins - @wall_mins.to_i) * 60).to_i
			eputs "Allotted wall time is " + sprintf("%02d:%02d:%02d", hours, mins, secs)
		else
			raise "Error: no wall clock time specified."
		end

		return <<EOF
#!/bin/bash

## job requirements for load leveler
######################################################################
\#@bg_size=#{nodes}
\#@job_type=bluegene
\#@class=prod
\#@executable=#{batch_script_file}
\#@environment=COPY_ALL
\#@output=#{executable_name}.#{job_identifier}.$(jobid).output.txt
\#@error=#{executable_name}.#{job_identifier}.$(jobid).error.txt
\#@wall_clock_limit=#{sprintf("%02d:%02d:%02d", hours, mins, secs)}
\#@notification=complete
\#@queue

## commands to be executed
######################################################################
## This is any custom configuration required for the code:
#{code_run_environment}
printenv
echo "Submitting #{nodes}x#{ppn} job on #{CodeRunner::SYS} for project (#@project)..."
	
	
EOF

	end

	def cancel_job
		if ((prefix = ENV['CODE_RUNNER_LAUNCHER']).size > 0 rescue false)
			 fname = ENV['HOME'] + "/.coderunner_to_launch_#{prefix}/#{$$}.stop"
			 File.open(fname, 'w'){|file| file.puts "\n"}
		else
			`llcancel #{@job_no}`
		end
	end

	def error_file
		return "#{executable_name}.#{job_identifier}.#@job_no.error.txt"
	end

	def output_file
		return "#{executable_name}.#{job_identifier}.#@job_no.output.txt"
	end

def get_run_status(job_no, current_status)
	if ((prefix = ENV['CODE_RUNNER_LAUNCHER']).size > 0 rescue false)
		return :Unknown
	end
	line = current_status.split(/\n/).grep(Regexp.new(job_no.to_s))[0]
	unless line
		return :Unknown
	else 
		if line =~ /\sS|H\s/
			return :Held
		elsif line =~ /\sI\s/
			return :Queueing
		elsif line =~ /\sR\s/
			return :Running
		else
			ep 'line', line
			raise 'Could not get run status'
		end
	end
end

	end
end
