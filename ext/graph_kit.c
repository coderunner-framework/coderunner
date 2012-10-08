#include "code_runner_ext.h"

/* RANKS:*/
/*0 --> [1]*/
/*1 --> [1, 1]*/
/*2 --> [1, 1, 1]*/
/*3 --> [1, 1, 2]*/
/*4 --> [2, 2, 2]*/
/*5 --> [2, 2, 2, 2]*/
/*6 --> [1, 1, 1, 1]*/
/*7 --> [1, 1, 2, 2]*/
/*8 --> [1, 1, 1, 3]*/
/*9 --> [3, 3, 3, 3]*/

inline int rank_switch(VALUE data_kit){
  return FIX2INT(RFCALL_10_ON(
				data_kit, "rank_c_switch"));
}

void get_data_pointer(VALUE data_kit, VALUE * dp){
	/*VALUE * dp;*/
	VALUE * axes;
	int i, nranks;

	nranks = FIX2INT(RFCALL_10_ON(
						RFCALL_10_ON(data_kit,"ranks"), 
						"size"));
	/*dp = ALLOC_N(VALUE, nranks);*/
	axes = RARRAY_PTR(RFCALL_10_ON(data_kit, "axes_array"));
	for (i=0;i<nranks;i++)
		dp[i] = RFCALL_10_ON(axes[i], "data");
	return;
}

enum tasks {
	PRINT_POINTS,
	COUNT_CELLS,
	PRINT_CELLS,
	COUNT_CELL_TYPES,
	PRINT_CELL_TYPES,
	PRINT_POINT_DATA,
  PRINT_DIMENSIONS
};


void vtk_legacy_data_kit_loop(enum tasks task, FILE * file, VALUE data_kit, int *cell_count, int *number_count){
	VALUE * data_ptr, *shape_last, *axes, *ranks;
	int * c_shape_last;
	int i, j, k, data_size;
	int ni, nj, nk, nc;
	int nranks, rank_last;
	int cell_size;
	int cell_type;
	/*int cell_points[8];*/

	axes = RARRAY_PTR(RFCALL_10_ON(data_kit, "axes_array"));
	ranks = RARRAY_PTR(RFCALL_10_ON(data_kit, "ranks"));
	/*nranks = FIX2INT(RFCALL_10_ON(ranks,"size"));*/
	/*nranks = sizeof(ranks)/sizeof(VALUE);*/
	nranks = FIX2INT(RFCALL_10_ON(
						RFCALL_10_ON(data_kit,"ranks"), 
						"size"));
	data_ptr = ALLOCA_N(VALUE, nranks);
	get_data_pointer(data_kit, data_ptr);
	/*nranks = sizeof(data_ptr)/sizeof(VALUE);*/
	/*CR_PINT2("nranks", nranks);*/
	shape_last = RARRAY_PTR(
			RFCALL_10_ON(axes[nranks-1], "shape"));
	CR_INT_ARY_R2C_STACK(
			RFCALL_10_ON(axes[nranks-1], "shape"),
			c_shape_last);
	ni = c_shape_last[0];
	nj = c_shape_last[1];
	nk = c_shape_last[2];
	rank_last = FIX2INT(ranks[nranks-1]);
	/*CR_PINT2("rank_last", rank_last);*/

	data_size = 1;
	for(i=0;i<nranks;i++) 
		data_size *= c_shape_last[i];


	/*CR_PINT2("data_size", data_size);*/
	switch(task){
		case PRINT_POINTS:
		switch(rank_switch(data_kit)){
			case 0:
				for(i=0;i<data_size;i++)
					fprintf(file, "0 %d %e\n", i, 
							NUM2DBL( RFCALL_11_ON( data_ptr[0], "[]", INT2FIX(i))));
				break;
			case 1:
				for(i=0;i<data_size;i++)
					fprintf(file, "0 %e %e\n",  
							NUM2DBL( RFCALL_11_ON( data_ptr[0], "[]", INT2FIX(i))),
							NUM2DBL( RFCALL_11_ON( data_ptr[1], "[]", INT2FIX(i)))
							);
				break;
			case 2: /*[1,1,1]*/
			case 6: /*[1,1,1,1]*/
				for(i=0;i<data_size;i++)
					fprintf(file, "%e %e %e\n",  
							NUM2DBL( RFCALL_11_ON( data_ptr[0], "[]", INT2FIX(i))),
							NUM2DBL( RFCALL_11_ON( data_ptr[1], "[]", INT2FIX(i))),
							NUM2DBL( RFCALL_11_ON( data_ptr[2], "[]", INT2FIX(i)))
							);
				break;
			case 3: /*[1,1,2]*/
			case 7: /*[1,1,2,2]*/
				for(i=0;i<c_shape_last[0];i++)
				for(j=0;j<c_shape_last[1];j++)
					fprintf(file, "%e %e %e\n",  
						NUM2DBL(CR_TELMT_R1(data_ptr[0], i)),
						NUM2DBL(CR_TELMT_R1(data_ptr[1], j)),
						NUM2DBL(CR_TELMT_R2(data_ptr[2], i, j)) 
							);
				break;
			case 4: /*[2,2,2]*/
			case 5: /*[2,2,2,2]*/
				for(i=0;i<c_shape_last[0];i++)
				for(j=0;j<c_shape_last[1];j++)
					fprintf(file, "%e %e %e\n",  
						NUM2DBL(CR_TELMT_R2(data_ptr[0],i,j)),
						NUM2DBL(CR_TELMT_R2(data_ptr[1],i,j)),
						NUM2DBL(CR_TELMT_R2(data_ptr[2],i,j)) 
							);
				break;
			case 8: /*[1,1,1,3]*/
				for(i=0;i<c_shape_last[0];i++)
				for(j=0;j<c_shape_last[1];j++)
				for(k=0;k<c_shape_last[2];k++)
					fprintf(file, "%e %e %e\n",  
						NUM2DBL(CR_TELMT_R1(data_ptr[0], i)),
						NUM2DBL(CR_TELMT_R1(data_ptr[1], j)),
						NUM2DBL(CR_TELMT_R1(data_ptr[2], k))
							);
				break;
			case 9: /*[3,3,3,3]*/
				for(i=0;i<c_shape_last[0];i++)
				for(j=0;j<c_shape_last[1];j++)
				for(k=0;k<c_shape_last[2];k++)
					fprintf(file, "%e %e %e\n",  
						NUM2DBL(CR_TELMT_R3(data_ptr[0],i,j,k)),
						NUM2DBL(CR_TELMT_R3(data_ptr[1],i,j,k)),
						NUM2DBL(CR_TELMT_R3(data_ptr[2],i,j,k))
							);
				break;



		}
		break; /*switch(task)*/
	case COUNT_CELLS:
		switch (rank_switch(data_kit)){
			case 0: /*[1]*/
			case 1: /*[1,1]*/ 
			case 2: /*[1,1,1]*/ 
			case 6: /*[1,1,1,1]*/ 
				*cell_count +=  c_shape_last[0]-1;
				*number_count += 3*(c_shape_last[0]-1);
				break;
			case 3: /*[1,1,2]*/
			case 4: /*[2,2,2]*/
			case 7: /*[1,1,2,2]*/
			case 5: /*[2,2,2,2]*/
				cell_size=1;
				if (ni>1) cell_size*=2;
				if (nj>1) cell_size*=2;
				for(i=0;i<c_shape_last[0];i++)
				for(j=0;j<c_shape_last[1];j++){
					if (
							!(
								(ni == 1 || (i+1) < ni) 
								&&
								(nj == 1 || (j+1) < nj)
							 )
						 ) continue;
					*cell_count+=1;
					*number_count+= cell_size; 
					*number_count+=1;

				}
				break;
			case 8: /*[1,1,1,3]*/
			case 9: /*[3,3,3,3]*/
				cell_size=1;
				if (ni>1) cell_size*=2;
				if (nj>1) cell_size*=2;
				if (nk>1) cell_size*=2;
				for(i=0;i<c_shape_last[0];i++)
				for(j=0;j<c_shape_last[1];j++)
				for(k=0;k<c_shape_last[2];k++){
					if (
							!(
								(ni == 1 || (i+1) < ni) 
								&&
								(nj == 1 || (j+1) < nj)
								&&
								(nk == 1 || (k+1) < nk)
							 )
						 ) continue;
					*cell_count+=1;
					*number_count+= cell_size; 
					*number_count+=1;

				}
				break;


		}
		break;
	case PRINT_CELLS:
		/*CR_PSTR("HERE!");*/
		switch (rank_switch(data_kit)){
			case 0: /*[1]*/
			case 1: /*[1,1]*/ 
			case 2: /*[1,1,1]*/ 
			case 6: /*[1,1,1,1]*/ 
				for (i=0;i<c_shape_last[0]-1;i++){
					fprintf(file, "2 %d %d\n", *number_count, ++*number_count);
					*number_count+=1;
				}
					/**cell_count +=  c_shape_last[0]-1;*/
					/**number_count += 3*(c_shape_last[0]-1);*/
				break;
			case 3: /*[1,1,2]*/
			case 4: /*[2,2,2]*/
			case 7: /*[1,1,2,2]*/
			case 5: /*[2,2,2,2]*/
				/*cell_size =  (ni>1?(nj>1?4:2):1);*/
				cell_size=1;
				if (ni>1) cell_size*=2;
				if (nj>1) cell_size*=2;
				nc = *number_count;
				for(i=0;i<c_shape_last[0];i++)
				for(j=0;j<c_shape_last[1];j++){
					*number_count+=1;
					if (
							!(
								(ni == 1 || (i+1) < ni) 
								&&
								(nj == 1 || (j+1) < nj)
							 )
						 ) continue;
					/**cell_count+=1;*/
					/**number_count+= cell_size; */
					if (ni>1){
						if (nj>1)
							fprintf(file,
								"4 %d %d %d %d\n",
								i*nj+j+nc,
								i*(nj)+j+1+nc,
								(i+1)*nj+j+1+nc,
								(i+1)*nj+j+nc);
						else 
							fprintf(file,
								"2 %d %d\n",
								i*nj+j+nc,
								(i+1)*nj+j+nc);
					}
					else{
						if (nj>1) 
							fprintf(file,
								"2 %d %d\n",
								i*nj+j+nc,
								i*(nj)+j+1+nc);
						else
							fprintf(file, "1 %d\n", i*nj+j+nc);
					}

				}
				break;
			case 8: /*[1,1,1,3]*/
			case 9: /*[3,3,3,3]*/
				/*CR_PSTR("HERE!2");*/
				cell_size=1;
				if (ni>1) cell_size*=2;
				if (nj>1) cell_size*=2;
				if (nk>1) cell_size*=2;
				nc = *number_count;
				/*CR_PINT2("nc", nc);*/
				/*nc = 0;*/
				for(i=0;i<c_shape_last[0];i++)
				for(j=0;j<c_shape_last[1];j++)
				for(k=0;k<c_shape_last[2];k++){
					*number_count+=1; 
					if (
							!(
								(ni == 1 || (i+1) < ni) 
								&&
								(nj == 1 || (j+1) < nj)
								&&
								(nk == 1 || (k+1) < nk)
							 )
						 ) continue;
					/**cell_count+=1;*/
					/**number_count+=1;*/
					if(ni>1){
						if(nj>1){
							if(nk>1)
								fprintf(file,
										"8 %d %d %d %d %d %d %d %d\n",
										i*(nj*nk)+j*nk+k+nc,
										i*(nj*nk)+j*nk+k+1+nc,
										i*(nj*nk)+(j+1)*nk+k+nc,
										i*(nj*nk)+(j+1)*nk+k+1+nc,
										(i+1)*(nj*nk)+j*nk+k+nc,
										(i+1)*(nj*nk)+j*nk+k+1+nc,
										(i+1)*(nj*nk)+(j+1)*nk+k+nc,
										(i+1)*(nj*nk)+(j+1)*nk+k+1+nc
										);
							else
								fprintf(file,
										"4 %d %d %d %d\n",
										i*(nj*nk)+j*nk+k+nc,
										i*(nj*nk)+(j+1)*nk+k+nc,

										(i+1)*(nj*nk)+(j+1)*nk+k+nc,
										(i+1)*(nj*nk)+j*nk+k+nc
										);
						}
						else{
							if(nk>1)
								fprintf(file,
										"4 %d %d %d %d\n",
										i*(nj*nk)+j*nk+k+nc,
										i*(nj*nk)+j*nk+k+1+nc,

										(i+1)*(nj*nk)+j*nk+k+1+nc,
										(i+1)*(nj*nk)+j*nk+k+nc
										);
							else
								fprintf(file,
										"2 %d %d\n",
										i*(nj*nk)+j*nk+k+nc,
										(i+1)*(nj*nk)+j*nk+k+nc
										);
						}
					}
					else{
						if(nj>1){
							if(nk>1)
								fprintf(file,
										"4 %d %d %d %d\n",
										i*(nj*nk)+j*nk+k+nc,
										i*(nj*nk)+j*nk+k+1+nc,
										
										i*(nj*nk)+(j+1)*nk+k+1+nc,
										i*(nj*nk)+(j+1)*nk+k+nc
										);
							else
								fprintf(file,
										"2 %d %d\n",
										i*(nj*nk)+j*nk+k+nc,
										i*(nj*nk)+(j+1)*nk+k+nc
										);
						}
						else{
							if(nk>1)
								fprintf(file,
										"2 %d %d\n",
										i*(nj*nk)+j*nk+k+nc,
										i*(nj*nk)+j*nk+k+1+nc
										);
							else
								fprintf(file,
										"1 %d\n",
										i*(nj*nk)+j*nk+k+nc
										);
						}
					}

				}
				break;


		} /* end switch(rank_switch))*/
		break;
	case PRINT_CELL_TYPES:
		switch (rank_switch(data_kit)){
			case 0: /*[1]*/
			case 1: /*[1,1]*/ 
			case 2: /*[1,1,1]*/ 
			case 6: /*[1,1,1,1]*/ 
				for (i=0;i<c_shape_last[0]-1;i++)
					fprintf(file, "3\n");
					/**cell_count +=  c_shape_last[0]-1;*/
					/**number_count += 3*(c_shape_last[0]-1);*/
				break;
			case 3: /*[1,1,2]*/
			case 4: /*[2,2,2]*/
			case 7: /*[1,1,2,2]*/
			case 5: /*[2,2,2,2]*/
				/*cell_size =  (ni>1?(nj>1?4:2):1);*/
				cell_size=1;
				if (ni>1) cell_size*=2;
				if (nj>1) cell_size*=2;
				switch(cell_size){
					case 4:
						cell_type = 7; break;
					case 2:
						cell_type = 3; break;
					case 1:
						cell_type = 1; break;
				}


				for(i=0;i<c_shape_last[0];i++)
				for(j=0;j<c_shape_last[1];j++){
					if (
							!(
								(ni == 1 || (i+1) < ni) 
								&&
								(nj == 1 || (j+1) < nj)
							 )
						 ) continue;
					/**cell_count+=1;*/
					/**number_count+= cell_size; */
					/**number_count+=1;*/
					fprintf(file, "%d\n", cell_type);

				}
				break;
			case 8: /*[1,1,1,3]*/
			case 9: /*[3,3,3,3]*/
				cell_size=1;
				if (ni>1) cell_size*=2;
				if (nj>1) cell_size*=2;
				if (nk>1) cell_size*=2;
				switch(cell_size){
					case 8:
						cell_type = 11; break; /*3D cells, see www.vtk.org/VTK/img/file-formats.pdf*/
					case 4:
						cell_type = 7; break; /*Polygons*/
					case 2:
						cell_type = 3; break; /*Lines*/
					case 1:
						cell_type = 1; break; /*Points*/
				}
				for(i=0;i<c_shape_last[0];i++)
				for(j=0;j<c_shape_last[1];j++)
				for(k=0;k<c_shape_last[2];k++){
					if (
							!(
								(ni == 1 || (i+1) < ni) 
								&&
								(nj == 1 || (j+1) < nj)
								&&
								(nk == 1 || (k+1) < nk)
							 )
						 ) continue;
					fprintf(file, "%d\n", cell_type);

				}
				break;


		} /*end switch rank_switch*/
		break;
	case PRINT_POINT_DATA:
		switch (rank_switch(data_kit)){
			case 0: /*[1]*/
			case 1: /*[1,1]*/ 
			case 2: /*[1,1,1]*/ 
				for (i=0;i<c_shape_last[0]-1;i++)
					fprintf(file, "%d\n", 0);
				break;
			case 6: /*[1,1,1,1]*/ 
				for (i=0;i<c_shape_last[0]-1;i++)
					fprintf(file, "%e\n", 
							NUM2DBL(CR_TELMT_R1(data_ptr[3], i)));
				break;
			case 3: /*[1,1,2]*/
			case 4: /*[2,2,2]*/
				for(i=0;i<c_shape_last[0];i++)
				for(j=0;j<c_shape_last[1];j++)
					fprintf(file, "%d\n", 0);
				break;
			case 7: /*[1,1,2,2]*/
			case 5: /*[2,2,2,2]*/

				for(i=0;i<c_shape_last[0];i++)
				for(j=0;j<c_shape_last[1];j++)
					fprintf(file, "%e\n", 
						NUM2DBL(CR_TELMT_R2(data_ptr[3],i,j)));

				
				break;
			case 8: /*[1,1,1,3]*/
			case 9: /*[3,3,3,3]*/
				for(i=0;i<c_shape_last[0];i++)
				for(j=0;j<c_shape_last[1];j++)
				for(k=0;k<c_shape_last[2];k++)
					fprintf(file, "%e\n", 
						NUM2DBL(CR_TELMT_R3(data_ptr[3],i,j,k))
						);
				
				break;


		} /*end switch rank_switch*/
		break;
	case PRINT_DIMENSIONS:
		switch (rank_switch(data_kit)){
			case 8: /*[1,1,1,3]*/
			case 9: /*[3,3,3,3]*/
				fprintf(file, "DIMENSIONS %d %d %d\n", ni, nj, nj);
		} /*end switch rank_switch*/

	} /* end switch(task)*/
	
	return; 
}

static VALUE graph_kit_to_vtk_legacy_2(VALUE graph_kit, VALUE options_hash)
{
	VALUE file_name;
	VALUE data;
	char * c_file_name;
	int npoints, data_size;
	int i, j, k;
	int cell_count, number_count, dummy;
	FILE *file;
	VALUE dirname;
	VALUE data_kit0;

	/*CR_PSTR("Calling graph_kit_to_vtk_legacy_2");*/
	Check_Type(options_hash, T_HASH);
	file_name = CR_HKS(options_hash, "file_name");
	Check_Type(file_name, T_STRING);

	data = RFCALL_10_ON(graph_kit, "data");
	data_size = FIX2INT(RFCALL_10_ON(data, "size"));
	npoints = 0;

	for (i=0;i<data_size;i++){
		/*rb_p(RARRAY_PTR(data)[i]);*/
		npoints = npoints + 
			FIX2INT(
					RFCALL_10_ON(
						RARRAY_PTR(data)[i], "vtk_legacy_size"
						)
					);
	}

	/*CR_PINT2("npoints", npoints);*/

	/*dirname = rb_funcall(*/
	/*RGET_CLASS_TOP("File"),*/
	/*rb_intern("dirname"),*/
	/*file_name);*/

	/*if (!RTEST(*/
	/*(rb_funcall(*/
	/*RGET_CLASS_TOP("FileTest"),*/
	/*rb_intern("exist?"),*/
	/*dirname*/
	/*))*/
	/*))*/
	/*rb_raise(RGET_CLASS_TOP("StandardError"), "Directory does not exist");*/

					
	c_file_name = RSTRING_PTR(file_name);
	file = fopen(c_file_name, "w");
	fprintf(file, "# vtk DataFile Version 3.0\n");
	fprintf(file, "vtk output\n");
	fprintf(file, "ASCII\n");

	if (0 && data_size==1) 
		/* Can write smaller, more efficient files, 
		 * but not possible to volume render them
		 * -- work in progress!
		 * Would also need to make x vary fastest
		 * in output*/
	{
		data_kit0 = RARRAY_PTR(data)[0];
		switch(rank_switch(data_kit0)){
			case 9: /* [3,3,3,3]*/
				fprintf(file, "DATASET STRUCTURED_GRID\n");
				vtk_legacy_data_kit_loop(
					PRINT_DIMENSIONS,
					file, data_kit0, &dummy, &dummy);
				cell_count = 0;
				number_count = 0;
				vtk_legacy_data_kit_loop(
						COUNT_CELLS,
						file, data_kit0, &cell_count, &dummy);
				fprintf(file, "POINTS %d float\n", npoints);
				vtk_legacy_data_kit_loop(
					PRINT_POINTS,
					file, data_kit0, &dummy, &dummy);
				fprintf(file, "\nCELL_DATA %d\n", cell_count);
		}
	}
	else /*Have to treat the most general case*/
	{
		fprintf(file, "DATASET UNSTRUCTURED_GRID\n");
		fprintf(file, "POINTS %d float\n", npoints);
		for (i=0;i<data_size;i++)
			vtk_legacy_data_kit_loop(
					PRINT_POINTS,
					file, RARRAY_PTR(data)[i],
					&dummy, &dummy);
		cell_count = 0;
		number_count = 0;
		for (i=0;i<data_size;i++)
			vtk_legacy_data_kit_loop(
					COUNT_CELLS,
					file, RARRAY_PTR(data)[i],
					&cell_count, &number_count);
		fprintf(file, "\nCELLS %d %d\n", cell_count, number_count);
		number_count = 0;
		for (i=0;i<data_size;i++)
			vtk_legacy_data_kit_loop(
					PRINT_CELLS,
					file, RARRAY_PTR(data)[i],
					&dummy, &number_count);
		fprintf(file, "\nCELL_TYPES %d\n", cell_count);
		for (i=0;i<data_size;i++)
			vtk_legacy_data_kit_loop(
					PRINT_CELL_TYPES,
					file, RARRAY_PTR(data)[i],
					&dummy, &dummy);
	}
	fprintf(file, "\nPOINT_DATA %d\n", npoints); 
	fprintf(file, "SCALARS myvals float\n"); 
	fprintf(file, "LOOKUP_TABLE default\n"); 
	for (i=0;i<data_size;i++)
		vtk_legacy_data_kit_loop(
				PRINT_POINT_DATA,
				file, RARRAY_PTR(data)[i],
				&dummy, &dummy);
	fclose(file);
	return Qnil;
}


void Init_graph_kit()
{
	ID graph_kit_class_id;
	graph_kit_class_id = rb_intern("GraphKit");
	cgraph_kit = rb_const_get(rb_cObject, graph_kit_class_id);
	/*cgraph_kit = rb_define_class("GraphKit", rb_cObject);*/
	/*("GraphKit", rb_cObject);*/
	rb_define_method(cgraph_kit, "to_vtk_legacy_fast", graph_kit_to_vtk_legacy_2, 1);

}
