/**
* Name: BaseParameter
* Author: julien
* Description: 
* Tags: Tag1, Tag2, TagN
*/

model BaseParameter

global
{
	//Simulated time between two step (in second)
	float deltaT min: 0.0001 max: 1.0 <- 0.1;
	
	//Number of agent
	int number_of_people min: 1 <- 20;
	int number_of_walls min: 0 <- 4;
	
	//Use to choose the kind of simulation you want
	bool isDifferentGroup <- true; 
	bool isRespawn <- true;
	bool headless <- false;
	string type;

	//space dimension
	int spaceWidth min: 2 <- 7;
	int spaceLength min: 5 <-20;
	float bottleneckSize min: 0.0 <- 10.0;

	//incremental var use in species initialisation
	int nd <- 0;
	int nbWalls <- 0;

	//Acceleration  time
	float relaxation min: 0.01 max: 5.0 <- 0.2;

	//Interaction strength
	float Ai min: 0.0 <- 2000.0;

	//Range of the repulsive interactions
	float Bi min: 0.0 <- 0.08;

	//Peception [0,1] => 0 -> 0° and 1 -> 360°
	float lambda min: 0.0 max: 1.0 <- 0.5;
	
	//Body force coefficient
	float body <- 120000.0;
	
	//Fiction coefficient
	float friction <- 240000.0;
	
	//pedestrian caracteristics
	float pedSize <- 0.25;
	float pedDesiredSpeed min: 0.5 max: 10.0 <- 1.34;
	float pedMaxSpeed;

	//Space shape
	geometry shape <- rectangle(spaceLength, spaceWidth);
	
	int lastCycle <- -1;
}

