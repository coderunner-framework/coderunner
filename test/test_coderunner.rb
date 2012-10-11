require 'coderunner'
require 'test/unit'

module Test::Unit::Assertions
	def assert_system(string)
		assert(system(string), "System Command: '#{string}'")
	end
end

`g++ cubecalc.cc -o cubecalc`


ppipe = PPipe.new(10, false, redirect: true)

raise "Please Specify Tests" unless ARGV[-1] 

# CodeRunner::SYS = (ENV['CODE_RUNNER_SYSTEM'] or 'genericlinux')

if ARGV[-1] =~ /0/
	if FileTest.exist? 'results'
		FileUtils.rm_r 'results'
	end
	FileUtils.makedirs 'results'

	Dir.chdir('results') do
		
		puts 'testing test submission'	
		exit unless system %[coderunner submit -C cubecalc -m sleep -D sleep -X ../cubecalc -T]
		raise "didn't find defaults" unless FileTest.exist? 'sleep_defaults.rb'
		puts 'testing test submission complete'
		
		puts 'testing job_no detection'
		puts fork{system %[coderunner sub -p "{sleep_time: 4}"]}
		sleep 2
		#exit unless system %[ps | grep cubecalc]
		Process.waitall
		puts 'testing job_no detection complete'
		
	 		#exit

		
		puts 'testing canceling a job (not deleting)'
		fork{system %[ruby ../../coderunner.rb sub -p "{sleep_time: 900}"]}
		sleep 3
		fork{system %[ruby ../../coderunner.rb sub -p "{sleep_time: 900, height: 3.0}"]}
		sleep 4
		runner = CodeRunner.new(Dir.pwd).update	
		runner.print_out(0)
		runner.print_out_size = 0
		runner.cancel_job(2, no_confirm: true, delete: false)
		#pipe = ppipe.fork do
			#runner.cancel_job(2)
		#end
	 	##3.times{puts ppipe.gets}
		#2.times{ppipe.puts(pipe, "")}
		#puts 'confirming...'
	## 	sleep 0.5
	 	##2.times{puts ppipe.gets}
		#puts 'about to say no'
		#ppipe.puts(pipe, "n")
	## 	9.times{puts ppipe.gets}
		
	 	#exit
		
		puts 'testing cancelling with deleting'
		
		runner.update
		runner.print_out(0)
		runner.print_out_size = 0
		runner.cancel_job(3, no_confirm: true, delete: true)
		#pipe = ppipe.fork do
				#runner.cancel_job(3)
		#end
	## 	2.times{puts ppipe.gets}
		#puts 'confirming...'
		#ppipe.puts(pipe, "")
	## 	ppipe.puts(pipe, "\n")
	## 	sleep 0.5
	## 	2.times{puts ppipe.gets}
		#puts 'about to say yes'
		#ppipe.puts(pipe, "y")
	## 	8.times{puts ppipe.gets}

		puts 'testing canceling complete'
		
	 	#exit

	# exit
		
		puts
			puts 'testing parameter scan'
		File.open('parameter_scan.rb', 'w') do |file|
			file.puts [
				[
					['width', [0.3, 0.5]], ['height', [0.5, 4.3]]
				],
				[
					['width', [7.2]], ['height', [3.6, 12.6]]
				]
			].inspect
		end
		exit unless system %[ruby ../../coderunner.rb ps parameter_scan.rb]
	# # 	exit unless system %[ruby ../../coderunner.rb -UN -O "width height"]
		runner.update
		runner.print_out(0)
		

		
	# exit
	# 	
	end

end # if ARGV[0] == 's'

# exit
	


if ARGV[-1] =~ /1/
FileUtils.rm_r 'results' if FileTest.exist? 'results'
FileUtils.makedirs 'results'

# CodeRunner::SYS = ENV['CODE_RUNNER_SYSTEM'] = 'genericlinux_testsystem' if CodeRunner::SYS == 'genericlinux'

Dir.chdir('results') do


		exit unless system %[ruby ../../coderunner.rb submit -C cubecalc -m empty -X ../cubecalc -T]
	
	defs = File.read('cubecalc_defaults.rb')
	File.open('cubecalc_defaults.rb', 'w'){|f| f.puts defs.sub(/(sides\s+=\s+)0/, '\11')}
	
	puts 'testing submission with -p flag'	

	exit unless system %[ruby ../../coderunner.rb submit -p "{width: 3.0,  height: 8.0}"]
	raise "didn't find defaults" unless FileTest.exist? 'cubecalc_defaults.rb'
	puts 'testing submission with -p flag complete'	
# 	exit
	
	puts 'testing printing out status'
	exit unless system %[ruby ../../coderunner.rb status -N]
	puts 'that should have raised a TerminalError from print_out'
	ENV['ROWS'] = Terminal.terminal_size[0].to_s 
	ENV['COLS'] = Terminal.terminal_size[1].to_s
	puts ENV['ROWS'], ENV['COLS']
 	exit unless system %[ruby ../../coderunner.rb st -N]
	runner = CodeRunner.new(Dir.pwd).update
	runner.print_out(0)
	puts 'testing printing out status complete' 

	puts 'testing using large cache'
	%x[ruby ../../coderunner.rb sub -p "{width: 3.0, height: 6.0}"]
	%x[ruby ../../coderunner.rb sub -p "{width: 3.0, height: 9.0}"]
	puts "using large cache without updating"
	runner.use_large_cache = true
	runner.update.print_out(0)
	puts 'using large cache after updating'
	runner.update
	runner.use_large_cache = true
	runner.update.print_out(0)
	puts 'testing using large cache complete'
	
	puts 'testing sorting'
	%x[ruby ../../coderunner.rb sub -p "{width: 12.0, height: 9.0}"]
	%x[ruby ../../coderunner.rb sub -p "{width: 5.0, height: 6.0}"]
	puts '----', 'unsorted'
 	exit unless system %[ruby ../../coderunner.rb st -N]
	puts '----', 'sort by volume'
 	exit unless system %[ruby ../../coderunner.rb st -O "volume" -N]
	puts '----','sort by width then by height'
 	exit unless system %[ruby ../../coderunner.rb st -O "width;height" -N]
	puts 'testing sorting complete'
	
	puts 'testing getting directory'
	exit unless system %[ruby ../../coderunner.rb dir 3 -UN ]
	puts 'testing getting directory complete'
	
	puts 'testing filtering'
	puts '----', 'height == 9.0'
 	exit unless system %[ruby ../../coderunner.rb st -UNf "height == 9.0"]
	puts '----', 'id == 1 or width == 12.0'
	exit unless system %[ruby ../../coderunner.rb st -UNf 'id == 1 or width == 12.0']
	puts 'testing filtering complete'

# 	exit
		
	puts 'testing phantom runs'
 	exit unless system %[ruby ../../coderunner.rb st -UN -h -O "volume;area"]
	puts 'testing using both'
 	exit unless system %[ruby ../../coderunner.rb st -UN -h both -O "volume;id"]
	puts 'testing phantom runs complete'
	
	puts 'testing readout'
 	exit unless system %[ruby ../../coderunner.rb ro -UN -O "width;height"]
	puts 'testing readout complete'
	
	puts 'testing run eval'
	exit unless system %[ruby ../../coderunner.rb rc "puts %[hello I am run \#\@run_name]" -U -f "id ==1" ]
	puts  'testing run eval complete'
	
	puts 'testing graph plotting'
	exit unless system %[ruby ../../coderunner.rb sub -p "{width: 11.0, height: 9.0, depth: 2.0}"]

# 	IO.popen(%[ruby ../../coderunner.rb -U -g "width*height*depth:volume"]) do |pipe|
# 		sleep 1
# 		pipe.puts
# 	end
	exit unless system %[ruby ../../coderunner.rb wg graph.ps -O volume -G "width*height*depth:volume"]
	exit unless system %[ruby ../../coderunner.rb wg graph1.ps -U -O volume -G "width:height:depth:volume;;;height"]
	exit unless system %[ruby ../../coderunner.rb wg "" -U -f "id==1 or id == 2" -g "sides"]
	puts 'testing graph plotting complete'
	
	puts 'testing max'
	exit unless system %[ruby ../../coderunner.rb st -U -f "max(:volume)"]
	exit unless system %[ruby ../../coderunner.rb st -U -f "width == 3.0 and smax(:volume, :height)"]
	puts 'testing max complete'
	
	
	

	


# 	
# # 	puts 'testing interactive mode'	
# # 	IO.popen(%[ruby ../../coderunner.rb -i]) do |pipe|
# #  		pipe.puts 'cr'
# # 		pipe.puts 'exit'
# #  	end
# # 	puts 'testing interactive mode'	

end #  Dir.chdir

end # if 

p ARGV[-1] =~ /2/

if ARGV[-1] =~ /2/

	FileUtils.rm_r 'results' if FileTest.exist? 'results'
	FileUtils.makedirs 'results'
	
	CodeRunner.submit(Y: Dir.pwd + '/results', C: 'cubecalc', m: 'empty', X: '../cubecalc', T: true)
# 	exit
	defs = File.read('results/cubecalc_defaults.rb')
	File.open('results/cubecalc_defaults.rb', 'w'){|f| f.puts defs.sub(/\#(@calculate_sides\s+=\s+)0/, '\11')}
	CodeRunner.submit(Y: Dir.pwd + '/results', p: "{width: 3.0,  height: 8.0}")
	CodeRunner.submit(Y: Dir.pwd + '/results', p: "{width: 3.0, height: 6.0}")
	CodeRunner.submit(Y: Dir.pwd + '/results', p: "{width: 3.0,  height: 9.0}")
	CodeRunner.submit(Y: Dir.pwd + '/results', p: "{width: 12.0,  height: 9.0}")
	CodeRunner.submit(Y: Dir.pwd + '/results', p: "{width: 5.0,  height: 6.0}")
	CodeRunner.submit(Y: Dir.pwd + '/results', p: "{width: 11.0, height: 9.0, depth: 2.0}")

	class TestCodeRunner < Test::Unit::TestCase
		
		# Override this method as we want the tests to be run in the order they are defined
		
		def self.test_methods
					public_instance_methods(true).grep(/^test/).map { |m| m.to_s}
		end
		
		def setup
			@runner = CodeRunner.fetch_runner(Y: Dir.pwd + '/results').update		
		end
		
		def teardown
		end
		
		def cl(command)
			Dir.chdir('results'){assert_system command}
		end

		def cl2(command)
			Dir.chdir('results3'){assert_system command}
		end

		
		def cl3(command)
			Dir.chdir('results3'){assert_system command}
		end

		
		#def test_remote_coderunner
			#puts 'testing remote coderunner'
			#rc = RemoteCodeRunner.new(ENV['USER'] + '@localhost', Dir.pwd + '/results', U: true, N: true).update
			#assert_equal(@runner.ids.sort, rc.ids.sort)
			#rc.print_out(0)
			#wdvh = rc.graphkit("width:height:depth:volume;;;height")
			#wdvh.gnuplot
			#assert_equal(4, wdvh.naxes)
			#assert_equal(1, wdvh.data.size)
			#assert_equal([30.0, 18.0, 24.0, 108.0, 27.0, 198.0], wdvh.data[0].axes[:f].data)
			#sds = rc.run_graphkit('sides;;[1,2].include? id')
	## 		sds.gnuplot
			#wdvh.close
			#puts 'testing remote coderunner complete'
		#end
		
		#def test_run_eval_saving
			#puts "\nTesting run command saving"
			#cl(%[ruby ../../coderunner.rb rc '@test_var = :will_o_the_wisp' -U])
			#@runner.update(false, true)
			#assert_equal(:will_o_the_wisp, @runner.run_list[1].instance_variable_get(:@test_var))
			#cl(%[ruby ../../coderunner.rb rc '@test_var2 = :will_o_the_wisps' -U -M 3])
			
			#@runner.update(false, true)
			#assert_equal(:will_o_the_wisps, @runner.run_list[1].instance_variable_get(:@test_var2))
			#puts 'finished testing run command saving'
		#end
		
		#def test_relative_directory
			#puts "\nTesting relative directory"
			#@runner.recalc_all = true
			#puts 'updating fully'
			#@runner.update #(true, false)
			#FileUtils.rm_r('results2') if FileTest.exist? 'results2'
			#FileUtils.cp_r('results', 'results2')
			#r = CodeRunner.fetch_runner(Y: 'results2', U: true)
			#r.update(false)
			#assert_equal(Dir.pwd + '/results', @runner.root_folder)
			#assert_equal(Dir.pwd + '/results2', r.root_folder)
			#assert_equal(@runner.run_list[1].directory.sub(File.expand_path(@runner.root_folder) + '/', ''), r.run_list[1].relative_directory)
			#assert_equal(r.root_folder + '/' + r.run_list[1].relative_directory, r.run_list[1].directory)
		#end
		
		#def test_set_start_id
			#eputs "\ntesting set_start_id"
			#FileUtils.rm_r 'results3' if FileTest.exist?('results3')
			#FileUtils.mkdir('results3')
			#cl3('ruby ../../coderunner.rb st -C cubecalc -m empty -X ../cubecalc -T')
			#cl3("ruby ../../coderunner.rb ev 'set_start_id(20)'")
			#cl3('ruby ../../coderunner.rb sub -p "{width: 12.0, height: 9.0}"')
			#@runner3 = CodeRunner.new(Dir.pwd + '/results3').update
			#assert_equal(20, @runner3.start_id)
			#assert_equal(21, @runner3.max_id)
			#eputs "\ntesting set_start_id complete"
		#end

		#def test_merged_code_runner
			#@runner3 = CodeRunner.new(Dir.pwd + '/results3').update
			#assert_nothing_raised{@mrunner = CodeRunner::Merged.new(@runner, @runner3)}
			#@mrunner.print_out(0)
			#assert_equal(@runner.run_list.size + 1, @mrunner.run_list.size)
			#@mrunner2 = @runner.merge(@runner3)
			#assert_equal(@mrunner2.run_list.keys, @mrunner.run_list.keys)
		#end
		
		#def test_alter_ids
			#FileUtils.rm_r('results4') if FileTest.exist? 'results4'
			#FileUtils.cp_r('results', 'results4')
			#@runner4 = CodeRunner.new(Dir.pwd + '/results4').update
			#@runner4.alter_ids(40, no_confirm: true)
			#@runner4a = CodeRunner.new(Dir.pwd + '/results4').update
			#assert_equal(@runner.ids.map{|id| id + 40}.sort, @runner4.ids.sort)
			#assert_equal(@runner4a.ids.sort, @runner4.ids.sort)
			#@runner4.alter_ids(40, no_confirm: true)
			#@runner4a.update
			#assert_equal(@runner.ids.map{|id| id + 80}.sort, @runner4.ids.sort)
			#assert_equal(@runner4a.ids.sort, @runner4.ids.sort)
			#run = @runner4.run_list.values[0]
			#assert(FileTest.exist?(run.directory), "Run directory exists")
			#assert_equal(run.id, eval(File.read(run.directory + '/code_runner_info.rb'))[:id])
		#end
		
		#def test_submit_non_parallel_with_large_cache
			#FileUtils.touch('results/submitting')
	## 		fork{cl('ruby ../../coderunner.rb sub -p "{width: 1.887, height: 9.0}"')}
			#fork{CodeRunner.submit(Y: 'results', p: "{width: 1.887, height: 9.0}", U: true)}
			#sleep 1.0
			#@runner.update(true, false)
			#assert_equal(0, @runner.run_list.values.find_all{|run| run.width==1.887}.size)
			#FileUtils.rm('results/submitting')
			#i = 0
			#Process.waitall
	## 		(@runner.update(true, true); sleep 0.5; i+=1 ; flunk if i==20) until @runner.run_list.values.find{|run| run.width==1.887}
			#@runner.update(true, true)
			#assert_equal(1, @runner.run_list.values.find_all{|run| run.width==1.887}.size)
			#@runner.conditions = "id==7"
			#@runner.destroy(no_confirm: true)
			#assert_equal(0, @runner.run_list.values.find_all{|run| run.width==1.887}.size)
			#assert_raise(RuntimeError){CodeRunner.submit(Y: 'results', p: "{run_test_flags: {test_submit_error_handling: true}}", U: true)}
			#assert(!FileTest.exist?('results/submitting'))
		#end
		
		def test_latex_graphkit
			sds = @runner.run_graphkit('sides;;[1,2].include? id')
 			p sds
			sds.ylabel = 'Hello'
			sds.data.each_with_index{|dk,i| dk.title = i.to_s}
			sds.xlabel = '\(\Gamma_{\epsilon}\)'
			sds.title = 'Area of the Sides'
			#pid1 = sds.gnuplot

			sds.gnuplot_write('latgraph.eps', latex: true)
			#pid = forkex "okular latgraph.eps"
			sleep 3
			#Process.kill 'TERM', pid
			#Process.kill 'TERM', pid1
		end
		
		def test_graphkit_multiplot
			
			######################
			# Make 3 random graphs
			######################
			
			
			# As usual, data can be an array or a GSL::Vector
			kit1 = GraphKit.autocreate(x: {data: [0,2,4], title: 'A label with latex \(\Gamma_\epsilon \chi\)', units: '\(\nu e\)'}, y: {data: [3.3, 5.5, 10], title: 'Label with latex \(\beta\)', units: '\(v_{thi}\)'})
			kit1.title = 'First Graph'
			kit1.gp.label = '\'A label\' at 2,7' # This 'gp' syntax is new. You can set pretty much any gnuplot option like this - see gnuplot help set
			kit1.data[0].title = 'A new title'
			
			kit2 = GraphKit.autocreate(x: {data: [0,2,4], title: 'Stuff \(\Gamma_\epsilon \chi\)', units: '\(\nu e\)'}, y: {data: [2, -1, 2], title: 'Some \(\beta\)', units: '\(v_{thi}\)'})
			kit2.title = 'Second Graph'
			kit2.data[0].gp.with = 'lp linewidth 6' # See gnuplot help plot for data options
			kit2.gp.key = 'off'
			kit2.xlabel = 'A NEW XLABEL'
			
			kit3 = GraphKit.autocreate(x: {data: [0,5,10], title: 'Mouse Height \(\Gamma_\epsilon \chi\)', units: '\(\nu e\)'}, y: {data: [4, 3, 4], title: 'Mouse weight \(\kappa\)', units: '\(v_{thi}\)'})
			kit3.title = 'Mouse info'
			kit3.data[0].gp.with = 'lp'
			kit3.gp.key = 'off'
			
			#####################
			# Plot a single one
			#####################
			
			kit1.gnuplot_write('first_graph.eps', latex: true) #Just plot it by itself
			
			###########################
			# Plot multiple graphs
			##########################

			kit1.gnuplot_write('aname.eps', latex: true)
			kit2.gnuplot_write('anothername.eps', latex: true)
			kit3.gnuplot_write('athirdname.eps', latex: true, size: "2.0in,2.0in")
			
			my_preamble = <<EOF
	\\documentclass{article}
	%\documentclass[aip,reprint]{}
	\\usepackage{graphics,bm,overpic,subfigure,color}

	\\pagestyle{empty}
	\\begin{document}
	\\begin{figure}
EOF
			
			
			# Can use default preamble - just don't include preamble option in function call GraphKit.latex_multiplot('all_graphs.eps')
			GraphKit.latex_multiplot('all_graphs.eps', preamble: my_preamble) do 
<<EOF
	\\subfigure{
	\\includegraphics{aname}
	}
	\\subfigure{
	\\begin{overpic}{anothername}
				% The location is in percent of image width
	\\put(44,22){\\includegraphics[scale=.45]
				{athirdname}}
	\\end{overpic}
	} 
EOF
			end

			
			
		end # def 
			
	end # class TestCodeRunner

end
