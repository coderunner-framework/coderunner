#include <stdio.h>
#include <iostream>
#include <cstdlib>
#include <fstream>
#include <cstring>
#include <ctime>
using namespace std;

int main(int argc, char* argv[]){
	string line;
	cout << "Starting..." << endl;
	
	int calculate_sides = atoi(argv[1]); //Should the program calculate the area of the sides of the cube? 
	cout << calculate_sides << endl;
	
	char* input_file_name = argv[2]; //Get the input file name from the command line
	cout << input_file_name << endl;
	
	if (argc > 3){ //It has been told to sleep for a time
		bool cont = true;
		time_t start_t;
		time(&start_t);
		while (cont){
			time_t new_t;
			time(&new_t);
			cont = (new_t < (start_t + atoi(argv[3]) * 1.0));
		}
	}
	
	ifstream edges_file(input_file_name); //Read the edges from the input file
	float* edges = new float[3];
	int j = 0;
	while (edges_file >> edges[j++]){
		cout << edges[j-1] << endl;
	}
	
	
	FILE* output = fopen("results.txt", "w"); //Write the volume to the output file
	fprintf(output, "Volume was %f", edges[0] * edges[1] * edges[2]);
	fclose(output);
	
	if (calculate_sides == 1){ //If it has been told to calculate the sides
		cout << "calculating sides" << endl;
		FILE* sides = fopen("sides.txt", "w");
		for(int i=0; i<3; i++){
			cout << "Side " << i << ": " << edges[(i%3)] * edges[((i+1)%3)] << endl;
			fprintf(sides, "The area of side %d is %f\n", i, edges[i%3] * edges[(i+1)%3]);
		}
		fclose(sides);
	}
}
	