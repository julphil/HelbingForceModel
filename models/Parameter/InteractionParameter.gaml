/**
* Name: InteractionParameter
* Author: julien
* Description: 
* Tags: Tag1, Tag2, TagN
*/

model InteractionParameter

global
{
	bool demonstrationMode; 
	
	int id_configuration;
	int id_simulationset;
	
	//machine error
	float epsilon <- 0.0000001;
	
		string dataFileName;
	
	/////////////////Helbing model parameter
	//Acceleration  time
	float relaxation min: 0.01 max: 5.0 <- 0.2;

	//Interaction strength
	float Ai min: 0.0 <- 2000.0;

	//Range of the repulsive interactions
	float Bi min: 0.0 <- 0.08;
	
	//Distance beyond force calculus are avoid
	float calculRange min: 0.0 <- 1.0;

	//Peception [0,1] => 0 -> 0° and 1 -> 360°
	float lambda min: 0.0 max: 1.0 <- 0.5;
	
	//Body force coefficient
	float body <- 120000.0;
	
	//Fiction coefficient
	float friction <- 240000.0;
	
	/////////Nervousness and interacion
	//Use to choose the kind of simulation you want
	bool isFluctuation  <- false;
	string fluctuationType;

	//Propagation parameter
	string interactionType;
	bool is360;
	float perceptionRange min:-1.0 max:30.0;
	bool isNervousnessTransmition;
	float empathy <- 0.0;
	float angleInteraction;
	float threshold <- 0.0;
	
	//////////pedestrian caracteristics
	float pedSizeMin <- 0.25;
	float pedSizeMax <- 0.35;
	float pedDesiredSpeed min: 0.5 max: 10.0 <- 1.34;
	float pedMaxSpeed;
	
	//////////Expemeriment space config
	//space dimension
	int spaceWidth min: 2 <- 7;
	int spaceLength min: 5 <-20;

	//Space shape
	geometry shape <- rectangle(spaceLength, spaceWidth);
	
	//In the list of area agents must consecutively reach, it's the index of the one which is the "strategic area" (lick a bottleneck)
	int indexPassing <-1;
	
	//Time paramter
	//Simulated time between two step (in second)
	float deltaT min: 0.0001 max: 1.0 <- 0.1;
	
	int simulationDuration;
	
	//Simulation date
	date simulationTime <- #now;
	
	//Duration of the interval in which we mesure nervousness in the simulated space
	int intervalLength;
	
	////////OUtput
		//To know if forces are display
	bool arrow;
	
	//FILE
	string outputFileName;
	string outFileData;
	

	//If true, the interaction graph must be write in a file
	bool graphOutput;
	
	//Use to choose the kind of simulation you want
	bool isRespawn <- true;
	
	///////Measure
	//Number of agent
	int nb_people;
	int number_of_people;
	int max_people;
	int nb_interactionPeople;
	
	//How many agents have left the
	int nbPeopleOut <- 0;
	
	int lastCycle <- -1;

}

