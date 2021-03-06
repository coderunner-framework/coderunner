class CodeRunner::Run
class FortranNamelistC < FortranNamelist
	# Given the folder where the source code resides, return a single string containing all the code

	@fortran_namelist_source_file_match = /(\.c|\.cpp|\.cu|\.cc)$/

	@fortran_namelist_variable_match_regex = /^[^\/]*?fnr_get_(?<type>\w+)\(\&?[\w\s]+\s*,\s*["'](?<namelist>\w+)[\d()]*?['"]\s*,\s*['"](?<variable>\w+)[()0-9]*['"],[^)]+\)\)\s*[\w\[\]\d]+\s*=\s*(?<default>\S+)\s*;/
		#
	# Find all input namelists and variables by scanning the source code
	#
	def self.get_namelists_and_variables_from_source_code(source)
		nms = {}
		all_variables_in_source = {}
		namelist_declarations = {}
		#source.scan(/^\s*namelist\s*\/(?<namelist>\w+)\/(?<variables>(?:(?:&\s*[\n\r]+)|[^!\n\r])*)/) do 
		#source.scan(Regexp.new("#{/^\s*namelist\s*\/\s*(?<namelist>\w+)\s*\//}(?<variables>#{FORTRAN_SINGLE_LINE})")) do 
		source.scan(rcp.fortran_namelist_variable_match_regex) do
			namelist = $~[:namelist].to_s.downcase.to_sym
			#variables = $~[:variables].gsub(/!.*/, '')
			#eputs namelist, variables
			#namelist_declarations[namelist] = variables
			#gets # if namelist == :collisions_knobs

			#next if [:stuff, :ingen_knobs].include? namelist
			nms[namelist] ||= []
			all_variables_in_source[namelist] ||= []
	# 		puts variables
			#variables.scan(/\w+/) do 
				var =  $~[:variable].to_sym
	# 			(p variables, namelist; exit) if var == :following or var == :sou
				all_variables_in_source[namelist].push var
				next if known_code_variable?(namelist, var)
				nms[namelist].push var
			#end
			nms[namelist].uniq!
			all_variables_in_source[namelist].uniq!
		end
		return [nms, all_variables_in_source, namelist_declarations]
	end
	def self.get_sample_value(source, var)
		sample_val = nil
		source.scan(rcp.fortran_namelist_variable_match_regex) do
			#p $~
			
			next unless var == $~[:variable].to_sym
			sample_val = eval($~[:default].sub(/(\d\.)$/, '\10').sub(/^(\.\d)/, '0\1').sub(/(\d\.)[eE]/, '\10e'))
		end
		raise "Couldn't get a sample value for #{var.inspect}" unless sample_val
		return sample_val
	end
	def self.update_defaults_from_source_code(source_code_folder = ARGV[-1])
		source = get_aggregated_source_code_text(source_code_folder)
		rcp.namelists.each do |nml, nmlhash|
			nmlhash[:variables].each do |var, varhash|
				varhash[:autoscanned_defaults] = [get_sample_value(source, varhash[:code_name]||var)] rescue []
				save_namelists
			end
		end
	end

end
end
