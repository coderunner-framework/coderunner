###########################
# Graph and Film Methods
##########################

#

class CodeRunner

	# Parse graphkit shorthand for a general graph and return it as [axes, options]. GraphKit shorthand is:
	# 	'<axis1>[ : <axis2> [ : <axis3 [ : <axis4> ] ] ] [ ; <graph_options> [ ; <conditions> [ ; <sort> ] ] ]'
	# i.e. all commands for the graph in one string
	
	def graphkit_shorthand(*gr)
		return gr if gr.size > 1
		gr = gr[0] 
		return gr if gr.class == Array
		axes, options, cons, srt = gr.split(/;/)
		axes = eval("['#{axes.split(/(?<!\\|:):(?!:)/).map{|s| s.gsub(/\\:/, ':')}.join("','")}']")
		options = (options and options =~ /\S/) ? eval(options): {}
# 		p srt
		cons = nil unless cons and cons=~ /\S/
		srt = nil unless srt and srt=~ /\S/

		options[:conditions] ||= cons
		options[:sort] ||= srt
		return [axes, options]
	end

	def sweep_graphkits(sweeps, options, &block)
		server = @server; @server = false
		intial_conditions = @conditions
		initial_sort = @sort
		@conditions = (options[:conditions] or @conditions)
		@sort = (options[:sort] or @sort)

		sweeps = sweeps.class == Array ? sweeps : [sweeps]
		generate_combined_ids
# 		ep sweeps
		sweep_values = filtered_ids.inject([]) do |arr, id|
			arr.push(sweeps.inject([]) do |sweep_arr, var|
				
				sweep_arr.push @combined_run_list[id].send(var)
# 				  ep sweep_arr, var
				sweep_arr
			end)
			arr.uniq
		end
		old_conditions = @conditions
		new_options = options.dup
		new_options.delete(:sweep) if new_options[:sweep]
# 			p new_options; gets
		kits = sweep_values.sort.map do |values|
			new_cons = (sweeps.zip(values).map do |name, value|
				"#{name}==#{value}"
			end).join(" and ")
			new_options[:conditions] = old_conditions ? old_conditions + " and #{new_cons}" : new_cons
# 				ep new_options[:conditions]
			kit = yield(new_options)
			
				
			kit.data[0].gp.title = new_cons.gsub(/==/, '=')
# 				p kit
			kit
		end
# 		@conditions = old_conditions
		@conditions = intial_conditions 
		@sort = initial_sort 
		if options[:sweep_multid]
			kitdata = kits.map do |kit| 
				kit.data[0].axes.values.map{|axiskit| axiskit.data}
			end
			final_axes = (kitdata[0].size  + sweeps.size - 1).times.inject([]){|arr, i| arr.push []}
			data_hash = {}
			sweep_values.sort.each_with_index do |vals, i| 
# 				ep 'v', vals
				data = kitdata[i]
				length = data[0].size
				vals.each_with_index do |val, j|
					final_axes[j].push val
# 					final_axes[j].uniq!
				end
				function = data.pop
				for j in 0...length
					
					data.each_with_index do |axisdata, k|
# 						ep 'vk', vals.size + k
# 						break if k == data.size - 1
						final_axes[vals.size + k].push axisdata[j]
						final_axes[vals.size + k].uniq!
					end
# 					ep 'h', final_axes, function
					data_hash[vals + data.map{|axisdata| axisdata[j]}] = function[j]
				end
			end
			final_axes.map!{|vals| vals.uniq.sort}
			final_data = SparseTensor.new(final_axes.size)
			data_hash.each do |coordinates, function|
				indices = []
				coordinates.each_with_index do |val, i| 
					indices[i] = final_axes[i].index(val)
				end
				final_data[*indices] = function
			end
			hash = {}
			
# 			pp final_axes, final_data
			
			titles = sweeps + kits[0].data[0].axes.values.map{|axiskit| axiskit[:title]}
			(final_axes + [final_data]).each_with_index do |d, i|
				hash[GraphKit::AXES[i]] = {data: d, title: titles[i].to_s}
			end
			kit = GraphKit.autocreate(hash)
			
						
						
# 				length = data[i].size
# 				array = vals.map{|val| [val] * length} + data
# 				p array
# 			end
# 			final_data = [[]] * (kitdata[0].size  + sweeps.size)
# 			sweep_values.sort.each_with_index do |vals, i|
# 				data = kitdata[0]
# 				length = data[0].size
# 				array = vals.map{|val| [val] * length} + data
# 				p array
# 			end
		else
			kit =  kits.inject{|ans, kit| ans + kit} 
		end
				
		
		#Kernel.puts server_dump(kit) if server 

		return kit
	
	end
	
	def sweep_graphkits(sweeps, options, &block)
		server = @server; @server = false
		intial_conditions = @conditions
		initial_sort = @sort
		@conditions = (options[:conditions] or @conditions)
		@sort = (options[:sort] or @sort)

		sweeps = sweeps.class == Array ? sweeps : [sweeps]
		generate_combined_ids
# 		ep sweeps
		sweep_values = filtered_ids.inject([]) do |arr, id|
			arr.push(sweeps.inject([]) do |sweep_arr, sweep|
				
				sweep_arr.push @combined_run_list[id].instance_eval(sweep.to_s)
# 				  ep sweep_arr, var
				sweep_arr
			end)
			arr.uniq
		end
		old_conditions = @conditions
		new_options = options.dup
		new_options.delete(:sweep) if new_options[:sweep]
# 			p new_options; gets
		kits = sweep_values.sort.map do |values|
			new_cons = (sweeps.zip(values).map do |name, value|
				"#{name}==#{value.inspect}"
			end).join(" and ")
			new_options[:conditions] = old_conditions ? old_conditions + " and #{new_cons}" : new_cons
# 				ep new_options[:conditions]
			kit = yield(new_options)
			
				
			kit.data[0].gp.title = new_cons.gsub(/==/, '=')
# 				p kit
			kit
		end
# 		@conditions = old_conditions
		@conditions = intial_conditions 
		@sort = initial_sort 
		if options[:sweep_multid]
			kitdata = kits.map do |kit| 
				kit.data[0].axes.values.map{|axiskit| axiskit.data}
			end
			final_axes = (kitdata[0].size  + sweeps.size - 1).times.inject([]){|arr, i| arr.push []}
			data_hash = {}
			sweep_values.sort.each_with_index do |vals, i| 
# 				ep 'v', vals
				data = kitdata[i]
				length = data[0].size
				vals.each_with_index do |val, j|
					final_axes[j].push val
# 					final_axes[j].uniq!
				end
				function = data.pop
				for j in 0...length
					
					data.each_with_index do |axisdata, k|
# 						ep 'vk', vals.size + k
# 						break if k == data.size - 1
						final_axes[vals.size + k].push axisdata[j]
						final_axes[vals.size + k].uniq!
					end
# 					ep 'h', final_axes, function
					data_hash[vals + data.map{|axisdata| axisdata[j]}] = function[j]
				end
			end
			final_axes.map!{|vals| vals.nuniq.sort}
# 			ep final_axes
			final_data = SparseTensor.new(final_axes.size)
			data_hash.each do |coordinates, function|
				indices = []
# 				p coordinates
				coordinates.each_with_index do |val, i| 
					indices[i] = final_axes[i].index(val)
				end
				final_data[*indices] = function
			end
			hash = {}
			
# 			pp final_axes, final_data
			
			titles = sweeps + kits[0].data[0].axes.values.map{|axiskit| axiskit[:title]}
			(final_axes + [final_data]).each_with_index do |d, i|
				hash[GraphKit::AXES[i]] = {data: d, title: titles[i].to_s}
			end
			kit = GraphKit.autocreate(hash)
			
						
						
# 				length = data[i].size
# 				array = vals.map{|val| [val] * length} + data
# 				p array
# 			end
# 			final_data = [[]] * (kitdata[0].size  + sweeps.size)
# 			sweep_values.sort.each_with_index do |vals, i|
# 				data = kitdata[0]
# 				length = data[0].size
# 				array = vals.map{|val| [val] * length} + data
# 				p array
# 			end
		else
			kit =  kits.inject{|ans, kit| ans + kit} 
		end
				
		
		#Kernel.puts server_dump(kit) if server 
		return kit
	
	end
		
	# call-seq: graphkit(axes, options)
	# Make a general graphkit, i.e. a graph that combines output from lots of runs. The axes should be an array of strings, each string defining what should be plotted on each axis. Each string is actually a fragment of Ruby code which will be evaluated by each run for whom option[:conditions] or @conditions evaulates to true. The most important other option is options[:sweep]. This is a string or an array of strings, each of which will be evaluated by each run; the data will then be grouped for the values of these strings.
	# E.g. 
	# 	graphkit(['a', 'b'], {sweep: ["c"], conditions: 'd==1'}
	# 	
	
	def graphkit(*args)
		logf(:graphkit)
		if args.size == 1
			axes, options = graphkit_shorthand(args[0])
		elsif args.size == 2
			axes, options = args
		else
			raise ArgumentError
		end
# 		p axes
# 		return named_graphkit(axes, options) if axes.class == String or axes.class == Symbol
#  		ep @sort
		(return sweep_graphkits(options[:sweep], options) do |new_options|
			graphkit(axes, new_options)
		end) if options [:sweep]
		
		intial_conditions = @conditions
		initial_sort = @sort
		@conditions = (options[:conditions] or @conditions)
		@sort = (options[:sort] or @sort)

		sort_runs

		case axes.size
		when 1
			kit = GraphKit.autocreate({x: axiskit(axes[0])})
			kit.data[0].gp.with = "linespoints"
		when 2
			kit = GraphKit.autocreate({x: axiskit(axes[0]), y: axiskit(axes[1])})
			kit.data[0].gp.with = "linespoints"
				
		when 3
			kit = GraphKit.autocreate({x: axiskit(axes[0]), y: axiskit(axes[1]), z: axiskit(axes[2])})
			kit.data[0].gp.with = "linespoints"

		when 4
			kit = GraphKit.autocreate({x: axiskit(axes[0]), y: axiskit(axes[1]), z: axiskit(axes[2]), f: axiskit(axes[3])})
			kit.data[0].gp.with = "linespoints palette"
		else
			raise CRError.new("Bad graph string")
		end

		kit.title += %| for #{@conditions.gsub(/==/, "=").gsub(/\&\&/, " and ").gsub(/\|\|/, " or ").gsub(/\A(.{,40}).*\s/m, '\1')}| if @conditions
		kit.file_name = kit.title.gsub(/=/, ' eq ').gsub(/\&\&/, " and ").gsub(/\|\|/, " or ").gsub(/ /, "_").gsub(/\//, "over").gsub(/\*/, '.')
		kit.modify(options)
		
		
# 		p kit
		kit.data[0].gp.title = "#@code:#{kit.data[0].title}" 
		#Kernel.puts server_dump(kit) if @server 
		return kit




	end
	
# 	def gnuplot(axes, options)
# 		a = graphkit(axes, options).gnuplot
# 	end
	
	def axiskit(string)
		generate_combined_ids
		data = filtered_ids.inject([]) do |arr, id|
			begin
				arr.push @combined_run_list[id].instance_eval(string)
			rescue => err
				eputs "Evaluation of #{string} failed for run #{id}"
				raise err
			end
		end
# 		p data
		return GraphKit::AxisKit.new(title: string, data: data)
	end
				                                	
	def run_graphkit_shorthand(*grs)
# 		p grs
		return grs if grs.size > 1
		gr = grs[0] 
# 		p gr
		return gr if gr.class == Array
		name, options, cons, srt = gr.split(/;/)
		options = (options and options =~ /\S/) ? eval(options): {}
		cons = nil unless cons and cons=~ /\S/
		srt = nil unless srt and srt=~ /\S/
		options[:conditions] ||= cons if cons
		options[:sort] ||= srt if srt
		[name, options]
	end


	def run_graphkit(*args)
		if args.size == 1
			name, options = run_graphkit_shorthand(args[0])
		elsif args.size == 2
			name, options = args
		else
			raise ArgumentError
		end
		
		(return sweep_graphkits(options[:sweep], options) do |new_options|
			run_graphkit(name, new_options)
		end) if options [:sweep]
		
		old_sort, old_conditions = @sort, @conditions
		@sort = options[:sort] if options[:sort]
		@conditions = options[:conditions] if options[:conditions]		
		generate_combined_ids
		fids = filtered_ids
		raise CRError.new("No ids match these conditions: #@conditions") unless fids.size > 0
		kit = (fids.map do |id| 
			run = @combined_run_list[id]; 
# 			p run; STDIN.gets
			kit = run.graphkit(name, options.dup); 
			kit.data[0].title ||= run.run_name; 
			kit
		end).inject{|kit, k| kit+k}
		@sort, @conditions = old_sort, old_conditions
		#Kernel.puts server_dump(kit) if @server
		kit
	end
	
	def graphkit_from_lists(graphs, run_graphs, extra_options = {})
		run_kits = run_graphs.map do |gr|
			name, options = run_graphkit_shorthand(gr)
			options += extra_options
			run_graphkit(name, options.dup)
		 end
		 kits = graphs.map do |gr|
			axes, options = graphkit_shorthand(gr)
			options += extra_options			
			graphkit(axes, options.dup)
		 end
 
		(run_kits + kits).inject{|kit, k| kit+k}
	end
	def graphkit_from_lists_with_frame_array(frame_array, graphs, run_graphs, extra_options = {})
		server = @server; @server = false
# 		ep "Frame array to calculate is", frame_array, "\n\n"
		i=0
		array = frame_array.map do |frame_index|
# 			if print_message
				eputs "\033[2A" # Terminal jargon - go back one line
				eputs sprintf("Fetching graphs: %2.2f", i.to_f/frame_array.size.to_f * 100.0) + "% Complete"
# 			end
			i+=1
			[frame_index, graphkit_from_lists(graphs, run_graphs, extra_options.absorb({(extra_options[:in]||extra_options[:index_name]||:frame_index) => frame_index}))]
		end
# 		eputs Marshal.load(Marshal.dump(array)).pretty_inspect
		#Kernel.puts server_dump(array) if server
		return array
	end

	
	def film_graphkit(axes, options, film_options = {})
# 		self.class.make_film_multiple_runners([[self,[[[axes, options]],[]]]], film_options)
		film_from_lists([[axes, options]], [], film_options)
	end
	
	def film_run_graphkit(name, options, film_options = {})
# 		self.class.make_film_multiple_runners([[self,[[],[[name, options]]]]], film_options)
 		film_from_lists([], [[name, options]], film_options)
	end
	
	def make_film_from_lists(graphs, run_graphs, film_options = {})
		self.class.make_film_multiple_runners([[self,[graphs, run_graphs]]], film_options)
	end
	
	# list is an array of [[runner, [graphs, run_graphs]], ... ]
	
	def self.graphkit_multiple_runners(list, options={})
		return list.inject(nil) do |kit, (runner, graph_lists)|
			graphs, run_graphs = graph_lists
			graphs.map!{|graph| runner.graphkit_shorthand(graph)}
			run_graphs.map!{|graph| runner.run_graphkit_shorthand(graph)}
			newkit = runner.graphkit_from_lists(graphs, run_graphs, options)
			kit ? kit + newkit : newkit
		end
	end
	
	def self.graphkit_multiple_runners_with_frame_array(frame_array, list, extra_options, print_message = false)
		i = 0
# 		
		return list.inject(nil) do |kit_array, (runner, graph_lists)|
			graphs, run_graphs = graph_lists
			graphs.map!{|graph| runner.graphkit_shorthand(graph)}
			run_graphs.map!{|graph| runner.run_graphkit_shorthand(graph)}
			newkit_array = runner.graphkit_from_lists_with_frame_array(frame_array, graphs, run_graphs, extra_options)
# 			eputs newkit_array.pretty_inspect
			kit_array ? (i=-1; kit.map{|(frame_index, kit)| i+= 1;[frame_index, new_kit[i][1]]}) : newkit_array
		end
	end
	
	def self.make_film_multiple_runners_old(list, options)
		possible_options = [:frame_array, :fa, :skip_frames, :sf, :normalize, :n, :normalize_pieces, :np, :increment, :i, :skip_encoding, :se, :index_name, :in]
		fa = (options[:frame_array] or options[:fa] or list[0][0].run_list[list[0][0].filtered_ids[0]].frame_array(options)	)
		iname = options[:in]||options[:index_name]||:frame_index

		fd = frame_digits = Math.log10(fa[1]).ceil
		unless options[:skip_frames] or options[:sf]
		`rm -rf film_frames`
		extension = (options[:extension] or options[:ext] or '.png')
		extension = '.' + extension unless extension =~ /^\./

		FileUtils.makedirs('film_frames')
# 		puts @@multiple_processes; gets
		no_forks = (@@multiple_processes or 1)
		ep @@multiple_processes, no_forks
		end_graphkit = graphkit_multiple_runners(list, iname => fa[1])
		begin_graphkit = graphkit_multiple_runners(list, iname => fa[0])

		end_area = end_graphkit.plot_area_size
		begin_area = begin_graphkit.plot_area_size
# 		p end_area, begin_area, options
		plot_size = {}
		axes = [:x, :y, :z]
		options[:normalize] ||= options[:nm]  
		options[:normalize_pieces] ||= options[:nmp]
		for i in 0...end_area.size
			next unless options[:normalize] and options[:normalize].include? axes[i]
			min = [end_area[i][0], begin_area[i][0]].min
			max = [end_area[i][1], begin_area[i][1]].max
			key =  axes[i]
			plot_size[key + :range] = [min, max]
		end
		ep plot_size
# 		exit
		frames = []
		actual_frames = {}
		i = fa[0]
		j = 0
		while i <= fa[1]
			frames.push i
			actual_frames[i] = j
			i += (options[:ic] or options[:increment] or 1)
			j += 1
		end
		frames.pieces(no_forks).each_with_index do |piece, myrank|
			fork do
				if options[:normalize_pieces]
				end_area = graphkit_multiple_runners(list, iname => piece.max).plot_area_size
				begin_area = graphkit_multiple_runners(list, iname => piece.min).plot_area_size
				axes = [:x, :y, :z]
				for i in 0...end_area.size
					next unless options[:normalize_pieces].include? axes[i]
					min = [end_area[i][0], begin_area[i][0]].min
					max = [end_area[i][1], begin_area[i][1]].max
					key =  axes[i]

					plot_size[key + :range] = [min, max]
				end
				end
				eputs 'making graphs...'; sleep 1
				graph_array = graphkit_multiple_runners_with_frame_array(piece, list, {:in => iname}, myrank==0)
# 				ep graph_array
				eputs
				graph_array.each_with_index do |(frame_index,g), pindex|
					if myrank == 0
						eputs "\033[2A" # Terminal jargon - go back one line
						eputs sprintf("Plotting graphs: %2.2f", pindex.to_f/piece.size.to_f * 100.0) + "% Complete"
					end
# 					g = graph_kit_multiple_runners(list, plot_size + {frame_index: frame_index})
					
					g.modify(plot_size)
					g.modify(options)
# 					p g; exit
				        g.title +=  sprintf(", frame %0#{fd}d", frame_index) unless options[:frame_title] == false
					folder = ("film_frames/"); 
					file_name = sprintf("frame_%0#{fd}d", actual_frames[frame_index])
# 					g.gnuplot; gets; g.close
# 					ep folder + file_name + '.png'; gets
					g.gnuplot_write(folder + file_name + extension)
				end
			end
		end
		eputs "Waiting on subprocesses..."
		Process.waitall
		end
		unless options[:skip_encoding]
		eputs "making film"
		frame_rate = (options[:frame_rate] or options[:fr] || 15)
		film_name = (options[:film_name] or options [:fn] or end_graphkit.file_name + '_film').gsub(/\s/, '_')
		puts `ffmpeg -y #{options[:bitrate] ? "-b #{options[:bitrate]}" : ""} -r #{frame_rate} -threads #{(@multiple_processes or 1)} -i film_frames/frame_%0#{fd}d#{extension} -qscale 0 #{film_name}.mp4`
		end
	end
	
# end

# __END__
	
	def self.make_film_multiple_runners(list, options)
		possible_options = [:frame_array, :fa, :skip_frames, :sf, :normalize, :n, :normalize_pieces, :np, :increment, :i, :skip_encoding, :se]
		fa = (options[:frame_array] or options[:fa] or list[0][0].run_list[list[0][0].filtered_ids[0]].frame_array(options)	)
		iname = options[:in]||options[:index_name]||:frame_index

		fd = frame_digits = Math.log10(fa[1]).ceil
		unless options[:skip_frames] or options[:sf]
# 		`rm -rf film_frames`
# 		extension = (options[:extension] or options[:ext] or '.png')
# 		extension = '.' + extension unless extension =~ /^\./

# 		FileUtils.makedirs('film_frames')
# 		puts @@multiple_processes; gets
		no_forks = (@@multiple_processes or 1)
		ep @@multiple_processes, no_forks
		end_graphkit = graphkit_multiple_runners(list, iname => fa[1])
		begin_graphkit = graphkit_multiple_runners(list, iname => fa[0])

		end_area = end_graphkit.plot_area_size
		begin_area = begin_graphkit.plot_area_size
# 		p end_area, begin_area, options
		plot_size = {}
		axes = [:x, :y, :z]
		options[:normalize] ||= options[:nm]  
		options[:normalize_pieces] ||= options[:nmp]
		for i in 0...end_area.size
			next unless options[:normalize] and options[:normalize].include? axes[i]
			min = [end_area[i][0], begin_area[i][0]].min
			max = [end_area[i][1], begin_area[i][1]].max
			key =  axes[i]
			plot_size[key + :range] = [min, max]
		end
		ep plot_size
# 		exit
		frames = []
		actual_frames = {}
		i = fa[0]
		j = 0
		while i <= fa[1]
			frames.push i
			actual_frames[i] = j
			i += (options[:ic] or options[:increment] or 1)
			j += 1
		end
# 		graphkit_frame_array = []
		
		myrank = -1
# 		graphkit_frame_array = (frames.pieces(no_forks).parallel_map(n_procs: no_forks, with_rank: true) do |piece, myrank|
		graphkit_frame_array = (frames.pieces(no_forks).map do |piece|
		                        myrank +=1
# 		                        ep 'myrank is', myrank
# 				unless myrank==0
# # 					$stdout = $stderr = StringIO.new
# 				end
# 			fork do
				if options[:normalize_pieces]
				end_area = graphkit_multiple_runners(list, iname => piece.max).plot_area_size
				begin_area = graphkit_multiple_runners(list, iname => piece.min).plot_area_size
				axes = [:x, :y, :z]
				for i in 0...end_area.size
					next unless options[:normalize_pieces].include? axes[i]
					min = [end_area[i][0], begin_area[i][0]].min
					max = [end_area[i][1], begin_area[i][1]].max
					key =  axes[i]

					plot_size[key + :range] = [min, max]
				end
				end
				eputs 'making graphs...'; sleep 1 if myrank==0
				graph_array = graphkit_multiple_runners_with_frame_array(piece, list, {:in => iname}, myrank==0)
# 				ep graph_array
				eputs
				graph_array.each_with_index do |(frame_index,g), pindex|
# 					if myrank == 0
# 						eputs "\033[2A" # Terminal jargon - go back one line
# 						eputs sprintf("Plotting graphs: %2.2f", pindex.to_f/piece.size.to_f * 100.0) + "% Complete"
# 					end
# 					g = graph_kit_multiple_runners(list, plot_size + {frame_index: frame_index})
					
					g.modify(plot_size)
					g.modify(options)
					g.instance_eval options[:graphkit_modify] if options[:graphkit_modify]
# 					p g; exit
				        g.title +=  sprintf(", frame %0#{fd}d", frame_index) unless options[:frame_title] == false
# 					folder = ("film_frames/"); 
# 					file_name = sprintf("frame_%0#{fd}d", actual_frames[frame_index])
# 					g.gnuplot; gets; g.close
# 					ep folder + file_name + '.png'; gets
# 					g.gnuplot_write(folder + file_name + extension)
				end
			 graph_array
# 			end
		end).sum
# 		eputs "Waiting on subprocesses..."
# 		Process.waitall
		end
		
		film_graphkit_frame_array(graphkit_frame_array, options)
# 		unless options[:skip_encoding]
# 		eputs "making film"
# 		frame_rate = (options[:frame_rate] or options[:fr] || 15)
# 		film_name = (options[:film_name] or options [:fn] or end_graphkit.file_name + '_film').gsub(/\s/, '_')
# 		puts `ffmpeg -y #{options[:bitrate] ? "-b #{options[:bitrate]}" : ""} -r #{frame_rate} -threads #{(@multiple_processes or 1)} -i film_frames/frame_%0#{fd}d#{extension} -sameq #{film_name}.mp4`
# 		end
	end
	
	def self.film_graphkit_frame_array(graphkit_frame_array, options)
		possible_options = [:frame_array, :fa, :skip_frames, :sf, :normalize, :n, :normalize_pieces, :np, :increment, :i, :skip_encoding, :se, :frame_rate, :fr, :size]
# 		fa = (options[:frame_array] or options[:fa] or list[0][0].run_list[list[0][0].filtered_ids[0]].frame_array(options)	)

		fd = frame_digits = options[:fd]||Math.log10(graphkit_frame_array.map{|f, g| f}.max).ceil
		extension = (options[:extension] or options[:ext] or '.png')
		extension = '.' + extension unless extension =~ /^\./
		unless options[:skip_frames] or options[:sf]
		FileUtils.rm_r('film_frames') if FileTest.exist?('film_frames')

		FileUtils.makedirs('film_frames')
# 		puts @@multiple_processes; gets
		no_forks = (@@multiple_processes or 1)
		ep @@multiple_processes, no_forks
# 		end_graphkit = graphkit_multiple_runners(list, frame_index: fa[1])
# 		begin_graphkit = graphkit_multiple_runners(list, frame_index: fa[0])

# 		end_area = end_graphkit.plot_area_size
# 		begin_area = begin_graphkit.plot_area_size
# 		p end_area, begin_area, options
# 		plot_size = {}
# 		axes = [:x, :y, :z]
# 		options[:normalize] ||= options[:nm]  
# 		options[:normalize_pieces] ||= options[:nmp]
# 		for i in 0...end_area.size
# 			next unless options[:normalize] and options[:normalize].include? axes[i]
# 			min = [end_area[i][0], begin_area[i][0]].min
# 			max = [end_area[i][1], begin_area[i][1]].max
# 			key =  axes[i]
# 			plot_size[key + :range] = [min, max]
# 		end
# 		ep plot_size
# 		exit
# 		frames = []
# 		actual_frames = {}
# 		i = fa[0]
# 		j = 0
# 		while i <= fa[1]
# 			frames.push i
# 			actual_frames[i] = j
# 			i += (options[:ic] or options[:increment] or 1)
# 			j += 1
# 		end
		i = 0
		actual_frames = graphkit_frame_array.map{|f, g| f}.inject({}){|hash, f| hash[f] = i; i+=1; hash}
		graphkit_frame_array.pieces(no_forks).each_with_index do |graphkit_frame_array_piece, myrank|
			fork do
# 				if options[:normalize_pieces]
# 				end_area = graphkit_multiple_runners(list, frame_index: piece.max).plot_area_size
# 				begin_area = graphkit_multiple_runners(list, frame_index: piece.min).plot_area_size
# 				axes = [:x, :y, :z]
# 				for i in 0...end_area.size
# 					next unless options[:normalize_pieces].include? axes[i]
# 					min = [end_area[i][0], begin_area[i][0]].min
# 					max = [end_area[i][1], begin_area[i][1]].max
# 					key =  axes[i]
# 
# 					plot_size[key + :range] = [min, max]
# 				end
# 				end
# 				eputs 'making graphs...'; sleep 1
# 				graph_array = graphkit_multiple_runners_with_frame_array(piece, list, myrank==0)
# # 				ep graph_array
# 				eputs
				graphkit_frame_array_piece.each_with_index do |(frame_index,g), pindex|
					if myrank == 0
						eputs "\033[2A" # Terminal jargon - go back one line
						eputs sprintf("Plotting graphs: %2.2f", pindex.to_f/graphkit_frame_array_piece.size.to_f * 100.0) + "% Complete"
					end
# 					g = graph_kit_multiple_runners(list, plot_size + {frame_index: frame_index})
					
# 					g.modify(plot_size)
# 					g.modify(options)
# 					p g; exit
# 				        g.title +=  sprintf(", frame %0#{fd}d", frame_index) unless options[:frame_title] == false
					folder = ("film_frames/"); 
					file_name = sprintf("frame_%0#{fd}d", actual_frames[frame_index])
# 					g.gnuplot; gets; g.close
# 					ep folder + file_name + '.png'; gets
					g.gnuplot_write(folder + file_name + extension, size: options[:size])
				end
			end
		end
		eputs "Waiting on subprocesses..."
		Process.waitall
		end
		unless options[:skip_encoding]
		eputs "making film"
		frame_rate = (options[:frame_rate] or options[:fr] || 15)
		film_name = (options[:film_name] or options [:fn] or graphkit_frame_array[0][1].file_name + '_film').gsub(/\s/, '_')
		puts `ffmpeg -y #{options[:bitrate] ? "-b #{options[:bitrate]}" : ""} -r #{frame_rate} -threads #{(@multiple_processes or 1)} -i film_frames/frame_%0#{fd}d#{extension} -qscale 0 #{film_name}.mp4`
		end
	end


end

