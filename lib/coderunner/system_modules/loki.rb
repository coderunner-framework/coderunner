class CodeRunner
	require SCRIPT_FOLDER + '/system_modules/moab.rb'
	module Loki
		include Moab
	
		def max_ppn
			8
		end
	def batch_script
		nodes, ppn = @nprocs.split(/x/)
		eputs "Warning: Underuse of nodes (#{ppn} cores per node instead of 4)" if ppn.to_i < 4
		raise "Please specify project" unless @project
		raise "Error: cores per node cannot excede 4" if ppn.to_i > max_ppn
#		raise "Error: project (i.e. budget) not specified" unless @project
		ppn ||= 4
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
        #PBS -q #{@runner.debug ? "debug" : "regular"} 

	### start of jobscript 
	cd $PBS_O_WORKDIR 
	echo "workdir: $PBS_O_WORKDIR" 

	echo "Submitting #{nodes}x#{ppn} job on Hector for project #@project..."
	
	
EOF

	end

	end
end
