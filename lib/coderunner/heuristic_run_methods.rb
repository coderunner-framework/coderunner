class CodeRunner
	
	class Run
	
def run_heuristic_analysis
	
	begin
		
		puts Dir.pwd
		raise CRMild.new("can't find input file") unless @rcp.input_file_extension
		input_file = Dir.entries.find_all{|file| file =~ Regexp.new("^[^.].*"+Regexp.escape(rcp.input_file_extension) + "$")}[0]
		raise CRMild.new("can't find input file") unless input_file
		log(input_file)
		input_file_text = File.read(input_file)
		@run_name = File.basename(input_file, rcp.input_file_extension) if rcp.use_file_name_as_run_name
		analyse_input_file_text(input_file_text)
		log("Automatic analysis complete")
# 				logiv
	rescue CRMild => err
		log(err)
		input_file = Feedback.get_choice("Unable to find a code runner inputs file. If there is another input file please choose it from this list", Dir.entries(Dir.pwd).find_all{|file| not [".",".."].include? file and File.file? file} + ["not available"])
		if input_file == "not available"
			FileUtils.touch('.CODE_RUNNER_IGNORE_THIS_DIRECTORY')
			raise CRError.new("run could be analysed, or folder does not contain a run")
		end
		input_file_text = File.read(input_file)
		log(input_file_text)
		analyse_input_file_text(input_file_text)
# 				logiv
		rcp.input_file_extension = File.extname(input_file)
		@rcp.use_file_name_as_run_name = Feedback.get_boolean("Do you want to use the input file name (minus the extension) as a run name? (Your answer will apply to all directories with code runner inputs files).") if rcp.use_file_name_as_run_name.class == NilClass
		@run_name = File.basename(input_file, rcp.input_file_extension) if rcp.use_file_name_as_run_name
	end
end


def analyse_input_file_text(input_file_text)
	logf(:analyse_input_file_text)
	pars = self.class.analyse_input_file_text(input_file_text, rcp.matching_regex)[0]
# 	log("These pars were found in the input file"); logi(pars)
 	logi(rcp.variables[rcp.variables.keys[0]])
	pars.each do |id, hash|
#  		puts hash.inspect
# 		puts @@variables[hash[:name].to_sym].inspect
		if rcp.variables[hash[:name].to_sym]
			set(hash[:name].to_sym, hash[:default].send(rcp.variables[hash[:name].to_sym]))
			# @@variables[hash[:name].to_sym] is the type conversion appropriate for the variable hash[:name]
		end
	end
end


@@successful_trial_system = nil
@@successful_trial_class = nil

def try_by_system(expected_return=NilClass, &block)
# 	puts "Trying by system"
# 	puts @@system_run_classes[0].new(@runner).inspect
	@@system_triers ||= rcp.system_run_classes.inject({}){|hash, run_class| 
# 		puts run_class.new(@runner).learn_from(self).inspect
		log hash.class
		hash[run_class] = run_class.new(@runner).learn_from(self).freeze
		hash}
# 	puts @system_triers.inspect
# 	i=0
	answer = nil
	if @@successful_trial_class
		begin
			answer = yield(@@system_triers[@@successful_trial_class].dup, self)
			raise CRError.new("trial returned an answer, but answer was not of the right class") unless expected_return == NilClass or answer.is_a? expected_return
			return answer
		rescue => err
			log err
		end
	end

	@@system_triers.values.each do |trier|
		begin	
# 			puts i
# 			i+=1
#  			puts trier.class.ancestors
# 			puts "asld"
			answer = yield(trier.dup, self)
# 			puts expected_return
# 			puts answer.is_a? Fixnum
# 			puts "Sd"
			raise CRError.new("trial returned an answer, but answer was not of the right class") unless expected_return == NilClass or answer.is_a? expected_return 
#  			puts answer, "HASG"
# 			puts "asfd"
			@@successful_trial_system = trier.class.run_sys_name
			@@successful_trial_class = trier.class
# 			puts @@successful_trial_system
			return answer
		rescue Errno::ENOENT, TypeError, CRMild, CRError => err
# 			puts err
			next
		end
	end
# 	puts answer; gets
# 	answer
	raise CRError.new("try by system was not successful")
end	


def try_to_get_job_number
	begin
		job_no = try_by_system(Fixnum) do |trier, myself|	

			trier.executable_name = "mx123456zz"
			trier.job_no = "mx123456yy"
			trier.version = ""

			scanner = Regexp.new(Regexp.escape(trier.output_file).sub("mx123456zz", ".+").sub("mx123456yy", "(?<jobno>\\d+)$"))
			answer = nil
			Dir.entries(Dir.pwd).each do |file|

					return   $~[:jobno].to_i if file =~ scanner
	# 			end
			end

			nil
		end
	rescue CRError => err
		job_no = -1
	end
	job_no
# 	exit
end

def try_to_get_output_file
	#very hacky!
	logf(:try_to_get_output_file)
	begin
		out_file =  try_by_system(String) do |trier, myself|
	# 		trier = trier.dup
	# 		puts trier
			trier.executable_name = "mx123456zz"
			trier.job_no = "mx123456yy"
			trier.version = ""
			scanner = Regexp.new("(?<outputfile>"+Regexp.escape(trier.output_file).sub("mx123456zz", ".+").sub("mx123456yy", "\\d+")+")")
# 			ep scanner
			ans = nil
			Dir.entries(Dir.pwd).each do |file|
				ans = $~[:outputfile] if file =~ scanner 
			end
			ans
		end
	rescue CRError => err
		log(err)
		out_file = nil
	end
	out_file
end

def try_to_get_error_file
	logf(:try_to_get_error_file)
	begin
		error_file =  try_by_system(String) do |trier, myself|
	# 		trier = trier.dup
	# 		puts trier
			trier.executable_name = "mx123456zz"
			trier.job_no = "mx123456yy"
			trier.version = ""
			scanner = Regexp.new("(?<outputfile>"+Regexp.escape(trier.error_file).sub("mx123456zz", ".+").sub("mx123456yy", "\\d+")+")")
			ans = nil
			Dir.entries.each do |file|
				if file =~ scanner
	# 				puts $~[:outputfile] 
					ans = $~[:outputfile] 
				end
			end
			ans
		end
	rescue CRError => err
 		log(err)
		error_file = nil
	end
	log("Error file was: ", error_file)
	if error_file
		begin
			logi(File.readlines(error_file))
			logi(File.readlines(error_file).size)
			logi(File.readlines(error_file).size.class)
		rescue => err
			log(err)
		end
	end
	return error_file
end

def try_to_find_job_output_ends
	output = try_to_get_output_file
	return nil unless output
#  	return try_by_system(Fixnum) do |trier, myself|
	found = File.read(output) =~ /job output ends/i
	return found ? true : false
#  	end
end

end

end