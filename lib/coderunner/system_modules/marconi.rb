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
	end
end
