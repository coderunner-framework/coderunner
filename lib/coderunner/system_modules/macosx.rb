class CodeRunner
	module Macosx
# @@ruby_command = "ruby1.9"

def queue_status
	%x[ps].grep(Regexp.new(Regexp.escape(executable_name))) #Can't put grep in the shell command because it will grep itself - OS X displays the entire command in ps!
end

def run_command
	if rcp.uses_mpi
		return %[mpirun -np #{@nprocs} #{executable_location}/#{executable_name} #{parameter_string} > #{output_file} 2> #{error_file}]
	else
		return %[#{executable_location}/#{executable_name} #{parameter_string} > #{output_file} 2> #{error_file}]
	end
end		

def execute
	log 'execute_submission'
  if ENV['CODE_RUNNER_LAUNCHER']
    launch_id = "#{Time.now.to_i}#{$$}"
    fname = ENV['HOME'] + "/.coderunner_to_launch/#{launch_id}"
    File.open(fname + '.start', 'w'){|file| file.puts "cd #{Dir.pwd};#{run_command}"}
    sleep 1 until FileTest.exist? fname + '.pid'
    pid = File.read(fname + '.pid').to_i
    FileUtils.rm fname + '.pid'
  else
    pid = Kernel.spawn(run_command + " & ")
  end
  
	return nil # pid
end


def cancel_job
	`kill #{@job_no}`
end

def error_file
	return executable_name + ".sh.e"
end

def output_file
	return executable_name + ".sh.o"
end

	end
end



