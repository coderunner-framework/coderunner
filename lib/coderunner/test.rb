module Tst
	def self.check(name, obj, test_string, expected_results, error_class)
		value = obj.instance_eval test_string
		unless (expected_results.class == Array ? expected_results.include?(value) : value == expected_results)
			message = "\n==============================\n"
			message += "=        Test Failed         =\n"
			message += "==============================\n\n"
			message += "Object Description: #{name}\n"
			message += "Object Value: #{obj.inspect}\n"
			message += "Test: #{test_string.inspect}\n" 
			message += "Expected Result:  #{expected_results}\n"
			message += "Actual Result: #{value.inspect}"
			message += "\n\n==============================="
			raise error_class.new(message)
		end
	end

	class TestProc < Proc
		alias :test :call
	end
	class MakeProc < Proc
		alias :with_result :call
	end
	
	#MakeProcs - used for making tests
	KIND_OF = MakeProc.new{|*klasses| TestProc.new{|obj, name=""| check(name, obj, klasses.inject(""){|str, klass| str << " or self.kind_of? #{klass.to_s}"}.sub(/^ or /, '') , true, TypeError)}}
	VALUE = MakeProc.new{|*values| TestProc.new{|obj, name=""| check(name, obj, "self", values, ArgumentError)}}

	#Some predefined tests
	FLOAT = KIND_OF.with_result(Float, Integer)
	FLOAT_STRICT = KIND_OF.with_result(Float)
	INT= INTEGER = KIND_OF.with_result(Integer)
	STRING = KIND_OF.with_result(String)
	FORTRAN_BOOL = VALUE.with_result(*String::FORTRAN_BOOLS)
end