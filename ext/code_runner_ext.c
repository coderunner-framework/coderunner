#include "code_runner_ext.h"


static VALUE code_runner_ext_hello_world()
{
	printf("Hello world");
	return Qnil;
}
void Init_code_runner_ext()
{
	/*printf("HERE!!!");*/
	ccode_runner_ext =  rb_define_class("CodeRunnerExt", rb_cObject);
	rb_define_method(ccode_runner_ext, "hello_world", code_runner_ext_hello_world, 0);
	Init_graph_kit();
}

/*printf("HERE!!!");*/
