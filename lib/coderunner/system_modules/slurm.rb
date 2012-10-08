class CodeRunner
	# A module to let CodeRunner run using the SLURM queue system,
	# used on certain HPC systems.
module Slurm
				
	def queue_status
		if ((prefix = ENV['CODE_RUNNER_LAUNCHER']).size > 0 rescue false)
			%x[cat #{ENV['HOME']}/.coderunner_to_launch_#{prefix}/queue_status.txt]  +
			%x[cat #{ENV['HOME']}/.coderunner_to_launch_#{prefix}/queue_status2.txt] 
		else
			%x[squeue | grep #{ENV['USER'][0..7]}]
		end
	end

	def run_command
# 		"qsub #{batch_script_file}"
		if (ENV['CODE_RUNNER_LAUNCHER'].size > 0 rescue false)
			return %[mpiexec -np #{@nprocs} #{executable_location}/#{executable_name} #{parameter_string} > #{output_file} 2> #{error_file}]
		else
			nodes, ppn = @nprocs.split(/x/)
			nprocstot = nodes.to_i * ppn.to_i
			"mpirun -np #{nprocstot}  #{executable_location}/#{executable_name} #{parameter_string}"
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
			File.open(batch_script_file, 'w'){|file| file.puts batch_script + run_command + "\n"}
			pid = %x[sbatch #{batch_script_file}].to_i
			return nil
		end
	end

	def batch_script_file
		"#{executable_name}.#{job_identifier}.sh"
	end

	def max_ppn
		raise "Please define max_ppn for your system"
	end
	
	def batch_script

		nodes, ppn = @nprocs.split(/x/)
		eputs "Warning: Underuse of nodes (#{ppn} cores per node instead of #{max_ppn})" if ppn.to_i < max_ppn 
		raise "Error: cores per node cannot excede #{max_ppn}" if ppn.to_i > max_ppn
#		raise "Error: project (i.e. budget) not specified" unless @project
		ppn ||= max_ppn
		raise "Please specify wall minutes" unless @wall_mins
		if @wall_mins
			ep @wall_mins
			hours = (@wall_mins / 60).floor
			mins = @wall_mins.to_i % 60
			secs = ((@wall_mins - @wall_mins.to_i) * 60).to_i
		end
		eputs "Allotted wall time is " + sprintf("%02d:%02d:%02d", hours, mins, secs)
		nprocstot = nodes.to_i * ppn.to_i
<<EOF
#!/bin/bash
#SBATCH -J #{executable_name}.#{job_identifier} # jobname
#SBATCH -N #{nodes.to_i}        # number of nodes
#SBATCH -n #{nprocstot}         # number of tasks
#SBATCH -o #{executable_name}.#{job_identifier}.o%j              # strout filename (%j is jobid)
#SBATCH -e #{executable_name}.#{job_identifier}.e%j               # stderr filename (%j is jobid)
#{@project ? "#SBATCH -A #@project # project to charge" : ""}
#{@wall_mins ? "#SBATCH -t #{sprintf("%02d:%02d:%02d", hours, mins, secs)} # walltime" : ""}

#{code_run_environment}
echo "Submitting #{nodes}x#{ppn} job on #{CodeRunner::SYS} for project #@project..."

	
	
EOF

	end

	def cancel_job
		if ((prefix = ENV['CODE_RUNNER_LAUNCHER']).size > 0 rescue false)
			 fname = ENV['HOME'] + "/.coderunner_to_launch_#{prefix}/#{$$}.stop"
			 File.open(fname, 'w'){|file| file.puts "\n"}
		else
			`scancel #{@job_no}`
		end
	end

	def error_file
		return "#{executable_name}.#{job_identifier}.e#@job_no"
	end

	def output_file
		return "#{executable_name}.#{job_identifier}.o#@job_no"
	end

def get_run_status(job_no, current_status)
	if ((prefix = ENV['CODE_RUNNER_LAUNCHER']).size > 0 rescue false)
		return :Unknown
	end
	line = current_status.split(/\n/).grep(Regexp.new(job_no.to_s))[0]
	unless line
		return :Unknown
	else 
		if line =~ /\sPD\s/
			return :Queueing
		elsif line =~ /\sR\s/
			return :Running
		elsif line =~ /\sC\s/
			return :Unknown
		else
			ep 'line', line
			raise 'Could not get run status'
		end
	end
end

	end
end
