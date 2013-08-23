class CodeRunner
	require SCRIPT_FOLDER + '/system_modules/moab.rb'
	module Hector
		include Moab
		def batch_script
			raise "Please specify project" unless @project
			(eputs "Warning: number of nodes is not recommended (8, 16, 32, 64, 128, 256, 512, 1024, 2048 or 4096 recommended)"; sleep 0.2) unless [8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096].include? nodes.to_i
			(eputs "Warning: number of wall mins is not recommended (20, 60, 180, 360, 720 recomended)"; sleep 0.2) unless [20, 60, 180, 360, 720].include? @wall_mins.to_i
			super
		end
		def max_ppn
			32
		end
	end
end
