class CodeRunner
	require SCRIPT_FOLDER + '/system_modules/slurm.rb'
	module Helios
		include Slurm
		def max_ppn
			16
		end
    def mpi_prog
	    nodes, ppn = @nprocs.split(/x/)
      nprocstot = nodes.to_i * ppn.to_i
      "srun -n #{nprocstot}"
    end 
	def run_command
		if use_launcher
			return %[#{code_run_environment}\n #@preamble #{mpi_prog}  #{executable_location}/#{executable_name} #{parameter_string} > #{output_file} 2> #{error_file}]
		else
			"#@preamble #{mpi_prog}  #{executable_location}/#{executable_name} #{parameter_string}"
		end
	end
	end
end
