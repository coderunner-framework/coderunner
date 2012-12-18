
class CodeRunner
	module BlueJoule

		require SCRIPT_FOLDER + '/system_modules/loadleveler.rb'
		include LoadLeveler
		def max_ppn
			16
		end
	end
end

