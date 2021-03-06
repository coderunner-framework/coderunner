class CodeRunner
require SCRIPT_FOLDER + '/system_modules/launcher.rb'
module Moab
  include Launcher

	#def self.configure_environment
		#eputs "Configuring Hector"
		#conf = <<EOF
#eval `modulecmd bash swap PrgEnv-pgi PrgEnv-gnu`
#eval `modulecmd bash load fftw/3.2.2`
#export XTPE_LINK_TYPE=dynamic
#export LD_LIBRARY_PATH=/opt/xt-libsci/10.4.1/gnu/lib/44:$LD_LIBRARY_PATH
#EOF
	#Kernel.change_environment_with_shell_script(conf)
	#end
				
	def queue_status
		if use_launcher
      queue_status_launcher
		else
			%x[qstat | grep $USER]
		end
	end

	def mpi_prog
		"aprun -n #{nprocstot} -N #{ppn}"
	end

  def nodes
    nodes, _ppn = @nprocs.split(/:/)[0].split(/x/)
    nodes.to_i
  end
	def ppn
			_nodes, ppn = @nprocs.split(/:/)[0].split(/x/)
			ppn.to_i
	end
	def nprocstot
		
			#nodes, ppn = @nprocs.split(/x/)
			_nprocstot = nodes.to_i * ppn.to_i
	end
	def run_command
# 		"qsub #{batch_script_file}"
		if use_launcher
			return %[#{code_run_environment}
				#{mpi_prog} #{executable_location}/#{executable_name} #{parameter_string} > #{output_file} 2> #{error_file}]
		else
			"#{mpi_prog}  #{executable_location}/#{executable_name} #{parameter_string}"
		end
	end

	def execute
		if use_launcher
      return execute_launcher
		else
			File.open(batch_script_file, 'w'){|file| file.puts batch_script + run_command + "\n"}
			_pid = %x[qsub #{batch_script_file}].to_i
		end
	end

	def batch_script_file
		"#{executable_name}.#{job_identifier}.sh"
	end

	def max_ppn
		raise "Please define max_ppn for your system"
	end
	
	def hours_minutes_seconds
		if @wall_mins
			ep @wall_mins
			hours = (@wall_mins / 60).floor
			mins = @wall_mins.to_i % 60
			secs = ((@wall_mins - @wall_mins.to_i) * 60).to_i
		else
			raise "Please specify wall mins using the W flag"
		end
		eputs "Allotted wall time is " + sprintf("%02d:%02d:%02d", hours, mins, secs)
		return [hours, mins, secs]
	end
	def ppn_checks
		eputs "Warning: Underuse of nodes (#{ppn} cores per node instead of #{max_ppn})" if ppn.to_i < max_ppn 
		raise "Error: cores per node cannot excede #{max_ppn}" if ppn.to_i > max_ppn
	end
	def batch_script
		ppn_checks
		hours, mins, secs = hours_minutes_seconds
<<EOF
	#!/bin/bash --login 
	#PBS -N #{executable_name}.#{job_identifier}
	#PBS -l mppwidth=#{nprocstot}
	#PBS -l mppnppn=#{ppn}
	#PBS -l walltime=#{sprintf("%02d:%02d:%02d", hours, mins, secs)}
	#{@project ? "#PBS -A #@project" : ""}
	#{@queue ? "#PBS -q #@queue" : ""}

	### start of jobscript 
	cd $PBS_O_WORKDIR 
	echo "workdir: $PBS_O_WORKDIR" 
#{code_run_environment}

	echo "Submitting #{nodes}x#{ppn} job on #{CodeRunner::SYS} for project #@project..."
EOF
	end

	def cancel_job
		use_launcher ? cancel_job_launcher : `qdel #{@job_no}`
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
      if line =~ /\sQ\s/
        return :Queueing
      elsif line =~ /\sR\s/
        return :Running
      elsif line =~ /\sH\s/
        return :Queueing
      elsif line =~ /\sC\s/
        @running=false
        return :Unknown
      else
        ep 'line', line
        raise 'Could not get run status'
      end
    end
  end

end
end
