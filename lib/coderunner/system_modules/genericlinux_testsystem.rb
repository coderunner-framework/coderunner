class CodeRunner
	module GenericlinuxTestsystem

@@ruby_command = "ruby1.9"

def queue_status
# 	if @@no_run
# 		return ""
# 	else
		return %x[ps] #%x[top -b -n 1 -u #{Process.uid} | grep #{@@executable_name}]
# 	end
	# top runs very slowly. If you have a system (for example your laptop) where you will never run simulations, only analyse them, replace this command with %x[ps] and code runner will run much faster.
end

def run_command
	if @@uses_mpi
		return %[mpirun -np #{@nprocs} #{executable_location}/#{executable_name} #{parameter_string}]
	else
		return %[#{executable_location}/#{executable_name} #{parameter_string}]
	end
end		

def execute
	log 'execute_submission'
	fork{exec run_command}
	sleep 0.2
end

def cancel_job
	`kill #{@job_no}`
end

def error_file
	return nil
end

def output_file
	return nil
end

	end
end