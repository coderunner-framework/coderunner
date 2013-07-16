
# A comment

class CodeRunner # declare the constant
end


# = CodeRunner Overview
#
# CodeRunner is a class designed to make the running an analysis of large simulations and easy task. An instance of this class is instantiated for a given root folder. The runner, as it is known, knows about every simulation in this folder, each of which has a unique id and a unique subfolder. 
#
# The heart of the runner is the variable run_list. This is a hash of IDs and runs. A run is an instance of a class which inherits from CodeRunner::Run, and which is customised to be able to handle the input variables, and the output data, from the given simulation code. This is achieved by a module which contains a child class of CodeRunner::Run, which is provided independently of CodeRunner.
#
# CodeRunner has methods to sort these runs, filter them according to quite complex conditions, print out the status of these runs, submit new runs, plot graphs using data from these runs, cancel running jobs, delete unwanted runs, and so on.
# 
# = CodeRunner Interfaces
#
# CodeRunner has two different interfaces:
#
# 1. Instance methods
# 2. Class methods
#
# == Instance Methods
#
# The instance methods provide a classic Ruby scripting interface. A runner is instantiated from the CodeRunner class, and passed a root folder, and possibly some default options. Instance methods can then be called individually. This is what should be used for complex and non-standard tasks.
#
# == Class methods
#
# The class methods are what are used by the command line interface. They define a standard set of tasks, each of which can be customised by a set of options known as command options, or <i>copts</i> for short.
#
# There is a one-to-one correspondence between the long form of the commandline commands, and the class methods that handle those commands, and between the command line flags, and the options that are passed to the class methods. So for example:
#
#	$ coderunner submit -p '{time: 23.4, resolution: 256}' -n  32x4 -W 600
#
# Becomes
# 
#	CodeRunner.submit(p: '{time: 23.4, resolution: 256}', n:  "32x4", W: 600) 
#		# remembering that braces are not needed around a hash if it is the final parameter.
# 
# These methods are what should be used to automate a large number of standard tasks, which would be a pain to run from the command line.

class CodeRunner

	class CRMild < StandardError # more of a dead end than an error. Should never be allowed to halt execution
		def initialize(mess="")
			mess += "\n\n#{self.class} created in directory #{Dir.pwd}"
			super(mess)
		end
	end
	class CRError < StandardError # usually can be handled
		def initialize(mess="")
			mess += "\n\n#{self.class} created in directory #{Dir.pwd}"
			super(mess)
		end
	end
	class CRFatal < StandardError # should never be rescued - must always terminate execution
		def initialize(mess="")
			mess += "\n\n#{self.class} created in directory #{Dir.pwd}"
			super(mess)
		end
	end
	# The defaults that are saved in the root folder
	
	FOLDER_DEFAULTS = [:code, :modlet, :executable, :defaults_file, :project]  
	
	# Parameters important to the submission of a run, which can be set by command line flags. The runner values provide the default values for the submit function, but can be overidden in that function. All the runner does with them is set them as properties of the run to be submitted. It is the run itself for which the options are relevant.
	
	SUBMIT_OPTIONS = [:nprocs, :wall_mins, :sys, :project, :comment, :executable]
	
	# A hash containing the defaults for most runner options. They are overridden by any options provided during initialisation. They are mostly set at the command line (in practice, the command line flags are read into the command options, which set these defaults in the function CodeRunner.process_command_options which calls CodeRunner.set_runner_defaults). However, if Code Runner is being scripted, these defaults must be set manually or else the options they specify must be provided when initialising a runner.
	
	DEFAULT_RUNNER_OPTIONS = ([:conditions, :sort, :debug, :script_folder, :recalc_all, :multiple_processes, :heuristic_analysis, :test_submission, :reprocess_all, :use_large_cache, :use_large_cache_but_recheck_incomplete, :use_phantom, :no_run, :server, :version, :parameters] + SUBMIT_OPTIONS + FOLDER_DEFAULTS).inject({}){|hash, option| hash[option] = nil; hash}
	
	# Options that apply across the CodeRunner class 
	
	CLASS_OPTIONS = [:multiple_processes].inject({}){|hash, option| 
		class_accessor option
		set(option, nil)
		hash[option] = nil; 
		hash
		}

	
	DEFAULT_RUNNER_OPTIONS.keys.each do |variable|
		#define accessors for class options and instance options
# 		class_accessor(variable)
		attr_accessor variable
# 		class_variable_set(variable, nil) 
	end
	
	
# 	def self.default_script_info
# 		Hash.phoenix('.code_runner_script_defaults.rb')
# # 		eval(File.read('.code_runner_script_defaults.rb'))
# 	end
# 	
# 	def self.add_to_default_script_info(hash)
# 		Hash.phoenix('.code_runner_script_defaults.rb') do |defaults|
# 			hash.each{|key,value| defaults[key] = value}
# 		end
# 	end

	DEFAULT_RUNNER_OPTIONS[:use_phantom] = :real
	DEFAULT_RUNNER_OPTIONS[:script_folder] = SCRIPT_FOLDER  #File.dirname(File.expand_path(__FILE__)) 

	# These are properties of the run class that must be defined. For more details see CodeRunner::Run.
	
	NECESSARY_RUN_CLASS_PROPERTIES = {
		:code => [String],
		:variables => [Array], 
		:naming_pars => [Array], 
		:results => [Array], 
		:run_info => [Array],  
		:code_long => [String],
		:excluded_sub_folders => [Array],
		:modlet_required => [TrueClass, FalseClass],
		:uses_mpi => [TrueClass, FalseClass]
	}

	# These are methods that the run class must implement. They should be defined in a code module.
	
	NECESSARY_RUN_CODE_METHODS = [
		:process_directory_code_specific, 
		:print_out_line, 
		:parameter_string, 
		:generate_input_file, 
		:parameter_transition, 
		:executable_location,
		:executable_name
	]
	
	
	# These are methods that the run class must implement. They should be defined in a system module.

	NECESSARY_RUN_SYSTEM_METHODS = [
		:queue_status, 
		:run_command, 
		:execute,
		:error_file, 
		:output_file, 
		:cancel_job
	]
	
	# These are the only permitted values for the run instance variable <tt>@status</tt>.
	
	PERMITTED_STATI = [:Unknown, :Complete, :Incomplete, :NotStarted, :Failed, :Queueing, :Running, :Held]


	include Log
#	Log.log_file = nil # Dir.pwd + "/.cr_logfile.txt"
#	puts Log.log_file, 'hello'
	Log.clean_up
	
	

	attr_accessor :run_list, :phantom_run_list, :combined_run_list, :ids, :phantom_ids, :combined_ids, :current_status, :run_class, :requests, :current_request, :root_folder, :print_out_size, :cache, :modlet, :code, :executable, :defaults_file
	attr_reader :max_id, :maxes, :cmaxes, :mins, :cmins, :start_id

	# Instantiate a new runner. The root folder contains a set of simulations, each of which has a unique ID. There is a one-to-one correspondence between a runner and a root folder: no two runners should ever be given the same root folder in the same script (there are safeguards to prevent this causing much trouble, but it should still be avoided on philosophical grounds), and no runner should be given a folder which has more than one set of simulations within it (as these simulations will contain duplicate IDs).
	#
	#
	# Options is a hash whose keys may be any of the keys of the constant <tt>DEFAULT_RUNNER_OPTIONS</tt>. I.e. to see what options can be passed:
	#
	#		p CodeRunner::DEFAULT_RUNNER_OPTIONS.keys

	def initialize(root_folder, options={})
		logf :initialize
		raise CRFatal.new("System not defined") unless SYS
		root_folder.sub!(/~/, ENV['HOME'])
		@root_folder = root_folder 
		read_defaults
		options.each do |key,value|
			key = LONG_TO_SHORT.key(key) if LONG_TO_SHORT.key(key)
			set(key, value) if value
		end
# 		ep options
		
		log 'modlet in initialize', @modlet
		
		@version= options[:version]
# 		ep 'ex', @executable
		#ep 'modlet is ', @modlet
		get_run_class

		@cache = {}
		
		@n_checks = 0
		@print_out_size = 0
		
		@run_list = {}; @ids = []
		set_max_id(0)

		@phantom_run_list = {}; @phantom_ids = []
		@phantom_id = -1

		@combined_run_list = {}; @combined_ids = []
	
		@current_request = nil
		@requests = []

		@pids= []
		@maxes = {}; @mins = {}
		@cmaxes = {}; @cmins = {}
	end

	def get_run_class
		@run_class = setup_run_class(@code, modlet: @modlet, version: @version, executable: @executable)
	end
	
	# Read the default values of runner options from the constant hash <tt>CodeRunner::DEFAULT_RUNNER_OPTIONS</tt>. This hash usually contains options set from the command line, but it can have its values edited manually in a script.
	# 
	# Also calls read_folder_defaults.

	
	def read_defaults
		DEFAULT_RUNNER_OPTIONS.each{|key,value| set(key, value)}
 				#ep DEFAULT_RUNNER_OPTIONS, @multiple_processes

		read_folder_defaults
		get_run_class
	end
	
	# Increase the value of <tt>@max_id</tt> by 1.
	
	def increment_max_id
		@max_id +=1
	end
	
	# Return an array of runs (run_list.values)
	
	def runs
		run_list.values
	end
	
	# Set the max_id. If the number given is lower than start_id, start_id is used. Use with extreme caution... if you set max_id to be lower than the highest run id, you may end up with duplicate ids.
	
	def set_max_id(number) # :doc:
# 		ep 'MAXES', @max_id, number, @start_id, 'END'
		@max_id = @start_id ? [@start_id, number].max : number
	end
		
	private :set_max_id


	# Read any default options contained in the file <tt>.code_runner_script_defaults.rb</tt> in the root folder.
	
	def read_folder_defaults
# 		p @root_folder + '/.code_runner_script_defaults.rb'
		if ENV['CODE_RUNNER_READONLY_DEFAULTS']
			hash = eval(File.read(@root_folder + '/.code_runner_script_defaults.rb'))
			FOLDER_DEFAULTS.each do |var|
				set(var, hash[var]) if hash[var]
			end
		else

			Hash.phoenix(@root_folder + '/.code_runner_script_defaults.rb') do |hash|
	# 			ep hash
				FOLDER_DEFAULTS.each do |var|
	# 				p send(var), hash[var]
					hash[var] = (send(var) or hash[var])
					hash[:code_runner_version] ||= CodeRunner::CODE_RUNNER_VERSION.to_s
					set(var, hash[var])
				end
				@start_id = hash[:start_id] if hash[:start_id]
	# 			ep "start_id: #@start_id"
				hash
			end
		end
		
		raise "No default information exists for this folder. If you are running CodeRunner from the commmand line please run again with the -C <code> and -X <executable> (and -m <modlet>, if required) flag (you only need to specify these flags once in each folder). Else, please specify :code and :executable (and :modlet if required) as options in CodeRunner.new(folder, options)" unless @code and @executable
	end

	# Here we redefine the inspect function p to raise an error if anything is written to standard out
	# while in server mode. This is because the server mode uses standard out to communicate
	# and writing to standard out can break it. All messages, debug information and so on, should always
	# be written to standard error.

	def p(*args)
		if @server
			raise "Writing to stdout in server mode will break things!"
		else
			super(*args)
		end
	end

	# Here we redefine the function puts to raise an error if anything is written to standard out
	# while in server mode. This is because the server mode uses standard out to communicate
	# and writing to standard out can break it. All messages, debug information and so on, should always
	# be written to standard error.

	def puts(*args)
		if @server
			raise "Writing to stdout in server mode will break things!"
		else
			super(*args)
		end
	end
	 
	# Here we redefine the function print to raise an error if anything is written to standard out
	# while in server mode. This is because the server mode uses standard out to communicate
	# and writing to standard out can break it. All messages, debug information and so on, should always
	# be written to standard error.

	def print(*args)
		if @server
			raise "Writing to stdout in server mode will break things!"
		else
			super(*args)
		end
	end

	def self.server_dump(obj)
		"code_runner_server_dump_start_E#{Marshal.dump(obj)}code_runner_server_dump_end_E"
	end
	
	def server_dump(obj)
		self.class.server_dump(obj)
	end
	
	def set_start_id(id)
		raise "start_id #{id} lower than max_id #@max_id" if @max_id and id < @max_id 
		Hash.phoenix(@root_folder + '/.code_runner_script_defaults.rb') do |hash|
			@start_id = hash[:start_id] = id
			hash
		end
	end
	
	# See CodeRunner.get_run_class_name
	
	def get_run_class_name(code, modlet)
		self.class.get_run_class_name(code, modlet)
	end
	
	# See CodeRunner.setup_run_class

	def setup_run_class(code, options)
		options[:runner] ||= self
		self.class.setup_run_class(code, options)
	end

	def self.old_get_run_class_name(code, modlet) # :nodoc:
		return modlet ? "#{code.capitalize}#{modlet.capitalize.sub(/\.rb$/, '').sub(/_(\w)/){"#$1".capitalize}}Run" : "#{code.capitalize}Run"
	end

	# Return the name of the run class according to the standard CodeRunner naming scheme. If the code name is 'a_code_name', with no modlet, the run class name will be <tt>ACodeName</tt>. If on the other hand there is a modlet called 'modlet_name', the class name will be <tt>ACodeName::ModletName</tt>.
	
	def self.get_run_class_name(code, modlet=nil) 
		return modlet ? "#{code.capitalize}::#{modlet.capitalize.sub(/\.rb$/, '').variable_to_class_name}" : "#{code.capitalize}"
	end


	def self.repair_marshal_run_class_not_found_error(err)
	    #ep 'error', err, err.message
			code, modlet = err.message.scan(/CodeRunner\:\:([A-Z][a-z0-9_]+)(?:::([A-Z]\w+))?/)[0]
			#ep 'merror', err, code, modlet; gets
			code.gsub!(/([a-z0-9])([A-Z])/, '\1_\2')
			(modlet.gsub!(/([a-z0-9])([A-Z])/, '\1_\2'); modlet.downcase!) if modlet	
			setup_run_class(code.downcase, modlet: modlet)
	end

	SETUP_RUN_CLASSES =[]
	
	# Create, set up and check the validity of the custom class which deals with a particular simulation code. This class will be defined in a custom module in the folder <tt>code_modules/code_name</tt>, where <tt>'code_name'</tt> is the name of the code. The only option is <tt>modlet:</tt>.
	#
	# If the custom class has already been set up, this method just returns the class.


		def self.setup_run_class(code, options={})
# 		logf(:setup_code)
# 		log(:code, code)
			
		modlet = options[:modlet]
		version = options[:version]
# 		log('modlet in setup_run_class', modlet)
		eputs "Loading modules for #{code}, #{modlet.inspect}..."
		
# 		modlet = modlet.sub(/\.rb$/, '') if modlet
		raise CRFatal.new("Code must contain only lowercase letters, digits, and underscore, and must begin with a letter or underscore; it is '#{code}'") unless code =~ /\A[a-z_][a-z_\d]*\Z/ 
		raise CRFatal.new("Input_file_module must contain only lowercase letters, digits, and underscore, and must begin with a letter or underscore; it is '#{modlet}'") if modlet and not modlet =~ /\A[a-z_][a-z_\d]*\Z/  

		run_class_name = get_run_class_name(code, modlet)

# 		p run_class_name

		return recursive_const_get(run_class_name) if SETUP_RUN_CLASSES.include?(run_class_name) #constants.include? (run_class_name).to_sym unless options[:force] #and const_get(run_class_name).rcp.code?
		#return const_get(run_class_name) if constants.include? (run_class_name).to_sym unless options[:force] #and const_get(run_class_name).rcp.code?
		SETUP_RUN_CLASSES.push run_class_name #.downcase
		FileUtils.makedirs(ENV['HOME'] + "/.coderunner/#{code}crmod/")
		FileUtils.makedirs(ENV['HOME'] + "/.coderunner/#{code}crmod/defaults_files")

		#Create the run_class, a special dynamically created class which knows how to process runs of the given code on the current system.
		#run.rb contains the basic methods of the class
# 		puts run_class_name; gets
# 		run_class = add_a_child_class(run_class_name, "")
		
# 		run_class.class_eval(%[
# 			@@code=#{code.inspect}; @@version=#{version.inspect}
# 			@@modlet=#{modlet.inspect} #modlet should be nil if not @@modlet_required
# 		        SYS = #{SYS.inspect}
# 		        include Log
# 			Log.logi(:code_just_after_runfile, @@code) 
# 			]
# 		)


		
		code_module_name = SCRIPT_FOLDER+ "/code_modules/#{code}/#{code}.rb"
		code_module_name = "#{code}crmod"
		require code_module_name
# 		ep get_run_class_name(code, nil)
		run_class = const_get(get_run_class_name(code, nil))
		run_class.instance_variable_set(:@code, code)
		run_class.instance_variable_set(:@sys, SYS)

		raise "#{run_class} must inherit from CodeRunner::Run: its ancestors are: #{run_class.ancestors}" unless run_class.ancestors.include? Run
		
		if options[:runner]
			run_class.runner = options[:runner]
			run_class.instance_variable_set(:@runner, options[:runner])
		end
		#Add methods appropriate to the current system

		system_module_name = SCRIPT_FOLDER+ "/system_modules/#{SYS}.rb"
		require system_module_name
		run_class.send(:include, const_get(SYS.variable_to_class_name))
# 		run_class.class_eval(File.read(system_module_name), system_module_name)


		
		#Some codes require an modlet; the flag modlet_required is specified in the code module
		if run_class.rcp.modlet_required
			raise CRFatal.new("Modlet necessary and none given") unless modlet
		end
		#If a modlet is specified (modlets can also be optional)
		if modlet
# 			Log.logi(:modlet, modlet)
			#if (	modlet_location =  "#{SCRIPT_FOLDER}/code_modules/#{code}/default_modlets";
			        #file_name = "#{modlet_location}/#{modlet}.rb"; 
				#FileTest.exist? file_name
			#)
			#elsif (		modlet_location =  "#{SCRIPT_FOLDER}/code_modules/#{code}/my_modlets";
			        #file_name = "#{modlet_location}/#{modlet}.rb"; 
				#FileTest.exist? file_name
			#)
			#else
				#raise CRFatal.new("Could not find modlet file: #{modlet}.rb")
			#end
			#require file_name
# 			ep run_class.constants
# 			ep run_class_names
			
		  modlet_file = "#{code}crmod/#{modlet}.rb"
			#ep ['requiring modlet file']
			require modlet_file
			run_class = recursive_const_get(run_class_name)
			run_class.instance_variable_set(:@modlet, modlet)
		end

		run_class.check_and_update
# 		log("random element of variables", run_class.variables.random)


# 		logi("run_class.variables[0] in setup_code", run_class.variables[0])
# 			ep 'finished'

		return run_class
	end

	# Traverse the directory tree below the root folder, detecting and analysing all runs within that folder. Although runs submitted by CodeRunner will all be in one folder in the root folder, it is not necessary for the runs to be organised like that. This is because CodeRunner can also be used to analyse runs which it did not submit.
	#
	# All subfolders of the root_folder will be analysed, except for ones specified in the run class property <tt>excluded_sub_folders</tt>, or those containing the hidden file '.CODE_RUNNER_IGNORE_THIS_DIRECTORY'
	
	def traverse_directories # :doc:
		string = ""
		#ep 'traversing', Dir.pwd
		if FileTest.exist?("code_runner_info.rb") or FileTest.exist?("CODE_RUNNER_INPUTS") or FileTest.exist?("README") or @heuristic_analysis and (Dir.entries(Dir.pwd).find{|file| not [".","..","data.txt"].include? file and File.file? file} and not Dir.entries(Dir.pwd).include? '.CODE_RUNNER_IGNORE_THIS_DIRECTORY')   
		#i.e. if there are some files in this directory (not just directories)
			eprint '.' if @write_status_dots
			begin

				raise CRMild.new("must recalc all") if @recalc_all or @reprocess_all #must recalculate the run results, not load them if @@recalc_all
				run = @run_class.load(Dir.pwd, self) #NB this doesn't always return an object of class run_class - since the run may actually be from a different code
				raise CRMild.new("not complete: must recalc") unless run.status == :Complete or run.status == :Failed
				raise CRMild.new("Not the right directory, must recalc") unless run.directory == Dir.pwd
			rescue ArgumentError, CRMild => err 
				if err.class == ArgumentError
					unless err.message =~ /marshal data too short/
						#puts err
						#puts err.backtrace
						raise  err
					end
				end
				log(err)
# 				puts err.class
				begin
					#interrupted = false; 
					#old_trap2 = trap(2){}
					#old_trap2 = trap(2){eputs "Interrupt acknowledged...#{Dir.pwd} finishing folder analyis. Interrupt again to override (may cause file corruption)."; interrupted = true}

					# Here we make sure we are creating a run object of the right class for this folder
					if FileTest.exist?('code_runner_info.rb') and File.read('code_runner_info.rb') =~ /Classname:.*?(?<class>[A-Z][\w:]+)/
						classname = $~[:class]
						begin 
							run_cls = Object.recursive_const_get(classname)
						rescue NameError=>err
							ep err, err.message
							self.class.repair_marshal_run_class_not_found_error(StandardError.new(classname))
							run_cls = Object.recursive_const_get(classname)
						end
					else
						run_cls = @run_class
					end

				 	run = run_cls.new(self).process_directory #NB this doesn't always return an object of class run_class - since the run may actually be from a different code
					#trap(2, old_trap2)
					#(eputs "Calling old interrupt #{Dir.pwd}"; Process.kill(2, 0)) if interrupted
				rescue => err
					log(err)
					unless @heuristic_analysis and (err.class == CRMild or err.class == CRError)
# 						puts Dir.pwd
						logd
						eputs Dir.pwd
						eputs err.class
						eputs err
# 						eputs err.backtrace
						eputs "----Only allowed to fail processing a directory if a heuristic analysis is being run"
						raise err
					end
# 					puts err.class
					run = nil
# 					puts @requests
				end
			end
			check = false
			if run
# 				puts run.id, @run_list[run.id]; gets
# 				raise CRFatal.new("\n\n-----Duplicate run ids: #{run.directory} and #{@run_list[run.id].directory}----") if @run_list[run.id]
				if @run_list[run.id] 
					check = true
						raise <<EOF 
Duplicate run ids:
New: #{run.run_name} #{run.status} in #{run.directory}
Old: #{@run_list[run.id].run_name} #{@run_list[run.id].status} in #{@run_list[run.id].directory}
EOF
					choice = Feedback.get_choice("Which do you want to keep, new or old? (The other folder will be deleted. Press Ctrl+C to cancel and sort the problem out manually)", ["New", "Old"])
					case choice
					when /New/
						raise "Aborting... this function has not been fully tested"
						FileUtils.rm_r(@run_list[run.id].directory)
					when /Old/
						raise "Aborting... this function has not been fully tested"
						FileUtils.rm_r(run.directory)
						run = nil
					end
				end
			end
			if run
				(puts "you shouldn't see this if you chose old"; gets) if check
				run.save
				@run_list[run.id] = run
				@ids.push run.id		
				@ids = @ids.uniq.sort
				@max_id = @max_id>run.id ? @max_id : run.id
			end
			if @heuristic_analysis
				Dir.foreach(Dir.pwd)do |directory|
					next if [".",".."].include? directory or File.file? directory or directory =~ /\.rb/ or @run_class.rcp.excluded_sub_folders.include? directory 
		# 			begin			
						Dir.chdir(directory) do 	
							traverse_directories
						end	
		# 			rescue Errno::ENOENT
		# 				log Dir.entries
		# 				puts directory + " was not a directory"
		# 			end
				end
			end

		else
			Dir.foreach(Dir.pwd)do |directory|
				next if [".",".."].include? directory or File.file? directory or directory =~ /\.rb/ or @run_class.rcp.excluded_sub_folders.include? directory 
	# 			begin			
					Dir.chdir(directory) do 	
						traverse_directories
					end	
	# 			rescue Errno::ENOENT
	# 				log Dir.entries
	# 				puts directory + " was not a directory"
	# 			end
			end
		end
	end
	private :traverse_directories

	# Write out a simple datafile containing all the inputs and outputs listed in the run class property <tt>readout_string</tt>. What is actually written out can be customised by redefining the method <tt>data_string</tt> in the run class, or changing <tt>readout_string</tt> or both.
	
	def write_data(filename = "data.txt")
		logf(:write_data)
		generate_combined_ids
		File.open(filename, "w") do |file|
			@combined_ids.each do |id|
				run = @combined_run_list[id]
				if run.status =~ /Complete/
					data_string = run.data_string
					raise CRFatal.new("data_string did not return a string") unless data_string.class == String
					file.puts data_string 
				end
			end
		end
	end
	
	# Sort the runs according to the variable <tt>@sort</tt> which can be either whitespace separated string or an array of strings. In the former case, the string is split to form an array of strings, using the separator <tt>/\s+/</tt>. For example, if
	#
	# @sort == ['height', '-weight', 'colour']
	#
	# Then the runs will be sorted according to first height, then (descending) weight, then colour. What actually happens is that the variable <tt>@ids</tt> is sorted, rather than <tt>@run_list</tt>. For this to work, height, weight and colour must be either variables or results or instance methods of the run class.
	#
	# Type can be either '' or 'phantom', in which case the variable sorted will be either <tt>@ids</tt> or <tt>@phantom_ids</tt> respectively.

	def sort_runs(type = @use_phantom.to_s.sub(/real/, ''))
		logf(:sort_runs)
		log(:type, type)
		#ep 'sort', @sort
		#sort_list = @sort ? (@sort.class == String ? eval(@sort) : @sort) : []
		run_list_name = [type.to_s, 'run_list'].join('_').gsub(/^_/, '')
		ids_name = [type.to_s, 'ids'].join('_').gsub(/^_/, '')
		log run_list_name 
			set(ids_name, send(ids_name).sort_by do |id|
				run = send(run_list_name)[id]
				sortkey = run.instance_eval((@sort or '[]'))
				#ep 'sortkey', sortkey
				sortkey

				#sort_list.map{|str| run.instance_eval(str)}
			end)
	end
	
	# Print out a summary of all the runs in the root folder, formatted in nice pretty colours. Since this is often called in a loop, if called twice without any arguments it will erase the first printout. To stop this happening set rewind to 0. If the command is being issued not in a terminal, so that CodeRunner cannot determine the size of the terminal, the second argument must be passed as an array of [rows, columns].

	def print_out(rewind = nil, options={}) # terminal_size = [rows, cols]
		rewind ||= @print_out_size
		terminal_size = options[:terminal_size]
		logf(:print_out)
# 		raise CRFatal.new("terminal size must be given if this is called any where except inside a terminal (for example if yo	u've called this as a subprocess)") unless terminal_size or $stdout.tty?
		terminal_size ||= Terminal.terminal_size
		#lots of gritty terminal jargon in here. Edit at your peril!
		
		unless ENV['CODE_RUNNER_NO_COLOUR']=='true' or ENV['CODE_RUNNER_NO_COLOR']=='true'
			dc= Terminal::WHITE #  .default_colour
			green= Terminal::LIGHT_GREEN
			cyan = Terminal::CYAN
			bblck = Terminal::BACKGROUND_BLACK
		else
			dc= ""# Terminal::WHITE #  .default_colour
			green= "" # Terminal::LIGHT_GREEN
			cyan = "" #Terminal::CYAN
			bblck = "" #Terminal::BACKGROUND_BLACK
		end
		cln = Terminal::CLEAR_LINE
# 		print "\033[#{rewind}A"
		deco = '-'*terminal_size[1]
		
		Terminal.erewind(rewind)
		
		eputs "\n#{cln}\n#{cln}\n#{bblck}#{dc}#{deco}\n#{@run_class.rcp.code_long} Status:#{cln}\n#{deco}"

		i = 0; j=0 # i is no. of actual terminal lines; j is number of results lines
		
		# Group the lines by major sort key
		#@split = @sort && @sort.split(/\s+/).size > 1 ? @sort.split(/\s+/)[0].to_sym : nil 
		@split_point = nil
		
		generate_combined_ids
		@combined_ids.each do |id|
			begin
	# 			puts id, :hello; gets
				@run = @combined_run_list[id]
				if filter
	# 				puts @run[:id], @id; gets
					#@new_split_point = @split ? @run.send(@split) : nil
					#if @split_point && @split_point != @new_split_point then eputs sprintf(" #{cln}", ""); i+=1 end
					#@split_point = @new_split_point
					eprint j%2==0 ? j%4==0 ? cyan : green : dc
					line = options[:with_comments] ? @run.comment_line : @run.print_out_line.chomp  
					eprint line
					eputs cln
	# 				puts (line.size / Terminal.terminal_size[1]).class
	# 				puts (line.size / Terminal.terminal_size[1])

					i+=((line.sub(/\w*$/, '').size-1)  / terminal_size[1]).ceiling
					j+=1
				end
# 				raise "monkeys"
			rescue => err
				eputs err
				eputs err.backtrace
				eputs "---------------------\nUnable to print out line for this job:"
				eputs "run_name: #{@run.run_name}"
				eputs "status: #{@run.status}\n-----------------------"
				Terminal.reset
				return
# 				raise CRFatal.new 
			end
		end
		@print_out_size = i+7# + (@run_list.keys.find{|id| not [:Complete, :Failed].include? @run_list[id].status } ? 0 : 1) 
		eprint dc, deco; Terminal.reset; eputs
# 		 puts
# 		puts
# 		puts dc # "\033[1;37m"
# 		print 'rewind size is', rewind

	end

	
# 	def filtered_run_list
# 		logf :filtered_run_list
# 		unless @use_phantom == :phantom
# 			return @run_list.find_all{|id, run| filter(run)}
# 		else
# 			log 'using phantom'
# 			return @phantom_run_list.find_all{|id, run| filter(run)}
# 		end
# 	end
	
	# Return a list of ids, filtered according to conditions. See CodeRunner#filter
	
	def filtered_ids(conditions=@conditions)
		generate_combined_ids
# 		ep @combined_run_list.keys
# 		sort_runs
		return @combined_ids.find_all{|id| filter(@combined_run_list[id], conditions)}
	end

	# Return true if 
	#		run.instance_eval(conditions) == true 
	# and false if 
	#	run.instance_eval(conditions) == false.
	# performing some checks on the validity of the variable <tt>conditions</tt>. For people who are new to Ruby instance_eval means 'evaluate in the context of the run'. Generally <tt>conditions</tt> will be something like 'status == :Complete and height == 4.5 and not width == 20', where height and width might be some input parameters or results from the diminishing.

	def filter(run=@run, conditions=@conditions)
		logf(:filter)
		@run = run
# 		to_instance_variables(directory)
		return true unless conditions 
#		p conditions, @run.id, @run.is_phantom
		conditions = conditions.dup	
		raise CRFatal.new("
-----------------------------
Conditions contain a single = sign: #{conditions}
-----------------------------") if conditions =~ /[^!=<>]=[^=~<>]/
		log conditions
		begin
			fil = @run.instance_eval(conditions)
		rescue => err
			eputs run.directory
			eputs conditions
			raise err
		end
		return fil
	end

	# Similar to CodeRunner#write_data, except that the readout is written to stdout, and formatted a bit. Will probably be rarely used.
	
	def readout
		logf(:readout)
		generate_combined_ids
		@split = @sort && @sort.split(/\s+/).size > 1 ? @sort.split(/\s+/)[0].to_sym : nil
		@split_point = nil
		string = @combined_ids.inject("") do |s, id|
			run = @combined_run_list[id]
			if run.status =~ /Complete/ and filter(run)  
				@new_split_point = @split ? run.send(@split) : nil
				splitter = (@split_point and @split_point != @new_split_point) ? "\n\n" : ""
				@split_point = @new_split_point
				splitter = "" # comment to put split points back in
# 				puts s.class, splitter.class, data_string(directory)
				data_string = run.data_string
				raise CRFatal.new("data_string did not return a string") unless data_string.class == String
				s + splitter + data_string 
			else 
				s 
			end
		end
# 		puts @max.inspect

		return string
	end
	
	# ? Probably can get rid of this one
	
	def readout_cols(*var_list) # :nodoc:
		logf :readout_cols
		ans = [[]] * var_list.size
		generate_combined_ids
		filtered_ids.each do |id|
			run = combined_run_list[id]
			var_list.each_with_index do |var, index|
				ans[index].push run.send(var)
			end
		end
		ans
	end
	
	# List every file in the root folder.
	
	def get_all_root_folder_contents # :nodoc:
		@root_folder_contents =[]
		Find.find(@root_folder){|file| @root_folder_contents.push file}
	end

	#Update the information about all the runs stored in the variable <tt>@run_list</tt>. By default, this is done by calling CodeRunner#traverse_directories. If, on the other hand, <tt>@use_large_cache</tt> is set to true, this is done by reading the temporary cache maintained in ".CODE_RUNNER_TEMP_RUN_LIST_CACHE" in the root folder. This is much quicker. If in addition <tt>@use_large_cache_but_recheck_incomplete</tt> is set to true, all runs whose status is not either :Complete or :Failed will be rechecked.
		
	def update(write_status_dots=true, use_large_cache=@use_large_cache, use_large_cache_but_recheck_incomplete=@use_large_cache_but_recheck_incomplete)
		@use_large_cache = use_large_cache
		logf(:update)
		@write_status_dots = write_status_dots

		@run_list={}
		@ids=[]
		@phantom_run_list = {}
		@phantom_ids = []
		@run_store =[]
# 		@multiple_processes_directories = []
		set_max_id 0
		@run_class.update_status(self)
		if @use_large_cache and not @recalc_all and not @reprocess_all
			log("using large cache")
			begin
				begin
					eputs 'Loading large cache...' if @write_status_dots
					Dir.chdir(@root_folder) do 
						@run_list = Marshal.load(File.read(".CODE_RUNNER_TEMP_RUN_LIST_CACHE"))
					end
					@run_list.values.each{|run| run.runner = self}
				rescue ArgumentError => err
					eputs err
					raise err unless err.message =~ /undefined class/
					#NB all code_names have to contain only lowercase letters:
# 					modlet, code = err.message.scan(/CodeRunner\:\:([A-Z][\w+])?([A-Z]\w+)Run/)[0]
					code, modlet = err.message.scan(/CodeRunner\:\:([A-Z][a-z0-9_]+)(?:::([A-Z]\w+))?/)[0]
# 					ep code.downcase, modlet
					modlet.downcase! if modlet
					setup_run_class(code.downcase, modlet: modlet)
					retry
				end
# 				ep @run_list
				@ids = @run_list.keys
 				@run_list.each{|id, run| run.runner = self }
				#eputs "Setting max id..."
				set_max_id(@ids.max || 0)
				#eputs "max_id = #@max_id"
# 				puts @max_id; gets
# 				@use_large_cache = false
				@ids.sort!
				redone_count = 0
				
				
# 					puts "hello"
# 				ep @use_large_cache_but_recheck_incomplete; exit
				recheck_incomplete_runs if use_large_cache_but_recheck_incomplete
# 				sort_runs
				eprint "Updating runs..." if @write_status_dots
# 				get_all_root_folder_contents
# 				puts @run_list.values[0].directory, File.expand_path(@root_folder).esc_regex
				fix_directories = (run_list.size > 0 and not @run_list.values[0].directory =~ File.expand_path(@root_folder).esc_regex)
# 				eputs 'fdirectories', fix_directories
# 				exit
				eputs "Fixing Directories..." if fix_directories
				@run_list.each do |id, run|
					eprint '.' if @write_status_dots
					run.directory = File.join(@root_folder, run.relative_directory) if fix_directories
# 					run.directory = "#@root_folder/#{run.relative_directory}"
# 					unless @root_folder_contents.include? run.directory# File.directory? run.directory and run.directory =~ File.expand_path(@root_folder).esc_regex
# 						if @root_folder_contents.include?(rel = File.join(@root_folder, run.relative_directory))
# 							run.directory = rel
# 						else
# 							raise CRFatal.new("Directory #{run.directory} not found")
# 						end
# 					end
# 					eputs @use_phantom
					#run.generate_phantom_runs #if @use_phantom.to_s =~ /phantom/i
					run.phantom_runs.each{|r| add_phantom_run(r)} if run.phantom_runs
				end
				eputs if @write_status_dots
				save_large_cache if fix_directories
# 				puts redone_count
				return self
			rescue Errno::ENOENT, ArgumentError, TypeError => err
				if err.class == ArgumentError and not err.message =~ /marshal data too short/ or err.class == TypeError and not err.message =~ /incompatible marshal file format/
					eputs err
					eputs err.backtrace
					raise CRFatal.new
				end
				eputs err, "Rereading run data"
# 				@use_large_cache = false
			end
		end

		log("not using large cache")
		@run_list={}
		@ids=[]
		@phantom_run_list = {}
		@phantom_ids = []
		@run_store =[]
# 		@multiple_processes_directories = []
		set_max_id 0

		log("traversing directories")
		eprint 'Analysing runs..' if @write_status_dots
		#interrupted = false; 
		#old_trap2 = trap(2){}
		#trap(2){eputs "Interrupt acknowledged... reloading saved cache. Interrupt again to override (may cause file corruption)."; trap(2, old_trap2); update(true, true, false); Process.kill(2,0)}
		Dir.chdir(@root_folder){traverse_directories}
		@max_id ||= 0
		eputs
# 		puts 'before request', @ids, @requests;
		respond_to_requests
# 		@n_checks += 1
# 		exit if ($nruns > 0 && @n_checks > $nruns) 
		sort_runs
		@recalc_all = false
# 		pp @run_list
		save_large_cache
		#@run_list.each{|id, run| run.generate_phantom_runs}
		#trap(2, old_trap2)
		#Process.kill(2, 0) if interrupted
		return self
	end
	
	# Dump all the instance variables of the runner to stdout as Marshalled binary data. This is used for RemoteCodeRunner server functions.
	
	def marshalled_variables
		#ep 'marsh1'
		instance_vars = {}
		instance_variables.each do |var|
			instance_vars[var] = instance_variable_get(var)
		end
		instance_vars[:@run_list].values.each{|run| run.runner=nil}
		#Kernel.puts server_dump(instance_vars)
		instance_vars[:@cache]={}
		instance_vars[:@phantom_run_list].values.each{|run| run.runner = nil}
		#ep 'marsh2'
		#eputs instance_vars.pretty_inspect
		#instance_vars.each do |var, val|
			#ep var
			#eputs server_dump(val)
		#end


		instance_vars
	end

	# Write the variable <tt>@run_list</tt>, which contains all information currently known about the simulations in the root folder, as Marshalled binary data in the file ".CODE_RUNNER_TEMP_RUN_LIST_CACHE". This cache will be used later by CodeRunner#update.
	
	def save_large_cache
# 		pp self
# 		ep @run_list
# 		pp @run_list.values.map{|run| run.instance_variables.map{|var| [var, run.instance_variable_get(var).class]}}
		
		generate_combined_ids
		@combined_run_list.each{|id, run| run.runner = nil; run.phantom_runs.each{|pr| pr.runner=nil} if run.phantom_runs}
		File.open(@root_folder + "/.CODE_RUNNER_TEMP_RUN_LIST_CACHE", 'w'){|file| file.puts Marshal.dump @run_list}
		@combined_run_list.each{|id, run| run.runner = self; run.phantom_runs.each{|pr| pr.runner=self} if run.phantom_runs}
	end

	# Self-explanatory! Call CodeRunner::Run#process_directory for every run whose status is not either :Complete or :Failed. (Note, for historical reasons traverse_directories is called rather than CodeRunner::Run#process_directory directly but the effect is nearly the same).
	
	def recheck_incomplete_runs
		logf :recheck_incomplete_runs
		@run_class.update_status(self)
		redone_count = 0
		run_list, @run_list = @run_list, {}; @ids = [];
		run_list.each do |id, run|
# 						print id
			if run.status == :Complete or run.status == :Failed
# 							print ".", id, "___"
				@run_list[id] = run
				@ids.push id
			else
# 							print id, "%%%"; 
				redone_count+=1
				Dir.chdir(run.directory){traverse_directories}
			end
		end
		@ids.sort!
# 		@ids = @run_list.keys
		set_max_id(@ids.max || 0)
		sort_runs
		respond_to_requests
		save_large_cache
	end

	# Self-explanatory! Call CodeRunner::Run#process_directory for every run for which CodeRunner#filter(run) is true. (Note, for historical reasons traverse_directories is called rather than CodeRunner::Run#process_directory directly but the effect is nearly the same).
	
	def recheck_filtered_runs(write_status_dots=false)
		@write_status_dots = write_status_dots
		logf :recheck_filtered_runs
		@run_class.update_status(self)
		@run_list.each do |id, run|
			if filter(run) and not (run.status == :Complete or run.status == :Failed)
# 				eputs run.directory
				Dir.chdir(run.directory){run.process_directory}
# 				eputs run.status
# 				ep run
			end
		end
		save_large_cache
# 		run_list, @run_list = @run_list, {}; @ids = []; @max_id = 0
# 		run_list.each do |id, run|
# 			if  not filter(run) or run.status == :Complete
# 				@run_list[id] = run
# 				@ids.push id
# 			else
# 				Dir.chdir(run.directory){traverse_directories}
# 			end
# 		end
# 		@ids.sort!
# 		@ids = @run_list.keys
		set_max_id(@ids.max || 0)
		sort_runs
		respond_to_requests
		save_large_cache
	end
	
	# One of the features of CodeRunner is two way communication between a runner and its runs. The runs can request actions from the runner directly by calling its instance methods, but often the runs want something to happen after the runner has processed every run in the directory. For example if a run wanted to check if it was resolved, it would need to know about all the other runs so it could compare itself with them. In this case it would place an instance method that it wanted to call in the variable <tt>@requests</tt> in the runner. The runner would then call that instance method on every run after it had finished processing all the runs.
	#
	# In summary, this method is called after every time the runner has checked through the directory. When it is called, it looks in the variable <tt>@requests</tt> which contains symbols representing methods. It calls each symbol as an instance method of every run in turn. So if <tt>@requests</tt> was <tt>[:check_converged]</tt> it would call <tt>run.check_converged</tt> for every run.

	def respond_to_requests
		logf(:respond_to_requests)
		logi(:@requests, @requests)
		log('@phantom_run_list.class', @phantom_run_list.class)
		while @requests[0]
			old_requests = @requests.uniq
			@requests = []
			old_requests.each do |request|
				@current_request = request
				if request == :traverse_directories # a special case
					@ids = []
					@run_list = {}
					@phantom_run_list = {}
					@phantom_ids = []

					Dir.chdir(@root_folder){traverse_directories}
				else
					filtered_ids.each do |id|
						run = @run_list[id]
						Dir.chdir(run.directory){run.instance_eval(request.to_s); run.save; run.write_results}
					end
				end
			end
		end
	end
	
	# Start a simulation: submit the run that is passed. What happens is as follows:
	#
	# 1. Modify the run according to options.
	# 2. Check if any other processes are submitting runs in the same root folder. In this case there will be a file called 'submitting' in the folder. If there is such a file wait until it is gone.
	# 3. Check if a run with identical parameters has been submitted before. In which case skip submitting the run unless options[:skip] == false.
	# 4. Call <tt>run.submit</tt>
	#
	#Options can be any one of <tt>CodeRunner::SUBMIT_OPTIONS</tt>. The options passed here will override values stored as instance variables of the runner with the same name, which will override these values if they are set in the runs itself. For example if
	#	run.nprocs == '32x4'
	#	runner.nprocs == nil
	#	options[:nprocs]  == nil
	# the number of processes will be 32x4. On the other hand if
	#	run.nprocs == '32x4'
	#	runner.nprocs == '24x4'
	#	options[:nprocs]  == '48x4'
	# the number of processes will be 48x4.

	def submit(runs, options={})
		eputs "System " + SYS 
		eputs "No. Procs " + @nprocs.inspect

		runs = [runs] unless runs.class == Array #can pass a single run to submit
			outruns = runs.dup
		skip = true unless options[:skip] == false
		SUBMIT_OPTIONS.each do |option|
			set(option, options[option]) if options.keys.include? option
		end
		logf(:submit)
		Dir.chdir(@root_folder) do
			@skip=skip
			mess = false
			while FileTest.exist?("submitting") 
				(eputs " Waiting for another process to finish submitting. If you know that no other CodeRunner processes are submitting in this folder (#@root_folder) then delete the file 'submitting' and try again"; mess = true) unless mess
				sleep rand
			end
# 			old_trap = trap(0)
			old_trap0 = trap(0){eputs "Aborted Submit!"; File.delete("#@root_folder/submitting"); exit!}
			old_trap2 = trap(2){eputs "Aborted Submit!"; File.delete("#@root_folder/submitting") if FileTest.exist? "#@root_folder/submitting"; trap(2, "DEFAULT"); trap(0, "DEFAULT"); Process.kill(2, 0)}
	# 		File.open("submitting", "w"){|file| file.puts ""}
			FileUtils.touch("submitting")
			unless options[:no_update_before_submit]
				@use_large_cache, ulc = false, @use_large_cache; update; @use_large_cache = ulc
			end
			generate_combined_ids(:real)
# 			old_job_nos = queue_status.scan(/^\s*(\d+)/).map{|match| match[0].to_i}
			script = "" if options[:job_chain]
			runs.each_with_index do |run, index|
				similar = similar_runs([], run)
				if @skip and similar[0] and not (options[:replace_existing] or options[:rerun])
					eputs "Found similar run: #{@run_list[similar[0]].run_name}"
					eputs "Skipping submission..."
					runs[index] = nil
					next
				end
				unless options[:replace_existing] or options[:rerun]
					@max_id+=1
					run.id = @max_id
				else
					if options[:replace_existing]
						FileUtils.rm_r run.directory 
				  elsif options[:rerun]
						################# For backwards compatibility
						SUBMIT_OPTIONS.each do |opt|
							 run.set(opt, send(opt)) unless run.send(opt)	
						end
						###########################################
						FileUtils.rm "#{run.directory}/code_runner_results.rb"
						FileUtils.rm "#{run.directory}/.code_runner_run_data"
					end
					@run_list.delete(run.id)
					@ids.delete run.id
					generate_combined_ids
				end

				begin
					
					unless options[:job_chain]
						run.prepare_submission unless options[:rerun]
						next if @test_submission
						Dir.chdir(run.directory) do 
							old_job_nos = queue_status.scan(/^\s*(\d+)/).map{|match| match[0].to_i}
							######################### The big tomale!
							run.job_no = run.execute  # Start the simulation and get the job_number
							#########################
							run.job_no = get_new_job_no(old_job_nos) unless run.job_no.kind_of? Integer # (if the execute command does not return the job number, look for it manually) 
# 							eputs 'run.job_no', run.job_no
							run.output_file = nil # reset the output file
							run.output_file # Sets the output_file on first call
							run.error_file = nil # reset the output file
							run.error_file # Sets the error_file on first call
							run.write_info
							eputs "Submitted run: #{run.run_name}"
						end
					else
						run.prepare_submission unless options[:rerun]
						script << "cd #{run.directory}\n"
						script << "#{run.run_command}\n"
						next if @test_submission
					end
				rescue => err
					File.delete("submitting")
					raise(err)
				end
			end # runs.each
			runs.compact!
			if options[:job_chain] and not @test_submission and runs.size > 0
				FileUtils.makedirs('job_chain_files')
				@id_list = runs.map{|run| run.id}
				
				#@executable ||= runs[0].executable
				@submission_script = script
				# A hook... default is to do nothing
				@submission_script = @run_class.modify_job_script(self, runs, @submission_script)
				# To get out of job_chain_files folder
				@submission_script = "cd .. \n" + @submission_script
				old_job_nos = queue_status.scan(/^\s*(\d+)/).map{|match| match[0].to_i}
				################ Submit the run
				Dir.chdir('job_chain_files'){job_no = execute}
				################
				job_no = get_new_job_no(old_job_nos) unless job_no.kind_of? Integer 	# (if the execute command does not return the job number, look for it manually) 
# 				eputs 'jobchain no', job_no
				#runs.each{|run| run.job_no = job_no}
				runs.each do |run| 
					run.job_no = @job_no = job_no
					run.output_file = run.relative_directory.split("/").map{|d| ".."}.join("/") + "/job_chain_files/" + output_file
					run.error_file = run.relative_directory.split("/").map{|d| ".."}.join("/") + "/job_chain_files/" + error_file
					run.write_info
					eputs "Submitted run: #{run.run_name}"
				end
			end
			@write_status_dots, wsd = false, @write_status_dots
			@run_class.update_status(self)
			runs.each do |run| 
# 				ep run.id, run_list.keys		
				Dir.chdir(run.directory){traverse_directories}
			end
			@write_status_dots = wsd	
			save_large_cache
			File.delete("submitting")
			trap(0, old_trap0)
			trap(2, old_trap2)
	
			
		end # Dir.chdir(@root_folder)
#     eputs
     #ep 'runs submitted', outruns
		return outruns[0].id if outruns.size == 1 #used in parameter scans 

	end # def submit
	
	def rcp
		@run_class.rcp
	end
	
	def executable_name
		return 'job_chain' unless @executable
		File.basename(@executable)
	end

	def executable_location
		return '' unless @executable
		File.dirname(@executable)
	end

	def code_run_environment
		run_class.new(self).code_run_environment
	end
	
	def run_command
		#ep 'submission_script', @submission_script
		@submission_script
	end
	
	private :run_command
	
	def job_identifier
		"#{@id_list[0]}-#{@id_list[-1]}"
	end
	
	#private :job_identifier
	
	# Assuming only one new job has been created, detect its job number.
	
	def get_new_job_no(old_job_nos) # :doc:
		#|| ""
# 			qstat = qstat=~/\S/ ? qstat : nil
		job_no = nil
		if self.respond_to? :queue_wait_attempts
			ntimes = queue_wait_attempts
		else
			ntimes = 5
		end
		eputs 'Waiting for job to appear in the queue...'
		ntimes.times do |i| # job_no may not appear instantly
# 				eputs queue_status
			new_job_nos = queue_status.scan(/^\s*(\d+)/).map{|match| match[0].to_i}
			job_no = (new_job_nos-old_job_nos).sort[0]
# 				eputs "job_no", job_no
			break if job_no
			sleep 0.2
			qstat = queue_status
			if i == ntimes
				eputs 'Timeout... perhaps increase queue_wait_attempts in the system module?'
			end
		end
		job_no ||= -1 # some functions don't work if job_no couldn't be found, but most are ok
	end
	
	private :get_new_job_no

# 	def submit
# 			
# # 			logi(:job_nos, job_nos)
# 			##################
# 			
# 			##################
# 			
# 			eputs info_file
# 			@sys = SYS
# 			
# 		end
# 		
# 
# 	else 
# 		File.delete("submitting")
# 		raise CRFatal.new("queue_status did not return a string; submission cancelled. Suggest editing system_modules/#{SYS}.rb")
# 	end
# 
# end

	
	# Create a new instance of the class <tt>@run_class</tt>
	
	def new_run
		logf(:new_run)
		@run_class.new(self)
	end

	@@wait = true #Do you wait for the previous run to have completed when using simple scan? 
	
	# Submit a series of runs according to scan_string. scan_string specifies a number of scans separated by hashes. Each scan has a number which is the ID of the run to start from followed by a colon. After the colon the user can write some code which modifies the original run. For example:
	#
	# 	simple_scan('23: @height *= 2; @weight *=1.1')
	#
	# will submit a series of runs, where each successive run has height twice the last one, and weight 1.1 times the last one, where we assume that height and weight are input parameters.
	#
	# Options are the same as CodeRunner#submit
	
	def simple_scan(scan_string, options={})
		scans = scan_string.split('#')
		ppipe = PPipe.new(scans.size + 1, true, controller_refresh: 0.5, redirect: false)
		pipe_numbers = ppipe.fork(scans.size - 1) 

		#p @run_class.naming_pars
		instructions = (scans[(ppipe.mpn > 0 ? ppipe.mpn - 1 : 0)])
		id = instructions.scan(/^\d+\:/)[0].to_i
		instructions = instructions.sub(/^\d+\:/, '')
		@run= id > 0 ?  @run_list[id] : (run  = @run_class.new(self); run.update_submission_parameters((options[:parameters] or '{}')); run)
	        @run_class.rcp.variables.each do |par|
		      #p par, @run_class.naming_pars
		      @run.naming_pars.push par if scan_string =~ Regexp.new(Regexp.escape(par.to_s))
		end
		@run.naming_pars.uniq!
# 		@run.naming_pars +== @run_class.naming_pars
		catch(:finished) do
		loop do #submit loop
			ppipe.synchronize(:submit) do 
			          @running = submit(@run, nprocs: options[:nprocs], version: @run_class.rcp.version)
                                   @conditions = "id == #@running"
				   #print_out
																	 #ep 'Running run', @running
			end
			loop do # check finished loop
				dir = @run_list[@running].directory
				@run_list.delete(@running)
				@run_class.update_status(self)
				Dir.chdir(dir) do
					traverse_directories
				end
				unless @@wait and (@run_list[@running].status == :Incomplete or @run_list[@running].status  == :NotStarted or @run_list[@running].status == :Queueing)
					@run.parameter_transition(@run_list[@running])
					@old_run = @run_list[@running]
					break
				end
				#p @running
				ppipe.i_send(:running, @running, tp: 0)
				if ppipe.is_root
					arr = (pipe_numbers + [0]).inject([]) do |arr, pn|
						arr.push ppipe.w_recv(:running, fp: pn)
					end
					#p arr
					@conditions = "#{arr.inspect}.include? id"
					print_out
				end
				sleep 3
			end
			@run.instance_eval(instructions)
		end
		end
		(ppipe.die; exit) unless ppipe.is_root
		ppipe.finish
	end

		
				
# 	        nprocs = options[:nprocs]
# # 		version = options[:version]
# 		skip = true unless options[:skip] == false
# 		logf(:submit)
# 		Dir.chdir(@root_folder) do

		
# 			run.nprocs =nprocs;
			
	# A parameter scan array is a list of parameter_scans:
	# 	[parameter_scan, parameter_scan, ...]
	# A parameter_scan is a list of variable scans:
	# 	[variable_scan, variable_scan, ...]
	# 
	# A variable_scan consists of a name, and a list of values;
	#
	#	['width', [0.3, 0.5, 0.6]]
	#
	# A parameter scan will scan through every possible combination of variable values, varying the final variable fastest. 
	#
	# In between each run it will call the hook function parameter_transition. This allows you to adjust the input variables of the next run based on the results of the previous.
	# e.g.
	#	parameter_scan_array = [
	#		[
	#			['width', [0.3, 0.5, 0.6]], ['height', [0.5, 4.3]]
	#		],
	#		[
	#			['width', [7.2, 0.6]], ['height', [3.6, 12.6, 12.9, 0.26]]
	#		]
	#	]
	#
	# This will run two simultaneous parameter scans: one with 3x2 = 6 runs; one with 2x4 = 8 runs, a total of 14 runs
	#
	# Any variables not specified in the parameter scan will be given their default values.
	

	def parameter_scan(parameter_scan, parameters, options={})
		skip = true unless options[:skip] == false
# 		version= (options[:version] or "")
		nprocs = options[:nprocs]
		logf(:parameter_scan)
		raise CRFatal.new("Wrong directory: parameter scan being conducted in #{Dir.pwd} instead of my root folder: #{@root_folder}") unless Dir.pwd == File.expand_path(@root_folder)
		@skip = skip
		puts parameter_scan.inspect
		
		@nprocs = nprocs; @skip=skip; 
		log '@run_class', @run_class
		@run = @run_class.new(self)
		@run.update_submission_parameters(parameters)
#  		@running_scans = {}; @gammas = {}
		beginning = "catch(:finished)  do \n"
		end_string = "\nend"
		parameter_scan.each do |variable_scan|
			beginning += %[ #{variable_scan[1].inspect}.each do |value|\n\t@run.#{variable_scan[0]} = value\n]
			@run_class.rcp.naming_pars.push variable_scan[0].to_sym; @run_class.rcp.naming_pars.uniq!
			end_string += %[\nend]
		end
		middle = <<EOF
@@psppipe.synchronize(:pssubmit){@running = submit(@run, nprocs: @nprocs, version: @version, skip: @skip); update};  
loop do
# 	@@mutex.synchronize{}
	@run_class.update_status(self)
# 	puts run_class.current_status
	Dir.chdir(@run_list[@running].directory){@run_list.delete(@running); traverse_directories}
# 	ep @run_list[@running].status, @run_list[@running].id, @run_list[@running].job_no, queue_status
	unless @run_list[@running].status == :Incomplete or @run_list[@running].status  == :NotStarted
		
		@run.parameter_transition(@run_list[@running])
		break
	end
	sleep 3
# 	Thread.pass
#  	puts Thread.current.to_s + " is looping, @run_list[@running].status = " + @run_list[@running].status.to_s + " @running = " + @running.to_s + " @run_list[@running].job_no = " + @run_list[@running].job_no.to_s  
end	
EOF
		command = beginning + middle + end_string
		puts command
		instance_eval(command, 'parameter_scan_code')
# 				puts Thread.current.object_id
# 				puts Thread.current.to_s; print " is finished"
# 		@@psppipe.i_send(:finished, true, tp: 0)
	
	end

	# Find runs whose input parameters are all the same as those for <tt>run</tt>, with the exception of those listed in <tt>exclude_variables</tt>
	
	def similar_runs(exclude_variables=[], run=@run) #all runs for which variables are the same as 'run', with the exception of exclude_variables
		logf(:similar_runs)
		raise CRFatal.new("generate_combined_ids must be called before this function is called") unless (@combined_run_list.size > 0 and @combined_ids.size > 0) or @ids.size ==0
		command = (run.class.rcp.variables+run.class.rcp.run_info-exclude_variables  - [:output_file, :error_file, :runner, :phantom_runs]).inject("@combined_ids.find_all{|id| @combined_run_list[id].class == run.class}"){ |s,v|	
			s + %<.find_all{|id| @combined_run_list[id].#{v}.class == #{run.send(v).inspect}.class and @combined_run_list[id].#{v} == #{run.send(v).inspect}}>} #the second send call retrieves the type conversion

#  		log command
  		#puts command
		begin 
			similar = instance_eval(command)
		rescue => err
			log command
			raise err
		end
		return similar
	end
	

# 	def max_conditional(variable,sweep=nil, conditions=nil)
# 		logf(:max_complete)
# 		return get_max_complete(variable,sweep, complete) == @run.id
# 	end

# 
# 	def max(variable,sweep=nil, complete=nil)
# 		logf(:max)
# 		return get_max(variable,sweep, complete) == @run.id
# 	end
# 
# 	def get_max(variable,sweep=nil, complete=nil)
# 		logf :get_max
# 		sweep ||= variable
# 		logi @run.maxes
# 		@run.maxes[variable] ||= {} 
# 		similar = similar_runs([sweep])
# 		similar = similar.find_all{|id| @combined_run_list[id].status == :Complete} if complete
# 		logi(:similar, similar, @combined_run_list[similar[0]].send(variable))
# 		@run.maxes[variable][sweep] ||= similar[1] ? similar.max{|id1,id2| @combined_run_list[id1].send(variable) <=> @combined_run_list[id2].send(variable)} : @run.id
# # 		puts "got_here"
# 		logi("@run.maxes[#{variable}][#{sweep}]", @run.maxes[variable][sweep])
# 		return @run.maxes[variable][sweep]
# 	end
	def get_max(run, variable,sweep, complete=nil)
		logf :get_max
		generate_combined_ids
		sweep = [sweep] unless sweep.class == Array
		similar = similar_runs(sweep, run)  
		similar = similar.find_all{|id| @combined_run_list[id].status == :Complete} if complete
		logi(:similar, similar, @combined_run_list[similar[0]].send(variable))
		max = similar[1] ? similar.max{|id1,id2| @combined_run_list[id1].send(variable) <=> @combined_run_list[id2].send(variable)} : similar[0]
	# 		puts "got_here"
		return max
	end

	def get_min(run, variable,sweep, complete=nil)
		logf :get_min
		generate_combined_ids
		sweep = [sweep] unless sweep.class == Array
		similar = similar_runs(sweep, run)  
		similar = similar.find_all{|id| @combined_run_list[id].status == :Complete} if complete
		logi(:similar, similar, @combined_run_list[similar[0]].send(variable))
		min = similar[1] ? similar.min{|id1,id2| @combined_run_list[id1].send(variable) <=> @combined_run_list[id2].send(variable)} : similar[0]
	# 		puts "got_here"
		return min
	end
	
# 
# 	def get_max_conditional(variable,sweep=nil, conditions=nil)
# 		logf(:get_max_conditional)
# 		raise CRFatal.new("generate_combined_ids must be called before this function is called") unless @combined_run_list[0]
# 		sweep ||= variable
# 		similar = similar_runs([sweep]).find_all{|id| filter(@combined_run_list[id], conditions)}
# 		similar = similar.find_all{|id| @combined_run_list[id].status == :Complete} if complete
# 		logi(:similar, similar, @combined_run_list[similar[0]].send(variable))
# 		id_of_max = similar[1] ? similar.max{|id1,id2| @combined_run_list[id1].send(variable) <=> @combined_run_list[id2].send(variable)} : @run.id
# # 		puts "got_here"
# 		return id_of_max
# 	end


	# Duplicate the runner, trying to be intelligent as far as possible in duplicating instance variables. Not fully correct yet. Avoid using at the moment.
				                               
	def dup
		logf(:dup)
		new_one = self.class.new(@code, @root_folder, modlet: @modlet, version: @version)
		new_one.ids = @ids.dup; new_one.phantom_ids = @phantom_ids.dup;
		new_one.run_list = @run_list.dup; new_one.phantom_run_list = @phantom_run_list.dup
		new_one.run_class = @run_class
		return new_one
	end

	# Delete the folders of all runs for whom CodeRunner#filter(run) is true. This will permanently erase the runs. This is an interactive method which asks for confirmation.

	def destroy(options={})
		ids = @ids.find_all{|id| filter @run_list[id]}
		unless options[:no_confirm]
			logf(:destroy)			
			puts "About to delete:"
			ids.each{|id| eputs @run_list[id].run_name}
			return unless Feedback.get_boolean("You are about to DESTROY #{ids.size} jobs. There is no way back. All data will be eliminated. Please confirm the delete.")
			#gets
			eputs "Please confirm again. Press Enter to confirm, Ctrl + C to cancel"
			gets
		end
		ids.each{|id| 
			FileUtils.rm_r @run_list[id].directory if @run_list[id].directory and not ["", ".", ".."].include? @run_list[id].directory
			@run_list.delete(id); @ids.delete(id); generate_combined_ids}
		set_max_id(@ids.max || 0)
		save_large_cache
		generate_combined_ids
	end

	# Cancel the job with the given ID. Options are:
	# 	:no_confirm  ---> true or false, cancel without asking for confirmation if true
	# 	:delete ---> if (no_confirm and delete), delete cancelled run
	
	def cancel_job(id, options={})
		@run=@run_list[id]
		raise "Run with id #{id} does not exist" unless @run
		unless options[:no_confirm]
			eputs "Cancelling job: #{@run.job_no}: #{@run.run_name}. \n Press enter to confirm"
	# 		puts 'asfda'
			gets
		end
		@run.cancel_job
		if options[:no_confirm] 
			delete =  options[:delete]
		else
			delete = Feedback.get_boolean("Do you want to delete the folder (#{@run.directory}) as well?")
		end
		FileUtils.rm_r(@run.directory) if delete and @run.directory and not @run.directory == ""
		update
		print_out
	end
	
	# Needs to be fixed.

# 	def rename_variable(old, new)
# 		puts "Please confirm complete renaming of #{old} to #{new}"
# 		gets
# 		@run_list.each do |directory|
# 			Dir.chdir directory[:directory] do
# 				begin
# 					@readme = File.read("CODE_RUNNER_INPUTS")
# 				rescue Errno::ENOENT => err
# 		# 			puts err, err.class
# 					@readme = File.read("README")
# 				end
# 				@readme.sub!(Regexp.new("^\s+#{old}:"), "^\s+#{new}:")
# 				File.open("CODE_RUNNER_INPUTS_TEST", 'w'){|file| file.puts @readme}
# 			end
# 		end
# 		old_recalc, @recalc_all = @recalc_all, true
# 		update
# 		@recalc_all = old_recalc
# 	end

	def add_phantom_run(run)
		@phantom_run_list[@phantom_id] = run
		@phantom_ids.push @phantom_id
		#run.real_id = run.id
		run.id = @phantom_id
		@phantom_id += -1
	end

	def generate_combined_ids(kind= nil)
		logf(:generate_combined_ids)
# 		case purpose
# 		when :print_out
# 			@combined_ids = []
# 			@combined_ids += @phantom_ids if @run_class.print_out_phantom_run_list
# 			@combined_ids += @ids if @run_class.print_out_real_run_list
# 		when :readout
# 			@combined_ids = []
# 			@combined_ids += @phantom_ids if @run_class.readout_phantom_run_list
# 			@combined_ids += @ids if @run_class.readout_real_run_list
# 		when :submitting
# 			@combined_ids = @ids
		kind ||= @use_phantom
		case kind
		when :real
			@combined_ids = @ids
		when :phantom
			@combined_ids = @phantom_ids
		when :both
			@combined_ids = @ids + @phantom_ids
		else
			raise CRFatal.new("Bad use phantom variable: #{kind.inspect}")
		end
		log('@phantom_run_list.class', @phantom_run_list.class)
		#puts 'crlist', @phantom_run_list.keys, @run_list.keys
		@combined_run_list = @phantom_run_list + @run_list
		log(:kind, kind)
# 		log(:combined_ids, @combined_ids)
		sort_runs(:combined)
	end
	
	def save_all
		save_large_cache
		@run_list.values.each do |run|
			run.save
			run.write_results
		end
	end
	
	def save_all_and_overwrite_info
		save_all
		@run_list.values.each do |run|
			run.write_info
		end
	end
	
	private :save_all_and_overwrite_info
	
	# Permanently change the id of every run in the folder by adding num to them. Num can be negative unless it makes any of the ids negative. Use if you want to combine these runs with the runs in another folder, either by creating an instance of CodeRunner::Merge, or by directly copying and pasting the run folders.
	
	def alter_ids(num, options={})
		Dir.chdir(@root_folder) do
			return unless options[:no_confirm] or Feedback.get_boolean("This will permanently alter all the ids in the folder #@root_folder. Scripts that use those ids may be affected. Do you wish to continue?")
			raise ArgumentError.new("Cannot have negative ids") if @run_list.keys.min + num < 0
			runs = @run_list.values
			fids = filtered_ids
			@run_list = {}
			runs.each do |run|
				old_id = run.id
				if fids.include? old_id
					run.id += num
					old_dir = run.relative_directory
					new_dir = old_dir.sub(Regexp.new("id_#{old_id}(\\D|$)")){"id_#{run.id}#$1"}
	# 				ep old_dir, new_dir
					FileUtils.mv(old_dir, new_dir)
					run.relative_directory = new_dir
					run.directory = File.expand_path(new_dir)
				end
				@run_list[run.id] = run
			end
			@ids = @run_list.keys
			set_max_id(@ids.max || 0)
			save_all_and_overwrite_info
		end
	end
		
	def continue_in_new_folder(folder, options={})
		Dir.chdir(@root_folder) do
			raise "Folder already exists" if FileTest.exist?(folder)
			FileUtils.makedirs("#{folder}/v")
			#FileUtils.makedirs(folder)
			FileUtils.cp(".code_runner_script_defaults.rb", "#{folder}/.code_runner_script_defaults.rb")
			FileUtils.cp(".code-runner-irb-save-history", "#{folder}/.code-runner-irb-save-history")
			FileUtils.cp("#{@defaults_file}_defaults.rb", "#{folder}/#{@defaults_file}_defaults.rb")
			if options[:copy_ids]
				options[:copy_ids].each do |id|
					FileUtils.cp_r(@run_list[id].directory, "#{folder}/v/id_#{id}")
				end
			end

		end
	end

	# Create a tar archive of the root folder and all the files in it. Options are
	# 	:compression => true or false 
	# 	:folder => folder in which to place the archive.
	# 	:verbose => true or false
	# 	:group => group of new files
	#
	def create_archive(options={})
		verbose = options[:verbose] ? 'v' : ''
		very_verbose = options[:very_verbose] ? 'v' : ''
		comp = options[:compression]
		Dir.chdir(@root_folder) do
			temp_root = ".tmparch/#{File.basename(@root_folder)}"
			FileUtils.makedirs(temp_root)
			system "chgrp  #{options[:group]} #{temp_root}" if options[:group]
			size=@run_list.size
			@run_list.values.each_with_index do |run, index|
				archive_name = "#{File.basename(run.directory)}.tar#{comp ? 
									'.gz' : 
									''}"
				tar_name = archive_name.delsubstr('.gz')
				relative = run.directory.delete_substrings(@root_folder, File.basename(run.directory))
				FileUtils.makedirs(temp_root +  relative)
				unless FileTest.exist? temp_root +  relative + archive_name
				eputs "Archiving #{index} out of #{size}" if options[:verbose]
					Dir.chdir(run.directory + '/..') do
							command =  "tar -cW#{very_verbose}f #{tar_name} #{File.basename(run.directory)}"
							eputs command if options[:verbose]
							unless system command
								raise "Archiving failed"
							end
							break unless comp
							command = "gzip -4 -vf #{tar_name}"
							eputs command if options[:verbose]
							unless system command
								raise "Compression failed"
							end
							command = "gzip -t #{archive_name}"
							eputs command if options[:verbose]
							unless system command
								raise "Compression failed"
							end
							#exit
					end
					FileUtils.mv(relative.delsubstr('/') + archive_name, temp_root + '/' + relative + archive_name)
				end
				
				system "chgrp -R #{options[:group]} #{temp_root}" if options[:group]
			end
			Dir.entries.each do |file|
				case file
				when '.', '..', '.tmparch'
					next
				when /^v/
					next unless File.file? file
				else
					FileUtils.cp_r(file, "#{temp_root}/#{file}")
				end
			end
			Dir.chdir('.tmparch') do
		  	command = "tar -cWv --remove-files -f #{File.basename(@root_folder)}.tar #{File.basename(@root_folder)}"
		  	command = "tar -cWv -f #{File.basename(@root_folder)}.tar #{File.basename(@root_folder)}"
				eputs command if options[:verbose]
				raise "Archiving Failed" unless system command
			end
			FileUtils.mv(".tmparch/#{File.basename(@root_folder)}.tar", "#{File.basename(@root_folder)}.tar")
			#FileUtils.rm_r(".tmparch")
		end
	end



	
	
end








[
	"/graphs_and_films.rb", 
	"/remote_code_runner.rb", 
	"/merged_code_runner.rb",
	'/run.rb', 
	'/heuristic_run_methods.rb', 
].each do |file|
		file = CodeRunner::SCRIPT_FOLDER + file
		require file
		eprint '.' unless $has_put_startup_message_for_code_runner	
end
