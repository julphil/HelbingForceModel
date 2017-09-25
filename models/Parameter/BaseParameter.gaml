/**
* Name: BaseParameter
* Author: julien
* Description: 
* Tags: Tag1, Tag2, TagN
*/

model BaseParameter

global
{
	string dataFileName;
	
	//Simulated time between two step (in second)
	float deltaT min: 0.0001 max: 1.0 <- 0.1;
	
	int simulationDuration;
	
	//Number of agent
	int nb_people;
	int number_of_people;
	int max_people;
	
	//Use to choose the kind of simulation you want
	bool isRespawn <- true;

	//space dimension
	int spaceWidth min: 2 <- 7;
	int spaceLength min: 5 <-20;

	//Acceleration  time
	float relaxation min: 0.01 max: 5.0 <- 0.2;

	//Interaction strength
	float Ai min: 0.0 <- 2000.0;

	//Range of the repulsive interactions
	float Bi min: 0.0 <- 0.08;
	
	//Distance beyond force calculus are avoid
	float calculRange min: 0.0 <- 1;

	//Peception [0,1] => 0 -> 0° and 1 -> 360°
	float lambda min: 0.0 max: 1.0 <- 0.5;
	
	//Body force coefficient
	float body <- 120000.0;
	
	//Fiction coefficient
	float friction <- 240000.0;
	
	//pedestrian caracteristics
	float pedSizeMin <- 0.25;
	float pedSizeMax <- 0.35;
	float pedDesiredSpeed min: 0.5 max: 10.0 <- 1.34;
	float pedMaxSpeed;

	//Space shape
	geometry shape <- rectangle(spaceLength, spaceWidth);
	
	int lastCycle <- -1;
	
	//To know if forces are display
	bool arrow;
	
	//machine error
	float epsilon <- 0.0000001;
	
	
	//FILE
	string outputFileName;
	string outFileData;
	
	
	//How many agents have left the
	int nbPeopleOut <- 0;
	
	//In the list of area agents must consecutively reach, it's the index of the one which is the "strategic area" (lick a bottleneck)
	int indexPassing <-1;
	
	//Simulation time
	date simulationTime <- #now;
	
}

