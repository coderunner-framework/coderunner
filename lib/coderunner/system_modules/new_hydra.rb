class CodeRunner
	module NewHydra

def queue_status
	%x[qstat | grep $LOGNAME]
end

def run_command
	if @runner.debug
		return %[mpisubshort "40mins" #{@nprocs} #{executable_location}/#{executable_name} #{parameter_string}  ]
	else 
		return %[mpisubnoquotes "0.5-10 hrs" #{@nprocs} #{executable_location}/#{executable_name} #{parameter_string}]
	end
end

def execute
	system run_command
end

def cancel_job
	`qdel #{@job_no}`
end

def error_file
	return "#{executable_name}.sh.e#{@job_no}"
end

def output_file
	return "#{executable_name}.sh.o#{@job_no}"
end

	end
end
