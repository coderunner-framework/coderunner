class CodeRunner
	require 'coderunner/system_modules/moab.rb'
	module Dirac
		include Moab
		def max_ppn
			16
		end
		def mpi_prog
			"mpiexec -np #{nprocstot} "
		end
		def gpu_name
			@nprocs.split(/:/)[1]
		end
		
		def batch_script
			ppn_checks
			hours, mins, secs = hours_minutes_seconds
	<<EOF
		#!/bin/bash --login 
		#PBS -N #{executable_name}.#{job_identifier}
		#PBS -l nodes=#{nodes}:ppn=#{ppn}:#{gpu_name}
		#PBS -l walltime=#{sprintf("%02d:%02d:%02d", hours, mins, secs)}
		#{@project ? "#PBS -A #@project" : ""}
		#PBS -e #{executable_name}.#{job_identifier}.e$PBS_JOBID
		#PBS -o #{executable_name}.#{job_identifier}.o$PBS_JOBID
		#PBS -V
		#PBS -q dirac_reg
		#PBS -A gpgpu

		module load cuda
		module load nvidia-driver-util


		#


		### start of jobscript 
		cd $PBS_O_WORKDIR 
		echo "workdir: $PBS_O_WORKDIR" 
	#{code_run_environment}

		echo "Submitting #{nodes}x#{ppn}:#{gpu_name} job on #{CodeRunner::SYS} for project #@project..."
EOF
		end
	end
end
