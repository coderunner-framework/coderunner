class CodeRunner
	class Cubecalc
		class Sleep < Cubecalc

@variables = [:calculate_sides, :width, :height, :depth, :sleep_time]

def parameter_string
	return sprintf("%d %s %d", @calculate_sides, 'edges.txt', @sleep_time)
end

		end
	end
end

