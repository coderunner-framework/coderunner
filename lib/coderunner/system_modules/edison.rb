cass CodeRunner
	require SCRIPT_FOLDER + '/system_modules/moab.rb'
	module Edison
		include Moab
 		def batch_script
			#raise "Please specify project" unless @project
			"#PBS -q regular\n" + super
		end
		def max_ppn
			16
		end
	end
end
