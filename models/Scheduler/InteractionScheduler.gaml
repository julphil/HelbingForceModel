/**
* Name: InteractionScheduler
* Author: julien
* Description: 
* Tags: Tag1, Tag2, TagN
*/

model InteractionScheduler

import "../Species/People/InteractionPeople.gaml"

global
{
	matrix data; //Data file to create the space 
	
	//Simulation survey
	//At each moment
	int nb_interactionPeople <- number_of_people;
	list<rgb> lcolor;
	float meanNervousness;
	float averageSpeed;
	float meanOrientedSpeed;
	int nbNervoussPeople;
	int peopleOut;
	int peoplePass;
	
	//Average value along the simulation
	float nb_interactionPeopleAVG;
	float meanNervousnessAVG;
	float averageSpeedAVG;
	float meanOrientedSpeedAVG;
	int nbNervoussPeopleAVG;
	
	//Max value
	pair<int,int> maxNervousPeople <- -1::0;
	pair<int,float> maxNervousness <- -1::0.0;
	pair<int,int> maxPeopleIn <- -1::0;
	pair<int,pair<float,float>> maxSpeed <- -1::(0.0::0.0);
	pair<int,pair<float,float>> maxOrientedSpeed <- -1::(0.0::0.0);
	pair<int,float> maxSpeedDifference <- -1::0.0;
	
	//Nervousness field
	matrix<float> nervousnessMap;
	matrix<float> cumuledNervousnessMap;
	matrix<float> temporalNervousnessMap;
	
	//depreciated
	list<int> nervousityDistribution;
	
	//Value use for the generation by Poisson process
	list<list> typeAgent;
	list<pair<int,int>> ArrivalTimes;
	int cptArrival <- 0;
	
	int realStartCycle <- -1;
	
	//Agent creation
	init
	{	
		//Reading data file
		file dataFile <- csv_file(dataFileName,",");
		data <- matrix(dataFile);
		
		int cpt <- 0;
		//Each row is an item (a wall or a set of agents)
		loop i from:0 to:data.rows-1
		{
			if data[0,i] = "agent" {
				//Set the aim area
				list<pair<point>> listAim;
				loop index from:7  to:data.columns-4 step:4 {
					add {data[index,i] as float,data[index+1,i] as float}::{data[index+2,i] as float,data[index+3,i] as float} to:listAim;
				}
				
				//create one agent to start the simulation
				create interactionPeople number:1 with:[init_color::data[1,i],pointAX::data[3,i],pointAY::data[4,i],pointBX::data[5,i],pointBY::data[6,i],lAim::listAim];
				
				//Create a type of agent, use each time on agent spawn
				add [data[1,i],data[2,i],data[3,i],data[4,i],data[5,i],data[6,i],listAim]  to:typeAgent;
				
				//Poisson process
				list<pair<int,int>> tempArrivalTimes;
				int lastTime <- 0;
				
				if (data[2,i] as float) > 0.0
				{
					loop while:lastTime<simulationDuration
					{
						lastTime <- round(lastTime - 1/((data[2,i] as float) * deltaT)*ln(1-rnd(1.0)));
						add lastTime::cpt to:tempArrivalTimes;
					}
				}
				else
				{
					float nbCreate <- (data[2,i] as float)*-1;
					
					loop while:nbCreate >0.00001
					{
						add 0::cpt to:tempArrivalTimes;
						nbCreate <- nbCreate -1;
					}
				}
				ArrivalTimes <- ArrivalTimes + tempArrivalTimes;
				
				cpt <- cpt +1;
				
			} else if data[0,i] = "wall" { //Wall creatoion
				create wall with:[type::data[1,i],locationX::data[2,i],locationY::data[3,i],length::data[4,i],width::data[5,i]];
			} 
		}
		
		//We need to sort arrival times because in the case where we have different type of agents, arrival are set for each type one after another
		ArrivalTimes <- ArrivalTimes sort_by each.key;
		
		
		number_of_people <- length(interactionPeople);
		nb_interactionPeople <- length(interactionPeople);
		pedMaxSpeed <- 7.0;
		
		nervousityDistribution <- list_with(12,0);
		
		
		
		ask field
		{
			ask wall
			{
				if (self overlaps {myself.location.x,myself.location.y})
				{
					myself.isWall <- true;
				}
			}
		}
		
		//Prepare the nervousness field with the simulated are size
		nervousnessMap <- matrix_with({spaceLength,spaceWidth},0.0);
		cumuledNervousnessMap <- matrix_with({spaceLength,spaceWidth},0.0);
		temporalNervousnessMap <- matrix_with({spaceLength,spaceWidth},0.0);
		
		//Rely on Ai and Bi
		calculRange <- calculRange + pedSizeMin*2;
		
		if outputFileName != "null"
		{
			//Add the simulation starting date at the begining of the output files names
			list outPutFileNameDecompose <- outputFileName split_with '/';
			string tmpFileName <- replace(replace(replace(string(#now)," ",""),":",""),"-","") + "_" + last(outPutFileNameDecompose) ;
			remove last(outPutFileNameDecompose) from:outPutFileNameDecompose;
			outputFileName <- "";
			
			
			loop i over:outPutFileNameDecompose
			{
				outputFileName <- outputFileName + i +"/";
			}
			outputFileName <- outputFileName + tmpFileName;
			
			//Prepare the file in which the data out
			outFileData <- "cycle,number of peoples,Average nervousness,number of nervous peoples,average speed,average speed in the goal direction";
			save outFileData to:outputFileName +".csv" rewrite:true;
		}
			
	}
	
	
	//Count thenumber of agents in the simulated area
	action count
	{
		
		nb_interactionPeople <- length(interactionPeople);
		
	}
	
	reflex count
	{
		do count;
	}
	
	//Scheduler of action the simulation perform at each step
	reflex scheduler
	{	
		//First we generate the agent for whom it's the arrival time
		do spawn;
		do count;

		//Clean some variables
		ask interactionPeople{
			do resetStepValue;
		}
		
		//Delete agent who left the simulation (only the one who really left, not the one who are out because they spawn here
		ask interactionPeople{
			do sortie;
		}
		
		//We count how many people where deleted cause they were out
		int nb_interactionPeopleTMP <- nb_interactionPeople;
		do count;
		peopleOut <- peopleOut + (nb_interactionPeopleTMP - nb_interactionPeople);
		
		//Compute the distantce between all agents
		ask interactionPeople parallel:true
		{
			do computeDistance;
		}
		
		//For each agent we set his neighbourhood in the interacton network
		ask interactionPeople parallel:true{
			do setInteraction;
		}
		
		//Set the destination of the agent
		ask interactionPeople parallel:true{
			do aim;
		}
		
		//Count how many people have pass the strategic area
		ask interactionPeople 
		{
			if checkPassing = 1
			{
				myself.peoplePass <- myself.peoplePass + 1;
				do checking;			
			}
			 
		}
		
		if realStartCycle = -1 and peoplePass > 0
		{
			realStartCycle <- cycle;
			write realStartCycle; 
		}
		
		
	
		//Compute the force system applying on every agent
		ask interactionPeople parallel:true{
			do computeForce;	
		}
		
		//With the force system, compute velocity and mouvement
		ask interactionPeople {
			do computeVelocity;
			do mouvement;
		}
		
		//Compute the nervousness transmit by the neighborhood
		ask interactionPeople parallel:true{
			do spreadNervousness;	
		}
		
		//Compute the inner nervousness
		ask interactionPeople parallel:true
		{
			do computeNervousness;
			
		}
		
		//Compose finla nervousnnes with inner and neighborhood
		if (isNervousnessTransmition)
		{
			ask interactionPeople parallel:true
			{
				do computeNervousnessEmpathy;
				do setColor;
			}
		}
		
		ask field parallel:true {
			do reset;
		}
		
		//Mark the field
		ask interactionPeople
		{
			do cellMark;
		}
		
		//Set color of each cells based on the nervousness
		ask field parallel:true{
			do setColor;
		}
		
		do setMax;
		
		do computeAverage;
		
		do saveData;
		
		do writeGraphDGS;
	}
	
	//If agents does not respawn, pause the simulation at the time they're  no more agent in the simulation
	reflex stopIt when:nb_interactionPeople <= 0 {
		if lastCycle = -1
		{
			lastCycle <- cycle;
		}
		do pause;
	}
	
	
	reflex meanNervousness_count
	{
		int count <- 0;
		meanNervousness <-0.0;
		
		ask interactionPeople
		{
			count <- count +1;
			meanNervousness <- meanNervousness + nervousness;
		}
		
		if count != 0
		{meanNervousness <- meanNervousness/count;}
	}
	
	reflex meanAverageSpeed_count
	{
		int count <- 0;
		averageSpeed <- 0.0;
		
		ask interactionPeople
		{
			count <- count +1;
			averageSpeed <- averageSpeed+ norm(actual_velocity);
		}
		
		if count != 0
		{averageSpeed <- averageSpeed/count;}
	}
	
	reflex meanOrientedSpeed_count
	{
		int count <- 0;
		meanOrientedSpeed <- 0.0;
		
		ask interactionPeople
		{
			count <- count +1;
			meanOrientedSpeed <- meanOrientedSpeed+ orientedSpeed;
		}
		
		if count != 0
		{meanOrientedSpeed <- meanOrientedSpeed/count;}
	}
	
	reflex nervousPeople_count
	{
		nbNervoussPeople <- 0;
		
		ask interactionPeople
		{
			if(nervousness >= 0.5) {
				nbNervoussPeople <- nbNervoussPeople + 1;
			}
		}
	}
	
	//Spawn agents with the arrival time set on the initialisation
	action spawn
	{
		loop while:cptArrival<length(ArrivalTimes) and ArrivalTimes[cptArrival].key <= cycle
		{
			create interactionPeople number:1 with:[init_color::typeAgent[ArrivalTimes[cptArrival].value][0],pointAX::typeAgent[ArrivalTimes[cptArrival].value][2],pointAY::typeAgent[ArrivalTimes[cptArrival].value][3],pointBX::typeAgent[ArrivalTimes[cptArrival].value][4],pointBY::typeAgent[ArrivalTimes[cptArrival].value][5],lAim::typeAgent[ArrivalTimes[cptArrival].value][6]];
			number_of_people <- number_of_people + 1;
			cptArrival <- cptArrival + 1;
		}
	}
	
	action setMax
	{
		if nbNervoussPeople > maxNervousPeople.value {maxNervousPeople <- cycle::nbNervoussPeople;}
		if meanNervousness > maxNervousness.value {maxNervousness <- cycle::meanNervousness;}
		if nb_interactionPeople > maxPeopleIn.value {maxPeopleIn <- cycle::nb_interactionPeople;}
		
		if averageSpeed > maxSpeed.value.key {maxSpeed <- cycle::(averageSpeed::meanOrientedSpeed/deltaT);}
		if meanOrientedSpeed/deltaT > maxOrientedSpeed.value.key {maxOrientedSpeed <- cycle::((meanOrientedSpeed/deltaT)::averageSpeed);}
		
		if (averageSpeed - (meanOrientedSpeed/deltaT)) > maxSpeedDifference.value {maxSpeedDifference <- cycle::(averageSpeed - (meanOrientedSpeed/deltaT));}

		ask field
		{
			nervousnessMap[self.grid_x,self.grid_y] <- totalAverageNerv;
			cumuledNervousnessMap[self.grid_x,self.grid_y] <- totalCumuledNerv;
			temporalNervousnessMap[self.grid_x,self.grid_y] <- temporalNerv;
		}
	}
	
	action computeAverage
	{
		if realStartCycle > -1
		{
			nb_interactionPeopleAVG <- nb_interactionPeopleAVG + nb_interactionPeople;
			meanNervousnessAVG <- meanNervousnessAVG +meanNervousness;
			averageSpeedAVG <- averageSpeedAVG +averageSpeed;
			meanOrientedSpeedAVG <- meanOrientedSpeedAVG +meanOrientedSpeed;
			nbNervoussPeopleAVG <- nbNervoussPeopleAVG +nbNervoussPeople;
		}
	}
	
	//Save data in files
	action saveData
	{
		if cycle  mod ((1/deltaT) as int) = 0 and outputFileName != "null"
		{
			outFileData <- "" + cycle;
			outFileData <- outFileData + "," + nb_interactionPeople;
			outFileData <- outFileData + "," + meanNervousness;
			outFileData <- outFileData + "," + nbNervoussPeople;
			outFileData <- outFileData + "," + averageSpeed;
			outFileData <- outFileData + "," + meanOrientedSpeed/deltaT;
			outFileData <- outFileData + "," + peopleOut;
			outFileData <- outFileData + "," + peoplePass;
			
			save outFileData to:outputFileName +".csv" rewrite:false;
			
			if realStartCycle > -1
			{
				outFileData <- "";
				outFileData <- outFileData + "" + nb_interactionPeopleAVG/(cycle-realStartCycle+1);
				outFileData <- outFileData + "," + meanNervousnessAVG/(cycle-realStartCycle+1);
				outFileData <- outFileData + "," + nbNervoussPeopleAVG/(cycle-realStartCycle+1);
				outFileData <- outFileData + "," + averageSpeedAVG/(cycle-realStartCycle+1);
				outFileData <- outFileData + "," + meanOrientedSpeedAVG/(cycle-realStartCycle+1)/deltaT;
				outFileData <- outFileData + "," + peopleOut/(cycle-realStartCycle+1)/deltaT;
				outFileData <- outFileData + "," + peoplePass/(cycle-realStartCycle+1)/deltaT;
				
				save outFileData to:outputFileName +"_average.csv" rewrite:true;
			}
		
			
			string maxData <- 
			"Number of people succeding escape : " + nbPeopleOut + "\n" +
			"Maximum number of nervous people : " + maxNervousPeople.value + " at cycle " + maxNervousPeople.key + "\n" +
			"Maximum nervousness reach : " + maxNervousness.value + " at cycle " + maxNervousness.key + "\n" +
			"Maximum number of people in the space at the same time : " + maxPeopleIn.value +  "at cycle " + maxPeopleIn.key +  "\n" +
			"Maximum  average speed reach : " + maxSpeed.value.key + " at cycle " + maxSpeed.key +  " when at the same time the oriented speed is " + maxSpeed.value.value + "\n" +
			"Maximum oriented speed reach : " + maxOrientedSpeed.value.key + " at cycle " + maxOrientedSpeed.key +  " when at the same time the speed is " + maxOrientedSpeed.value.value + "\n" +
			"Larger difference between speed and oriented speed : " +  maxSpeedDifference.value + " at the cycle " + maxSpeedDifference.key  + "\n" + 
			nbPeopleOut + "," + maxNervousPeople.value + "," + maxNervousness.value + "," + maxPeopleIn.value + "," + maxSpeed.value.key + "," + maxOrientedSpeed.value.key + "," + maxSpeedDifference.value +"\n" +
			"\nAverage nervousness map :\n\n" + nervousnessMap + "\n" +
			"\nCumuled nervousness map :\n\n" + cumuledNervousnessMap
			;
			
			save maxData to:outputFileName + "_max.txt" type:text;
					
		}
		if cycle  mod intervalLength = 0 and outputFileName != "null"
		{
			string writeData <- "" + temporalNervousnessMap + "\n";
			
			save writeData to:outputFileName + "_temporal.txt" rewrite:false type:text;
		}
	}
	
	action writeGraphDGS
	{
		if cycle  mod ((1/deltaT) as int) = 0 and graphOutput
		{
			outFileData <- "\nst :" + int(cycle*deltaT) + "\ncl";
			string outEdge <- "\n";
			
			ask interactionPeople
			{
				outFileData <- outFileData + "\nan " + int(self) + " x:" + self.location.x + " y:" + self.location.y + " innerNerv:" + self.nervousness + " lastNerv:" + self.lastNervousness + " currentNerv:" + self.nervousness;
				
				loop p over:interaction
				{
					outEdge <- outEdge + "\nae " + int(self) + "to" + int(p) + " " + int(self) + " < " + int(p) + " nervpass:" + p.lastNervousness;
				}
				 
			} 
			
			save outFileData+outEdge to:outputFileName +"_graph.dgs" rewrite:false;
			
		}
	}
}

