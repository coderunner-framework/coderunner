
class CodeRunner
	module BlueJoule

		require SCRIPT_FOLDER + '/system_modules/load_leveler.rb'
		include LoadLeveler
		def max_ppn
			16
		end
	end
end

