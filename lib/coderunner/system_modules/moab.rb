class CodeRunner
module Moab

	def self.configure_environment
		eputs "Configuring Hector"
		conf = <<EOF
eval `modulecmd bash swap PrgEnv-pgi PrgEnv-gnu`
eval `modulecmd bash load fftw/3.2.2`
export XTPE_LINK_TYPE=dynamic
export LD_LIBRARY_PATH=/opt/xt-libsci/10.4.1/gnu/lib/44:$LD_LIBRARY_PATH
EOF
	Kernel.change_environment_with_shell_script(conf)
	end
				
	def queue_status
		if ((prefix = ENV['CODE_RUNNER_LAUNCHER']).size > 0 rescue false)
			%x[cat #{ENV['HOME']}/.coderunner_to_launch_#{prefix}/queue_status.txt]  +
			%x[cat #{ENV['HOME']}/.coderunner_to_launch_#{prefix}/queue_status2.txt] 
		else
			%x[qstat | grep $USER]
		end
	end

	def run_command
# 		"qsub #{batch_script_file}"
		if (ENV['CODE_RUNNER_LAUNCHER'].size > 0 rescue false)
			return %[mpiexec -np #{@nprocs} #{executable_location}/#{executable_name} #{parameter_string} > #{output_file} 2> #{error_file}]
		else
			nodes, ppn = @nprocs.split(/x/)
			nprocstot = nodes.to_i * ppn.to_i
			"aprun -n #{nprocstot} -N #{ppn} #{executable_location}/#{executable_name} #{parameter_string}"
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
			pid = %x[qsub #{batch_script_file}].to_i
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
		(eputs "Warning: number of nodes is not recommended (8, 16, 32, 64, 128, 256, 512, 1024, 2048 or 4096 recommended)"; sleep 0.2) unless [8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096].include? nodes.to_i
		(eputs "Warning: number of wall mins is not recommended (20, 60, 180, 360, 720 recomended)"; sleep 0.2) unless [20, 60, 180, 360, 720].include? @wall_mins.to_i
		eputs "Warning: Underuse of nodes (#{ppn} cores per node instead of #{max_ppn})" if ppn.to_i < max_ppn 
		raise "Error: cores per node cannot excede #{max_ppn}" if ppn.to_i > max_ppn
#		raise "Error: project (i.e. budget) not specified" unless @project
		ppn ||= max_ppn
		if @wall_mins
			ep @wall_mins
			hours = (@wall_mins / 60).floor
			mins = @wall_mins.to_i % 60
			secs = ((@wall_mins - @wall_mins.to_i) * 60).to_i
		end
		eputs "Allotted wall time is " + sprintf("%02d:%02d:%02d", hours, mins, secs)
		nprocstot = nodes.to_i * ppn.to_i
<<EOF
	#!/bin/bash --login 
	#PBS -N #{executable_name}.#{job_identifier}
	#PBS -l mppwidth=#{nprocstot}
	#PBS -l mppnppn=#{ppn}
	#{@wall_mins ? "#PBS -l walltime=#{sprintf("%02d:%02d:%02d", hours, mins, secs)}" : ""}
	#{@project ? "#PBS -A #@project" : ""}

	### start of jobscript 
	cd $PBS_O_WORKDIR 
	echo "workdir: $PBS_O_WORKDIR" 

	echo "Submitting #{nodes}x#{ppn} job on Hector for project #@project..."
	
	
EOF

	end

	def cancel_job
		if ((prefix = ENV['CODE_RUNNER_LAUNCHER']).size > 0 rescue false)
			 fname = ENV['HOME'] + "/.coderunner_to_launch_#{prefix}/#{$$}.stop"
			 File.open(fname, 'w'){|file| file.puts "\n"}
		else
			`qdel #{@job_no}`
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
		if line =~ /\sQ\s/
			return :Queueing
		elsif line =~ /\sR\s/
			return :Running
		elsif line =~ /\sH\s/
			return :Queueing
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
