class CodeRunner
	
	def merge(*others)
		Merged.new(*others.unshift(self))
	end
	
	def merge_method(meth, *args)
		send(meth, *args)
	end

	class Merged < CodeRunner
		def each
			@runners.each{|r| yield(r)}
		end
		include Enumerable
		def initialize(*runners)
			@runners = []
			r = runners[0]
			r.instance_variables.each do |v| 
				instance_variable_set(v, r.instance_variable_get(v))
			end
			@run_list = {}
			runners.each{|runner| add_runner(runner)}
		end
		def add_runner(runner)
			@runners.push runner
			runner.run_list.each do |id, run|
				#raise "Duplicate ids: #{id}" if @run_list[id]
				@run_list[id] = run
			end
			@ids = @run_list.keys
		end
		def merge_method(meth, *args, &block)
			results = @runners.map{|r| r.send(meth, *args)}
			return results.inject{|o,n| yield(o,n)}
		end

		
	end
end
