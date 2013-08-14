class CodeRunner
	require SCRIPT_FOLDER + '/system_modules/moab.rb'
	module Loki
		include Moab
	
		def max_ppn
			8
		end

	def mpi_prog
		"mpiexec -n #{nprocstot}"
	end

	def batch_script
		nodes, ppn = @nprocs.split(/x/)
          eputs "Warning: Underuse of nodes (#{ppn} cores per node instead of #{max_ppn})" if ppn.to_i < max_ppn
#		raise "Please specify project" unless @project
                raise "Error: cores per node cannot excede #{max_ppn}" if ppn.to_i > max_ppn
#		raise "Error: project (i.e. budget) not specified" unless @project
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
	#PBS -l nodes=#{nodes}:ppn=#{ppn}
	#{@wall_mins ? "#PBS -l walltime=#{sprintf("%02d:%02d:%02d", hours, mins, secs)}" : ""}
	#{@project ? "#PBS -A #@project" : ""}
        #PBS -q #{@runner.debug ? "debug" : "default"} 

	### start of jobscript 
	cd $PBS_O_WORKDIR 
	echo "workdir: $PBS_O_WORKDIR" 

	echo "Submitting #{nodes}x#{ppn} job on Loki for project #@project..."
	
	
EOF

	end

	end
end
