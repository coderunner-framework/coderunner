class CodeRunner
	class Cubecalc
		class WithNamelist < Cubecalc
			@source_code_subfolders = []
			setup_namelists(rcp.code_module_folder)

			def parameter_string
				'input_file.in'
			end

			def generate_input_file
				File.open('input_file.in', 'w'){|file| file.puts input_file_text}
			end

			def input_file_header
				<<EOF
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
!  Input file for the test program cubecalc_namelist
!
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

! #@defaults_file_description

EOF
			end

			def self.defaults_file_header
				<<EOF
#############################################################
#
# Defaults for the test program cubecalc_namelist
#
#############################################################

@defaults_file_description = "Basic defaults"
EOF
			end
		end
	end
end

