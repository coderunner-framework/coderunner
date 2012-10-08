class CodeRunner

      # System module for Juropa and HPC-FF

	module Juropa

def queue_status
	if prefix = ENV['CODE_RUNNER_LAUNCHER']
		%x[cat #{ENV['HOME']}/.coderunner_to_launch_#{prefix}/queue_status.txt]  +
		%x[cat #{ENV['HOME']}/.coderunner_to_launch_#{prefix}/queue_status2.txt] 
	else
		%x[qstat | grep $USER]
	end
end

def run_command
# 	"msub #{batch_script_file}"
	if ENV['CODE_RUNNER_LAUNCHER']
		return %[mpiexec -np #{@nprocs} #{executable_location}/#{executable_name} #{parameter_string} > #{output_file} 2> #{error_file}]
	else
		"mpiexec -np $NSLOTS #{executable_location}/#{executable_name} #{parameter_string}"
	end
end

def execute
	
	if ((prefix = ENV['CODE_RUNNER_LAUNCHER']).size > 0 rescue false)
    launch_id = "#{Time.now.to_i}#{$$}"
    fname = ENV['HOME'] + "/.coderunner_to_launch_#{prefix}/#{launch_id}"
    File.open(fname + '.start', 'w'){|file| file.puts "cd #{Dir.pwd};#{run_command}"}
    sleep 1 until FileTest.exist? fname + '.pid'
    pid = File.read(fname + '.pid').to_i
    FileUtils.rm fname + '.pid'
		return pid
  else
		File.open(batch_script_file, 'w'){|file| file.puts batch_script + run_command + "\n"}
		jn = %x[msub #{batch_script_file}].scan(/(\d+)\s*\Z/).flatten
		if jn[0]
			 return jn[0].to_i
		 else
			 return nil
		 end
	end
end

def batch_script_file
	"#{executable_name}_#{job_identifier}.sh"
end

def batch_script
	nodes, ppn = @nprocs.split(/x/)
	ppn ||= 8
	if @wall_mins
		ep @wall_mins
		hours = (@wall_mins / 60).floor
		mins = @wall_mins.to_i % 60
		secs = ((@wall_mins - @wall_mins.to_i) * 60).to_i
	end
	eputs "Allotted wall time is " + sprintf("%02d:%02d:%02d", hours, mins, secs)
<<EOF
#!/bin/bash -x 
#MSUB -l nodes=#{nodes}:ppn=#{ppn} 
#MSUB -N #{executable_name}.#{job_identifier}
#{@wall_mins ? "#MSUB -l walltime=#{sprintf("%02d:%02d:%02d", hours, mins, secs)}" : ""}

### start of jobscript 
cd $PBS_O_WORKDIR 
echo "workdir: $PBS_O_WORKDIR" 
NSLOTS=#{nodes.to_i * ppn.to_i} 
echo "running on $NSLOTS cpus ..." 

EOF

#MSUB -e #{Dir.pwd}/#{error_file} 
#      if keyword omitted : default is submitting directory  
#MSUB -o #{Dir.pwd}/#{output_file}
#       if keyword omitted : default is submitting directory 
end

def cancel_job
	if ((prefix = ENV['CODE_RUNNER_LAUNCHER']).size > 0 rescue false)
   	 fname = ENV['HOME'] + "/.coderunner_to_launch_#{prefix}/#{$$}.stop"
		 File.open(fname, 'w'){|file| file.puts "\n"}
	else
		`canceljob #{@job_no}`
	end
end

def error_file
	#For backwards compatibility
	return "#{executable_name}.sh.e" if kind_of? CodeRunner::Run and [:Completed, :Failed].include? @status
	return "#{executable_name}.#{job_identifier}.e#@job_no"
end

def output_file
	return "#{executable_name}.sh.o" if kind_of? CodeRunner::Run and [:Completed, :Failed].include? @status
	return "#{executable_name}.#{job_identifier}.o#@job_no"
end

def get_run_status(job_no, current_status)
	if ENV['CODE_RUNNER_LAUNCHER']
		return :Unknown
	end
	line = current_status.split(/\n/).grep(Regexp.new(job_no.to_s))[0]
	unless line
		return :Unknown
	else 
		if line =~ /\sQ\s/
			return :Queueing
		elsif line =~ /\sR\s/
			return :Running
		elsif line =~ /\sC\s/
			return :Unknown
		else
			ep 'line', line
			raise 'Could not get run status'
		end
	end
end
	

	end
end
