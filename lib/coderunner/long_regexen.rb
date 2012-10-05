# $script_folder = File.dirname(File.expand_path(__FILE__))
require File.dirname(File.expand_path(__FILE__)) + "/box_of_tricks.rb"

module LongRegexen 

FLOAT = /(?<float>\-?(?:(?>\d+\.\d*)|(?>\d*\.\d+))(?:[eE][+-]?\d+)?)/

FLOAT_WSP = /(?<float>\-?\s*(?:(?>\d+\.\d*)|(?>\d*\.\d+))(?:[eE][+-]?\d+)?)/ # allows a space between the minus sign and the number


INT = INTEGER = /(?<int>\-?\d++)/

NUMBER = Regexp.new("(?<number>#{FLOAT.verbatim}|#{INTEGER.verbatim})")

STRING = /(?:"(?<string>(?:[^"]|\\")*)")|(?:'(?<string>(?:[^']|\\")*)')/

EQUALITY = /\b	#a word boundary
	
	(?<name>[A-Za-z_]\w*)  # the name, which must be a single word (not beginning 
					# with a digit) followed by

	\s*=\s*    # an equals sign (possibly with whitespace either side), then

	(?<default>(?>    # the default answer, which can be either:

		(?<float>\-?(?:(?>\d+\.\d*)|(?>\d*\.\d+))(?:[eE][+-]?\d+)?) # a floating point number
		
		|						#or

		(?<int>\-?\d++)	# an integer

		|						#or

		(?:(?<delim>["'])(?<string>.*?)\k<delim>) # a string in quotes: '' or ""

		|						# or

		(?:(?<word>\S+)(?=\s|\)|\]|[\n\r]+)) # a single word containing no spaces 
						# which must be followed by a space or ) or ] or a new line

	))/x

KEYVALUE = /<key>		#  <key> then
	
	(?<name>[A-Za-z_]\w*)  # the name, which must be a single word (not beginning 
					# with a digit) followed by

	<\/key>\s*    # <\/key> (possibly with following whitespace), then

	<value>  	# <value>, then

	(?<default>    # the default answer, which can be either:


		(?<float>\-?(?:(?>\d+\.\d*)|(?>\d*\.\d+))(?:[eE]\-?\d+)?) # a floating point number 
		
		|						#or

		(?<int>\-?\d+)		# an integer

		|						#or

		(?<string>[^<]*) 	# a string (containing no '<'s)
	
	)

	<value>  	# <\/value>

	/x

TAG = /<			# < 

	[^\/\S>]+		#  some word (containing no '\/'s or '>'s)

	\s+ 		#some whitespace

	name=
	
	(?<delim>["'])  # a double or single quote
	
	(?<name>[A-Za-z_]\w*) # the name, which must be a single word (not beginning 
					# with a digit) followed by
	
	\k<delim> 	#a closing quote  

	\s+ 		#some whitespace

	(?<delimnext>["'])  # a double or single quote

	(?<default>    # the default answer, which can be either:


		(?<float>\-?(?:(?>\d+\.\d*)|(?>\d*\.\d+))(?:[eE]\-?\d+)?) # a floating point number 
		
		|						#or

		(?<int>\-?\d+)	# an integer

		|						#or

		(?<string>[^"']*) # a string (containing no quotation marks)

	)

	\k<delimnext> 	#a closing quote  

	\s* 		#some whitespace

	>		# >

	/x

		#<comp> : only complete sets of delimiters [], "", '', \/\/ or complete method calls: meth(params) or no delimiters at all: ensures that any following expressions are not inside open square brackets, quotation marks or regexen, or inside method parameter lists 
NAMRSQBQS = NOT_IN_A_METHOD_OR_IN_A_REGEXP_OR_IN_SQUARE_BRACKETS_OR_IN_QUOTES_OR_A_SYMBOL = 
	
	    /(?<comp> 
		(?:   #a set of three options 
		    (?:  #option 1: complete sets of delimiters 
			(?<nest> #sub-expression denoting nested delimiters
			    (?:   #  A: meth(stuff)
				(?:[A-Za-z_]\d*?) #method name ending in numbers or a letter
				\(  #begin brackets
				    (?:
					[^()\[\]"\/'] #no delimiters
					|
					\g<nest> #complete nested sub-expression
				    )*
				\)
			    )
			    |
			    (?:   #  B: [stuff]
				\[  #begin square brackets
				    (?:
					[^()\[\]"\/'] #no delimiters
					|
					\g<nest> #complete nested sub-expression
				    )*
				\] 
			    )
			    |
			    (?:   #  C: \/stuff\/  or "stuff" or 'stuff'
				(?<delim>[\/"'])  #begin symmetrical delimiters
				    (?:
					[^()\[\]"\/'] #no delimiters
					|
					\g<nest> #complete nested sub-expression
				    )*
				\k<delim> #end symmetrical delimiters
			    )
			) # end sub-expression denoting correctly nested delimiters 
		    )
		    |
		    [^()\[\]"\/'] #option 2: not delimiters
		    |
		    (?:  # option 3: open brackets with no methods call before them
			(?:
			    \W\d*  # possibly some kind of number but not a name
			    |
			    ^
			)
			\(
		    )
		)*? #as many of the above options as you like
	    )
	    (?: #Here we specify the immediately preceding letter (it cannot be a dot or a colon)
		[^.:()\[\]"\/'] #Not a dot, a colon or a delimiter
		| 
		(?: # not a method call 
		    \W\d*  
		    |
		    ^
		)
		\( #followed by an open bracket
		| 
		^ #we can match the beginning of the string
	     )/x #THE END! 

	
=begin
	Ensures that any following expression is not inside a method(...) pair of brackets, by demanding that any preceding opening bracket '\\(', is 
	  either
		-followed by a closing bracket '\\)' to form a complete set of correctly nested brackets (the <par> subexpression): 
			(?<begin>(?:(?:(?<par>\\((?:[^()]|\\g<par>)*\\))
	  or
		-not preceded by a word character (A-Za-z_) (all method brackets are assumed to have a word character before them; other brackets (e.g. in a logical expression) are assumed not to): 
			(?:(?:[^A-Za-z_]|^)\\())*?)
=end

end


if $0 == __FILE__
	puts " j(KWE) [0]" =~ Regexp.new("(?<b>#{LongRegexen::NAMRSQBQS})")
	par = "q"
	regex1 = Regexp.new("(?<b>#{LongRegexen::NAMRSQBQS.verbatim})\\#?(?<variable>#{Regexp.escape(par)})(?<end>[^A-Za-z_])", Regexp::EXTENDED)
	puts " (q) " =~ regex1
	puts $~.inspect
	puts "t= 0.2000000000E+03 aky=  1.40 akx= -0.02 om= " =~ LongRegexen::FLOAT
	puts "asd"
	puts "	-9.81730399614593e+38;  // phi(2,33,43,2)" =~  Regexp.new("^\\s*?#{LongRegexen::FLOAT.verbatim}.*?\\sphi\\(\\d,(?<theta>\\d+),(?<kx>\\d+)")
end