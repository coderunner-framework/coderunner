class CodeRunner
	require SCRIPT_FOLDER + '/system_modules/slurm.rb'
	module Helios
		include Slurm
		#def batch_script
			#raise "Please specify project" unless @project
			#super
		#end
		def max_ppn
			16
		end
	end
end
