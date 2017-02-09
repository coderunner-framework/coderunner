class CodeRunner
	require SCRIPT_FOLDER + '/system_modules/moab.rb'
	module Marconi
		include Moab
		def batch_script
			raise "Please specify project" unless @project
			super
		end
		def max_ppn
			36
		end
	def batch_script
		ppn_checks
		hours, mins, secs = hours_minutes_seconds
<<EOF
	#!/bin/bash --login 
	#PBS -N #{executable_name}.#{job_identifier}
	#PBS -l select=#{nodes}:ncpus=#{ppn}:mpiprocs=#{ppn}
	#PBS -l walltime=#{sprintf("%02d:%02d:%02d", hours, mins, secs)}
	#{@project ? "#PBS -A #@project" : ""}
	#{@queue ? "#PBS -q #@queue" : ""}

  #{code_run_environment}

	### start of jobscript 
	cd $PBS_O_WORKDIR 
	echo "workdir: $PBS_O_WORKDIR" 

	echo "Submitting #{nodes}x#{ppn} job on #{CodeRunner::SYS} for project #@project..."
EOF
	end
	def mpi_prog
		"mpirun -np #{nprocstot}"
	end
	end
end
