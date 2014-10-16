class CodeRunner
	
	def merge(*others)
		Merged.new(*others.unshift(self))
	end
	
	def merge_method(meth, *args)
		send(meth, *args)
	end

  # This class allows the analysis of multiple root folders as if they were
  # one. For every normal runner (instance of CodeRunner) that is added to the merged runner
  # (instance of CodeRunner::Merged), the runs of that normal runner are added to the merged
  # run_list. Normal runner function such as CodeRunner#graphkit() can then be called.
  #
  # In order to keep the run_list unique, the runs from each component runner are not added
  # to the merged runner directly: instead they are wrapped in a container of class Run::Merged
  # which behaves like a standard run object except that it redefines the id to be [runner_index, id].
  # Thus, within the merged runner, the id of run 43 from the third runner to be added to the merged
  # runner is [2,43].
  #
	class Merged < CodeRunner
    # Iterates over the runners contained within the merged runner.
    # E.g.
    #   merged_runner.each{|runner| p runner.root_folder}
    attr_reader :runners
		def each
			@runners.each{|r| yield(r)}
		end
    # Iterate over each of the merged runners, updating them.
    def update(*args)
      each{|r| r.update(*args)}
    end
		include Enumerable
    # Create a new merged runner. <tt>runners</tt> is an array of standard runners
    # (i.e. instances of CodeRunner).
		def initialize(*runners)
			@runners = []
			r = runners[0]
			r.instance_variables.each do |v| 
				instance_variable_set(v, r.instance_variable_get(v))
			end
			@run_list = {}
			runners.each{|runner| add_runner(runner)}
		end
    # Raises an error. At the present time, submitting 
    # from a merged runner has no defined behaviour and 
    # is not implemented.
    def submit(*args)
      raise "Submitting from a merged runner is currently not supported"
    end
    # A string prepended to each line of the status output for merged
    # runners... see CodeRunner#print_out
    def merged_runner_info(run)
      #run.id.inspect + " : "
      run.id[0].to_s + ","
      #""
    end
    # Do nothing
    def save_large_cache
    end
    # Merge an additional runner. 
		def add_runner(runner)
      index = @runners.size
			@runners.push runner
			runner.run_list.each do |id, run|
				#raise "Duplicate ids: #{id}" if @run_list[id]
        merged_run = Run::Merged.new(index, run)
				@run_list[merged_run.id] = merged_run 
			end
			@ids = @run_list.keys
		end
    # Call a method on each runner and combine the results according to 
    # the block.
    # E.g.
    #   string_of_root_folders = merged_runner.merge_method(:root_folder){|string, folder| string << "," << folder}
		def merge_method(meth, *args, &block)
			results = @runners.map{|r| r.send(meth, *args)}
			return results.inject{|o,n| yield(o,n)}
		end

		
	end
  # This is a container for run objects for use in a merged runner.
  # Basically its job is to route all methods to the run it contains,
  # except for the id method, which is redefined.
  #
  # Instead of being a number, the id of the run is now an array of two 
  # numbers, of which the second is the id of the run contained, but the
  # first is the index of the runner which the run corresponds to.
  #
  # Thus, within a merged runner (an instance of CodeRunner::Merged), each 
  # run has a unique id, and the merged runner can treat the Run::Merged objects
  # exactly as if they were simply Run objects.
  class Run::Merged
    #(Object.instance_methods - [:send,:set,:object_id, :__send__, :__id__]).each{|meth| undef_method meth}
    undef_method :test
    attr_reader :run
    attr_accessor :id
    def initialize(runner_index, run)
      @runner_index = runner_index
      @run = run
      @id = [@runner_index, @run.id]
    end
    #def send(meth, *args)
      #@run.send(meth, *args)
    #end
    def method_missing(meth, *args)
      @run.send(meth, *args)
    end
  end
end
