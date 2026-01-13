#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>

#define INITIAL_TEMPERATURE 1000000
#define COOLING_RATE 0.99999
#define STOP_THRESHOLD 0.001

void anneal(int *current);
void copy(int *current, int *next);
void alter(int *next);
int evaluate(int *next); //Scores the absolute distance of the cityies
void accept(int *current_val, int next_val, int *current, int *next, float temperature);
float adjustTemperature();

typedef struct {
    int x;
    int y; 
}Grid;

int main()
{
    a = 6;                       //Grid row size. Read in from file
    b = 6;                       //Grid column size. Read in from file
    nodes = 7;                   //Nodes of the problem. Read in from file
    static int currend
	static Grid[a][b] = {0};
	int i;
	
	printf("Initial order:\n");
	for (i=0; i<NUM_CITIES; i++)
	{
		printf("%d ", current[i]);
	}
		
	srand(time(NULL));
	anneal(current);
	
	printf("Final order: ");
	for (i=0; i<NUM_CITIES; i++)
	{
		printf("%d ", current[i]);
	}
	
	return 0;
}