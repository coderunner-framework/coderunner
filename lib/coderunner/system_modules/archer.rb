class CodeRunner
	require SCRIPT_FOLDER + '/system_modules/moab.rb'
	module Hector
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

	### start of jobscript 
	cd $PBS_O_WORKDIR 
	echo "workdir: $PBS_O_WORKDIR" 
#{code_run_environment}

	echo "Submitting #{nodes}x#{ppn} job on #{CodeRunner::SYS} for project #@project..."
EOF
	end
		end

		def max_ppn
			24
		end

	def mpi_prog
		"aprun -n #{ppn}"
	end

end
