class CodeRunner
	require SCRIPT_FOLDER + '/system_modules/moab.rb'
	module Hector
		include Moab
		def batch_script
			raise "Please specify project" unless @project
			super
		end
		def max_ppn
			32
		end
	end
end
