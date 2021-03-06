class CodeRunner
require SCRIPT_FOLDER + '/system_modules/launcher.rb'
# A module to let CodeRunner run using the SLURM queue system,
# used on certain HPC systems.
module Slurm
  include Launcher
				
	def queue_status
		if use_launcher
      queue_status_launcher
		else
			#%x[squeue | grep #{ENV['USER'][0..7]}]
			%x[squeue -u $USER]
		end
	end

	def run_command
# 		"qsub #{batch_script_file}"
		if use_launcher
			return %[mpiexec -np #{@nprocs} #{executable_location}/#{executable_name} #{parameter_string} > #{output_file_launcher} 2> #{error_file_launcher}]
		else
			"#@preamble #{mpi_prog}  #{executable_location}/#{executable_name} #{parameter_string}"
		end
	end
  def mpi_prog
	  nodes, ppn = @nprocs.split(/x/)
	  nprocstot = nodes.to_i * ppn.to_i
    "mpirun -np #{nprocstot}"
  end 

	def execute
		if use_launcher
      return execute_launcher
		else
			File.open(batch_script_file, 'w'){|file| file.puts batch_script + run_command + "\n"}
			_pid = %x[sbatch #{batch_script_file}].to_i
			return nil
		end
	end

	def batch_script_file
		"#{executable_name}.#{job_identifier}.sh"
	end

	def max_ppn
		raise "Please define max_ppn for your system"
	end
	

  def nodes
    @nprocs.split(/x/)[0].to_i
  end
  def ppn
    @nprocs.split(/x/)[1].to_i
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
#{@queue ? "#SBATCH -p #@queue # submission queue" : ""}
#{@wall_mins ? "#SBATCH -t #{sprintf("%02d:%02d:%02d", hours, mins, secs)} # walltime" : ""}

#{code_run_environment}
echo "Submitting #{nodes}x#{ppn} job on #{CodeRunner::SYS} for project #@project..."

	
	
EOF

	end

	def cancel_job
		use_launcher ? cancel_job_launcher : `scancel #{@job_no}`
	end

	def error_file
		use_launcher ? error_file_launcher :
      "#{executable_name}.#{job_identifier}.e#@job_no"
	end

	def output_file
		use_launcher ? output_file_launcher :
      "#{executable_name}.#{job_identifier}.o#@job_no"
	end

def get_run_status(job_no, current_status)
	if use_launcher
		return :Unknown
	end
	line = current_status.split(/\n/).grep(Regexp.new(job_no.to_s))[0]
	unless line
		return :Unknown
	else 
		@running = true
		if line =~ /\sPD\s/
			return :Queueing
		elsif line =~ /\sR\s/
			return :Running
		elsif line =~ /\sC\s/
			@running = false
			return :Unknown
		else
			ep 'line', line
			raise 'Could not get run status'
		end
	end
end

end
end
