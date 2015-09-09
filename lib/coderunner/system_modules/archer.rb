class CodeRunner
	require SCRIPT_FOLDER + '/system_modules/moab.rb'
	module Archer
		include Moab

		def batch_script
			raise "Please specify project" unless @project
			(eputs "Warning: number of wall mins is not recommended (20, 60, 180, 360, 720 recomended)"; sleep 0.2) unless [20, 60, 180, 360, 720].include? @wall_mins.to_i

		ppn_checks
		hours, mins, secs = hours_minutes_seconds
<<EOF 
	#!/bin/bash --login 
	#PBS -N #{executable_name}.#{job_identifier}
	#PBS -l select=#{nodes}
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

    def max_ppn
      24
    end

    def  mpi_prog
    "aprun -n #{ppn*nodes}"
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
		elsif line =~ /\s[CE]\s/
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
