class CodeRunner
	
	module InteractiveMethods
		COMMANDS.each do |command|
			eval("def #{command[1]}(*args) 
# 			     if args[-1].kind_of? 
					CodeRunner.send(#{command[0].to_sym.inspect}, *args)
						end")
		end
		def up
			ObjectSpace.each_object{|obj| obj.update if obj.class.to_s =~ /CodeRunner$/}
			nil
		end
		def cd(dirct)
			Dir.chdir(dirct)
		end
		def setup_interactive
			@runner = CodeRunner.fetch_runner(CodeRunner::DEFAULT_COMMAND_OPTIONS.dup) unless CodeRunner::DEFAULT_COMMAND_OPTIONS[:q]
			@r = @runner
		end
		def pwd
			puts Dir.pwd
		end
		def runs
			CodeRunner.runner.run_list
		end


			

		
		INTERACTIVE_METHODS = <<EOF


include CodeRunner::InteractiveMethods
setup_interactive
module Kernel

		alias_method(:shell_do, "`".to_sym)
	def `(cmd)
		c =caller
		if c[0] =~ /irb_binding/
			system(cmd)
		else
			shell_do(cmd)
		end
	end
end
EOF

	end # module InteractiveMethods

  	def CodeRunner.interactive_mode(copts={})
		process_command_options(copts)
	  			unless false and FileTest.exist? (ENV['HOME'] + '/code_runner_interactive_options.rb')
				File.open(ENV['HOME'] + '/.code_runner_interactive_options.rb', 'w') do |file|
					file.puts <<EOF
	$has_put_startup_message_for_code_runner = true #please leave!
	$code_runner_interactive_mode = true #please leave!
	require 'yaml'

	def reset
	  Dispatcher.reset_application!
	end
	  
	IRB.conf[:AUTO_INDENT] = true
	IRB.conf[:USE_READLINE] = true
	IRB.conf[:LOAD_MODULES] = []  unless IRB.conf.key?(:LOAD_MODULES)
	unless IRB.conf[:LOAD_MODULES].include?('irb/completion')
	  IRB.conf[:LOAD_MODULES] << 'irb/completion'
	end      

				
	require 'irb/completion'
	require 'irb/ext/save-history'
	require 'socket'
unless ENV['CODE_RUNNER_SYSTEM'] == 'macosx'
	prompt_start = "\001#{Terminal::LIGHT_GREEN}\002CodeRunner\001#{Terminal::RESET}\002 v#{CODE_RUNNER_VERSION} - \001#{Terminal::CYAN}\002#\{ENV['USER']\}@#\{Socket::gethostname\}:#\{File.basename(Dir.pwd)}\001#{Terminal::RESET}\002 timemarker\n"
	prompt_start = "\001#{Terminal::LIGHT_GREEN}\002CodeRunner\001#{Terminal::RESET}\002 v#{CODE_RUNNER_VERSION} - \001#{Terminal::CYAN}\002#\{Socket::gethostname\}:#\{File.basename(Dir.pwd)}\001#{Terminal::RESET}\002 timemarker %02n,%i \n"
else
		prompt_start = "CodeRunner #\{File.basename(Dir.pwd)}"
end
  IRB.conf[:PROMPT][:CODE_RUNNER] = {:PROMPT_I=>"#\{prompt_start}>> %02n,%i >> ", :PROMPT_N=>"#\{prompt_start}>> %02n:%i > ", :PROMPT_S=>"#\{prompt_start}>> %02n:%i (%l)> ", :PROMPT_C=>"#\{prompt_start}>> %02n:%i >>  ", :RETURN=>""}
  IRB.conf[:PROMPT][:CODE_RUNNER] = {:PROMPT_I=>"#\{prompt_start}>> ", :PROMPT_N=>"#\{prompt_start}> ", :PROMPT_S=>"#\{prompt_start}(%l)> ", :PROMPT_C=>"#\{prompt_start}>>  ", :RETURN=>""}
#   IRB.conf[:PROMPT][:CODE_RUNNER] = {:PROMPT_I=>"#\{prompt_start} %02n,%i>> ", :PROMPT_N=>"#\{prompt_start} %02n:%i> ", :PROMPT_S=>"#\{prompt_start} %02n:%i (%l)> ", :PROMPT_C=>"#\{prompt_start} %02n:%i>>  ", :RETURN=>""}


	IRB.conf[:PROMPT_MODE] = :CODE_RUNNER
	IRB.conf[:SAVE_HISTORY] = 400
	IRB.conf[:HISTORY_FILE] = "\#\{Dir.pwd}/.code-runner-irb-save-history"
	IRB.conf[:INSPECT_MODE] = false
	

EOF
				end # File.open
			end # unless
			File.open(".int.tmp.rb", 'w')do |file|
				file.puts "#{copts.inspect}.each do |key, val|
					CodeRunner::DEFAULT_COMMAND_OPTIONS[key] = val
				end"
				file.puts CodeRunner::InteractiveMethods::INTERACTIVE_METHODS
			end
# 			asdfa
			exec %[#{RbConfig::CONFIG['bindir']}/irb#{Config::CONFIG['ruby_install_name'].sub(/ruby/, '')} -f -I '#{Dir.pwd}' -I '#{SCRIPT_FOLDER}'   -I '#{ENV['HOME']}' -r '.code_runner_interactive_options' -r 'coderunner' -r .int.tmp ]
	end
		

end


require "readline"


module IRB
	
	COMMANDS = ENV['PATH'].split(':').inject([]) do |comms,dir|
# 		ep dir
		begin
			dir = dir.sub(/~/, ENV['HOME'])
			Dir.entries(dir).each do |file|
				file = "#{dir}/#{file}"
	# 			ep file
				comms.push(File.basename(file)) if FileTest.executable? file #and File.file? file
			end
		rescue
		end
		comms
	end
	COMMANDS.delete_if{|com| com =~ /^\./}
# 	ep 'COMMANDS', COMMANDS
	
  module InputCompletor
		
		def self.complete_files(receiver, message)
# 			files = message.split(/\s+/)
# 			message = files.pop
			dir = message.sub(/[^\/]*$/, '')
			message = message.sub(Regexp.new("#{Regexp.escape(dir)}"), '')
			dir.sub!(/^~/, ENV['HOME'])
			short_dir = dir
			dir = Dir.pwd + '/' + dir unless dir =~ /^\//
			#$stderr.puts "Dir to scan: #{dir}"

			files = Dir.entries(dir)

			#$stderr.puts "entries", files
		  Dir.chdir(dir){files= files.map{|file| FileTest.directory?(file) ? file + "/" : file}}
			#$stderr.puts "entries - directories", files

		  candidates = message.size > 0 ? files.find_all{|com| com[0...message.size] == message} : files
			return candidates.map{|com| receiver + short_dir + com}
			
			
			old_dir = message.sub(/[^\/]*$/, '')
			dir = old_dir.chomp("/")
			message = message.sub(Regexp.new("#{Regexp.escape(dir)}\\/"), '')
			if dir.size > 0
# 			eputs 'dir', dir
# 				unless old_dir ~= /^\//
					dir = Dir.pwd + '/' + dir
# 				end
# 				eputs 'dir', dir, FileTest.directory?(dir)
				if FileTest.directory? dir
					files = Dir.entries(dir)
				else
					files = []
				end
			else
				dir = Dir.pwd
				files = Dir.entries(dir)
			end
# 			ep files
# 			ep 'mess', message
			Dir.chdir(dir){files= files.map{|file| FileTest.directory?(file) ? file + "/" : file}}
# 			ep dir, files
			candidates = message.size > 0 ? files.find_all{|com| com[0...message.size] == message} : files
			candidates.map{|com| receiver + old_dir + com}
		rescue 
			return []
		end

    @RCS_ID='-$Id: completion.rb 23233 2009-04-19 13:35:47Z yugui $-'

      
    CodeRunnerCompletionProc = proc do |input|
      bind = IRB.conf[:MAIN_CONTEXT].workspace.binding
      Readline.completion_append_character = nil
#     eputs "\n\ninput: #{input}"


      case input
			when Regexp.new("^(#{/\w+\b.*(?:\s|,)(?::p\s+\=\>|p:)\s+\[?\s*/}(?:#{Regexp.quoted_string}\\s*,\\s*)*#{/'\{(?:[^}]*\s)?:?/})(\\w+)$")
				# matches CodeRunner parameter list.... command [stuff] p: '{var: value, var
				receiver = $1
				message = $2
# 				ep 'mess', message
				if CodeRunner.runner and CodeRunner.runner.run_class
					candidates = CodeRunner.runner.run_class.rcp.variables.map{|var| var.to_s}.find_all{|var| var[0...message.size] == message}.map{|var| receiver + var}
				else
					candidates = []
				end
			when /^('(?:(?:\\ |[^'\s])*\s+)*)((?:\\ |[^'\s])*)$/, Regexp.new("^((?:[^']|#{Regexp.quoted_string})*')([^']*)$")
				#filename in a single quoted string
						                      	receiver = "#$1" # "`" #$~[1]
			message = "#$2" #Regexp.quote($~[2]) # $2 #Regexp.quote($2)
# 			ep 'mess', message
			complete_files(receiver, message)
			

				
			when /^(\`\w+\s+(?:\S+\s+)*)([^`\s]*)$/, /^([^`]*`\w+\s+)([^`]*)$/
		#shell command with an executable
		                      	receiver = $1 # "`" #$~[1]
	message = $2 #Regexp.quote($~[2]) # $2 #Regexp.quote($2)
			complete_files(receiver, message)
# 			files = Dir.entries(File.dirname(message))
# 			candidates = message.size > 0 ? files.find_all{|com| com[0...message.size] == message} : files
# 			candidates.map{|com| receiver + com}

			when /^(\`)([^`]*)$/, /^([^`]*`)([^`]*)$/
		#shell command without an excutable
		                      
# 				p $~
		                      	receiver = $1 # "`" #$~[1]
	message = $2 #Regexp.quote($~[2]) # $2 #Regexp.quote($2)
# 	ep "message is", message
# 	ep COMMANDS.grep(//)
	candidates = message.size > 0 ? COMMANDS.find_all{|com| com[0...message.size] == message} : COMMANDS
	candidates.map{|com| receiver + com}
	#.grep(Regexp.new("^#{message}")) #("^#{Regexp.escape(message)}")) #.map{|com| "#{com}"} #.map{|com| receiver + com}
# 	ep candidates
# 	select_message(receiver, message, COMMANDS)

			     when /^([^\/]*\/[^\/]*\/)\.([^.]*)$/
	# Regexp
	receiver = $1
	message = Regexp.quote($2)

	candidates = Regexp.instance_methods.collect{|m| m.to_s}
	select_message(receiver, message, candidates)

      when /^([^\]]*\])\.([^.]*)$/
	# Array
	receiver = $1
	message = Regexp.quote($2)

	candidates = Array.instance_methods.collect{|m| m.to_s}
	select_message(receiver, message, candidates)

      when /([^\}]*\})\.([^.]*)$/
	# Proc or Hash
	receiver = $1
	message = Regexp.quote($2)

	candidates = Proc.instance_methods.collect{|m| m.to_s}
	candidates |= Hash.instance_methods.collect{|m| m.to_s}
	select_message(receiver, message, candidates)
	
		
 		when /^((?:(::)?[A-Z][^:.(]*)+)\.help :(\w*)$/
			# CodeRunner help method
			receiver = $1
			message = Regexp.quote($3)
			begin
					candidates = eval("(#{receiver}.constants - Object.constants).collect{|m| m.to_s}", bind)
					candidates |= eval("(#{receiver}.methods - Object.methods).collect{|m| m.to_s}", bind)
					begin
						candidates |= eval("(#{receiver}.instance_methods - Object.instance_methods).collect{|m| m.to_s}", bind)
					rescue
					end
				rescue Exception
					candidates = []
				end
			candidates.grep(/^#{message}/).collect{|e| receiver + '.help :' + e}

      when /^((?:.*[^:])?:[^:.]*)$/
# 				eputs 'found symbol'
 	# Symbol
	if Symbol.respond_to?(:all_symbols)
	  sym = $1
	  candidates = Symbol.all_symbols.collect{|s| ":" + s.id2name}
	  candidates.grep(/^#{sym}/)
	else
	  []
	end

      when /^(.*\s)?(((::)?[A-Z][^:.(]*)+)(::|\.)([^:.]*)$/
	# Constant or class methods
# 				p "CCC"
	start = $1
	receiver = $2
	message = Regexp.quote($6)
	joiner = "#$5"
	begin
	  candidates = eval("#{receiver}.constants.collect{|m| m.to_s}", bind)
	  candidates |= eval("#{receiver}.methods.collect{|m| m.to_s}", bind)
	rescue Exception
	  candidates = []
	end
	candidates.grep(/^#{message}/).collect{|e| (start or "") + receiver + (joiner or "::") + e}

	
      when /^(.*)(\b[A-Z][^:\.\(]*)$/
	# Absolute Constant or class methods
	receiver = $1
	message = $2
	candidates = Object.constants.collect{|m| m.to_s}
	candidates.grep(/^#{message}/).collect{|e| receiver + e}

	

      when /^(.*-?(0[dbo])?[0-9_]+(\.[0-9_]+)?([eE]-?[0-9]+)?)\.([^.]*)$/
	# Numeric
	receiver = $1
	message = Regexp.quote($5)

	begin
	  candidates = eval(receiver, bind).methods.collect{|m| m.to_s}
	rescue Exception
	  candidates = []
	end
	select_message(receiver, message, candidates)

      when /^(.*-?0x[0-9a-fA-F_]+)\.([^.]*)$/
	# Numeric(0xFFFF)
	receiver = $1
	message = Regexp.quote($2)

	begin
	  candidates = eval(receiver, bind).methods.collect{|m| m.to_s}
	rescue Exception
	  candidates = []
	end
	select_message(receiver, message, candidates)

      when /^(.*[\s\{\[])?(\$[^.]*)$/
	regmessage = Regexp.new(Regexp.quote($1))
	candidates = global_variables.collect{|m| m.to_s}.grep(regmessage)

#      when /^(\$?(\.?[^.]+)+)\.([^.]*)$/
      when /^((\.?[^.]+)+)\.([^.]*)$/
	# variable
	receiver = $1
	message = Regexp.quote($3)

	gv = eval("global_variables", bind).collect{|m| m.to_s}
	lv = eval("local_variables", bind).collect{|m| m.to_s}
	cv = eval("self.class.constants", bind).collect{|m| m.to_s}
	
	if (gv | lv | cv).include?(receiver)
	  # foo.func and foo is local var.
	  candidates = eval("#{receiver}.methods", bind).collect{|m| m.to_s}
	elsif /^[A-Z]/ =~ receiver and /\./ !~ receiver
	  # Foo::Bar.func
	  begin
	    candidates = eval("#{receiver}.methods", bind).collect{|m| m.to_s}
	  rescue Exception
	    candidates = []
	  end
	else
	  # func1.func2
	  candidates = []
	  ObjectSpace.each_object(Module){|m|
	    begin
	      name = m.name
	    rescue Exception
	      name = ""
	    end
	    next if name != "IRB::Context" and 
	      /^(IRB|SLex|RubyLex|RubyToken)/ =~ name
	    candidates.concat m.instance_methods(false).collect{|x| x.to_s}
	  }
	  candidates.sort!
	  candidates.uniq!
	end
	select_message(receiver, message, candidates)

      when /^\.([^.]*)$/
	# unknown(maybe String)

	receiver = ""
	message = Regexp.quote($1)

	candidates = String.instance_methods(true).collect{|m| m.to_s}
	select_message(receiver, message, candidates)

      else
	candidates = eval("methods | private_methods | local_variables | self.class.constants", bind).collect{|m| m.to_s}
			  
	(candidates|ReservedWords).grep(/^#{Regexp.quote(input)}/)

      end
			end

  end
	
	    def self.select_message(receiver, message, candidates)
      candidates.grep(/^#{message}/).collect do |e|
	if receiver =~ /^.*`/
		receiver + e
	else
		case e
		when /^[a-zA-Z_]/
			receiver + "." + e
		when /^[0-9]/
		when *Operators
		
			
			#receiver + " " + e
		end
	end
      end
    end
class InputMethod
end
class ReadlineInputMethod < InputMethod
      include Readline 
			 def gets
        Readline.input = @stdin
        Readline.output = @stdout
				prompt_end = Time.now.to_s[11...16]
				begin
					memsize = `ps ax -o pid,rss | grep -E "^[[:space:]]*#{Process::pid}"`.chomp.split(/\s+/).map {|s| s.strip.to_i}[1].to_i/1000
					prompt_end += " #{memsize}k"
				rescue
				end
				prompt_end +=" (#{CodeRunner::SETUP_RUN_CLASSES.join(",")})"
	if l = readline(@prompt.gsub(/timemarker/, prompt_end) , false)
	  #HISTORY.push(l) if !l.empty? and (HISTORY.size ==0 or l != HISTORY[-1])
	  HISTORY.push(l) if !l.empty? and (HISTORY.size ==0 or l != HISTORY[-1])

		i = 0
		loop do
			break if HISTORY.size == 1
			(HISTORY.delete_at(i); i-=1) if HISTORY[i] == l
			i+=1
			#ep "i: #{i}, HS: #{HISTORY.size}"
			break if i >= HISTORY.size - 1
		end
		#HISTORY.reverse!
		#HISTORY.uniq!
		#HISTORY.reverse!
	  #HISTORY.push(l) if !l.empty? and (HISTORY.size ==0 or !HISTORY.include? l)
	  @line[@line_no += 1] = l + "\n"
	else
	  @eof = true
	  l
	end
      end
end
		
end #module IRB

if Readline.respond_to?("basic_word_break_characters=")
  Readline.basic_word_break_characters= "\t\n><=;|&("
end
Readline.completion_append_character = "BB"
Readline.completion_proc = IRB::InputCompletor::CodeRunnerCompletionProc

begin
if Readline.respond_to?("basic_quote_characters=")
  Readline.basic_quote_characters= "\"'`"
end
rescue NotImplementedError
end

module Kernel

end

require 'rdoc'
require 'rdoc/ri/driver'

class RDoc::RI::Driver
  def run
    if(@list_doc_dirs)
      puts @doc_dirs.join("\n")
    elsif @names.empty? then
      @display.list_known_classes class_cache.keys.sort
    else
	
			@names.each do |name|
        if class_cache.key? name then
          method_map = display_class name
          if(@interactive)
            method_name = @display.get_class_method_choice(method_map)

            if(method_name != nil)
              method = lookup_method "#{name}#{method_name}", name
              display_method method
            end
          end
        elsif name =~ /::|\#|\./ then
          klass, = parse_name name

          orig_klass = klass
          orig_name = name

          loop do
            method = lookup_method name, klass

            break method if method

            ancestor = lookup_ancestor klass, orig_klass

            break unless ancestor

            name = name.sub klass, ancestor
            klass = ancestor
          end
					
# 					return unless method

          raise NotFoundError, orig_name unless method

          display_method method
        else
          methods = select_methods(/#{name}/)

          if methods.size == 0
          return  
						raise NotFoundError, name
          elsif methods.size == 1
            display_method methods[0]
          else
            if(@interactive)
              @display.display_method_list_choice methods
            else
              @display.display_method_list methods
            end
          end
        end
      end
    end
#   rescue NotFoundError => e
#     eputs e
# 		return
  end
	
	 def self.process_args(argv)
    options = default_options

    opts = OptionParser.new do |opt|
      opt.program_name = File.basename $0
      opt.version = RDoc::VERSION
      opt.release = nil
      opt.summary_indent = ' ' * 4

      directories = [
        RDoc::RI::Paths::SYSDIR,
        RDoc::RI::Paths::SITEDIR,
        RDoc::RI::Paths::HOMEDIR
      ]

      if RDoc::RI::Paths::GEMDIRS then
        Gem.path.each do |dir|
          directories << "#{dir}/doc/*/ri"
        end
      end

      opt.banner = <<-EOT
Usage: #{opt.program_name} [options] [names...]

Where name can be:

  Class | Class::method | Class#method | Class.method | method

All class names may be abbreviated to their minimum unambiguous form. If a name
is ambiguous, all valid options will be listed.

The form '.' method matches either class or instance methods, while #method
matches only instance and ::method matches only class methods.

For example:

    #{opt.program_name} Fil
    #{opt.program_name} File
    #{opt.program_name} File.new
    #{opt.program_name} zip

Note that shell quoting may be required for method names containing
punctuation:

    #{opt.program_name} 'Array.[]'
    #{opt.program_name} compact\\!

By default ri searches for documentation in the following directories:

    #{directories.join "\n    "}

Specifying the --system, --site, --home, --gems or --doc-dir options will
limit ri to searching only the specified directories.

Options may also be set in the 'RI' environment variable.
      EOT

      opt.separator nil
      opt.separator "Options:"
      opt.separator nil

      opt.on("--fmt=FORMAT", "--format=FORMAT", "-f",
             RDoc::RI::Formatter::FORMATTERS.keys,
             "Format to use when displaying output:",
             "   #{RDoc::RI::Formatter.list}",
             "Use 'bs' (backspace) with most pager",
             "programs. To use ANSI, either disable the",
             "pager or tell the pager to allow control",
             "characters.") do |value|
        options[:formatter] = RDoc::RI::Formatter.for value
      end

      opt.separator nil

      opt.on("--doc-dir=DIRNAME", "-d", Array,
             "List of directories from which to source",
             "documentation in addition to the standard",
             "directories.  May be repeated.") do |value|
        value.each do |dir|
          unless File.directory? dir then
            raise OptionParser::InvalidArgument, "#{dir} is not a directory"
          end

          options[:extra_doc_dirs] << File.expand_path(dir)
        end
      end

      opt.separator nil

      opt.on("--[no-]use-cache",
             "Whether or not to use ri's cache.",
             "True by default.") do |value|
        options[:use_cache] = value
      end

      opt.separator nil

      opt.on("--no-standard-docs",
             "Do not include documentation from",
             "the Ruby standard library, site_lib,",
             "installed gems, or ~/.rdoc.",
             "Equivalent to specifying",
             "the options --no-system, --no-site, --no-gems,",
             "and --no-home") do
        options[:use_system] = false
        options[:use_site] = false
        options[:use_gems] = false
        options[:use_home] = false
      end

      opt.separator nil

      opt.on("--[no-]system",
             "Include documentation from Ruby's standard",
             "library.  Defaults to true.") do |value|
        options[:use_system] = value
      end

      opt.separator nil

      opt.on("--[no-]site",
             "Include documentation from libraries",
             "installed in site_lib.",
             "Defaults to true.") do |value|
        options[:use_site] = value
      end

      opt.separator nil

      opt.on("--[no-]gems",
             "Include documentation from RubyGems.",
             "Defaults to true.") do |value|
        options[:use_gems] = value
      end

      opt.separator nil

      opt.on("--[no-]home",
             "Include documentation stored in ~/.rdoc.",
             "Defaults to true.") do |value|
        options[:use_home] = value
      end

      opt.separator nil

      opt.on("--list-doc-dirs",
             "List the directories from which ri will",
             "source documentation on stdout and exit.") do
        options[:list_doc_dirs] = true
      end

      opt.separator nil

      opt.on("--no-pager", "-T",
             "Send output directly to stdout,",
             "rather than to a pager.") do
        options[:use_stdout] = true
      end

      opt.on("--interactive", "-i",
             "This makes ri go into interactive mode.",
             "When ri is in interactive mode it will",
             "allow the user to disambiguate lists of",
             "methods in case multiple methods match",
             "against a method search string.  It also",
             "will allow the user to enter in a method",
             "name (with auto-completion, if readline",
             "is supported) when viewing a class.") do
        options[:interactive] = true
      end

      opt.separator nil

      opt.on("--width=WIDTH", "-w", OptionParser::DecimalInteger,
             "Set the width of the output.") do |value|
        options[:width] = value
      end
    end

    argv = ENV['RI'].to_s.split.concat argv

    opts.parse! argv

    options[:names] = argv

    options[:formatter] ||= RDoc::RI::Formatter.for('plain')
    options[:use_stdout] ||= !$stdout.tty?
    options[:use_stdout] ||= options[:interactive]
    options[:width] ||= 72

    options

  rescue OptionParser::InvalidArgument, OptionParser::InvalidOption => e
    puts opts
    puts
    puts e
#     exit 1
  end

end


	class Object
# 		def help
# 			CodeRunner.ri(self.to_s)
# 		end
		def self.help(meth_or_const=nil)
			join = ""
			if meth_or_const
				if self.constants.include? meth_or_const.to_sym
					join = "::"
				elsif self.methods.include? meth_or_const.to_sym
					join = "."
				elsif self.instance_methods.include? meth_or_const.to_sym
					join = "#"
				end
			end
			CodeRunner.reference("#{self.to_s}#{join}#{meth_or_const}")
		end
	end
	
	class Module

		def help(meth_or_const=nil)
			join = ""
			if meth_or_const
				if self.constants.include? meth_or_const.to_sym
					join = "::"
				elsif self.methods.include? meth_or_const.to_sym
					join = "."
				elsif self.instance_methods.include? meth_or_const.to_sym
					join = "#"
				end
			end
			CodeRunner.reference("#{self.to_s}#{join}#{meth_or_const}")
		end
	end
