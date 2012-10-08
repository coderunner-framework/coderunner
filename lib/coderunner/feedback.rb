class Feedback

def gets #No reading from the command line thank you very much!
	$stdin.gets
end
def self.gets
	$stdin.gets
end

def Feedback.get_custom(question, regexp)
	#NB regex is submitted  as a string
	puts question
	cont = true
	while cont
		puts "---Please enter an answer of the form " + regexp
		answer = gets.to_s
		if answer =~ Regexp.new(regexp)
			cont = false
		else
			puts "Incorrect form"
		end
	end
	return answer.chomp
end

def Feedback.get_boolean(question)
	puts question
	cont = true
	while cont
		puts "---Please enter y or n"
		answer = gets
		if answer =~ /^n$/i
			cont = false
			bool = false
		elsif answer =~ /^y$/i
			cont = false
			bool = true
		else
			puts "Incorrect selection: #{answer.inspect}"
		end
	end
	return bool
end

def Feedback.get_float(question)
	puts question
	cont = true
	while cont
		puts "---Please enter an answer of the form ^-?\\d[.e-\\d]*$"
		answer = gets
		if answer =~ /^-?\d[\d\.e-]*$/
			cont = false
		else
			puts "Incorrect selection: #{answer.inspect}"
		end
	end
	return answer.to_f
end

def Feedback.get_choice(question, choice)
	case choice
		when Hash
			puts question
			cont = true
			old_choice = choice; choice = {}
			old_choice.each do |key,value|
					choice[key.to_s] = old_choice[key]
			end
			while cont
				puts "Please select your choice (case sensitive)"
				choice.each do |key,value|
					puts key.to_s + ":  " + value.to_s

				end

				answer = gets.chomp
				if choice[answer]
					cont = false
					answer = choice[answer]
				else	
					puts "Incorrect Selection: #{answer.inspect} - Please try again"
				end
			end
		when Array
			hash = {}
			choice.each_with_index{|choice,i| hash[i] = choice}
			answer = self.get_choice(question, hash)
	end
	return answer
end	

end