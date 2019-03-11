/**
* Name: InteractionScheduler
* Author: julien
* Description: 
* Tags: Tag1, Tag2, TagN
*/

model InteractionScheduler

import "../Species/People/InteractionPeople.gaml"
import "../connectDB/ConnectDB.gaml"

global
{
	int id_simulation; //simulation's id in the database
	
	matrix data; //Data file to create the space 
	
	//Parameter from the database
	map parameter;
    list<map> agentset;
    list<map> walls;
	
	//Simulation survey
	//At each moment
	
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
		nb_interactionPeople <- number_of_people;
		
		create connection number:1 with:[id_configuration::id_configuration];
		
		ask connection {
			myself.parameter <- self.parameter;
			myself.agentset <- self.agentset;
    		myself.walls <- self.walls;
		}
		
		do initParameter;
		
		loop w over: walls {
			create wall with:[type::"rectangle",locationX::float(w['COORDX']),locationY::float(w['COORDY']),length::float(w['LARGEUR']),width::float(w['LONGUEUR'])];
		}
		
		int cpt <- 0;
		loop aS over:agentset {
			list<pair<point>> listAim;
				loop o from:1 to:length(list(aS["ZONE"])) -1 {
					add {aS["ZONE"][o]["COORDLTX"] as float,aS["ZONE"][o]["COORDLTY"] as float}::{aS["ZONE"][o]["COORDRDX"] as float,aS["ZONE"][o]["COORDRDY"] as float} to:listAim;
				}
				
				//create one agent to start the simulation
				create interactionPeople number:1 with:[init_color::aS["COLOR"],pointAX::float(aS["ZONE"][0]["COORDLTX"]),pointAY::float(aS["ZONE"][0]["COORDLTY"]),pointBX::float(aS["ZONE"][0]["COORDRDX"]),pointBY::float(aS["ZONE"][0]["COORDRDY"]),lAim::listAim];
				
				//Create a type of agent, use each time on agent spawn
				add [aS["COLOR"],aS["PARAMGENERATION"],float(aS["ZONE"][0]["COORDLTX"]),float(aS["ZONE"][0]["COORDLTY"]),float(aS["ZONE"][0]["COORDRDX"]),float(aS["ZONE"][0]["COORDRDY"]),listAim]  to:typeAgent;
				
				//Poisson process
				list<pair<int,int>> tempArrivalTimes;
				int lastTime <- 0;
				
				if bool(aS["ISPOISSON"])
				{
					loop while:lastTime<simulationDuration
					{
						lastTime <- round(lastTime - 1/((aS["PARAMGENERATION"] as float) * deltaT)*ln(1-rnd(1.0)));
						add lastTime::cpt to:tempArrivalTimes;
					}
				}
				else
				{
					float nbCreate <- (aS["PARAMGENERATION"] as float);
					
					loop while:nbCreate >0.00001
					{
						add 0::cpt to:tempArrivalTimes;
						nbCreate <- nbCreate -1;
					}
				}
				ArrivalTimes <- ArrivalTimes + tempArrivalTimes;
				
				cpt <- cpt +1;
		}
		
		
		//We need to sort arrival times because in the case where we have different type of agents, arrival are set for each type one after another
		ArrivalTimes <- ArrivalTimes sort_by each.key;
		
		
		number_of_people <- length(interactionPeople);
		nb_interactionPeople <- length(interactionPeople);
		pedMaxSpeed <- 7.0;
		
		nervousityDistribution <- list_with(12,0);
		
		
		loop while:cptArrival<length(ArrivalTimes)
		{
			create interactionPeople number:1 with:[spawnTime::int(ArrivalTimes[cptArrival].key),init_color::typeAgent[ArrivalTimes[cptArrival].value][0],pointAX::typeAgent[ArrivalTimes[cptArrival].value][2],pointAY::typeAgent[ArrivalTimes[cptArrival].value][3],pointBX::typeAgent[ArrivalTimes[cptArrival].value][4],pointBY::typeAgent[ArrivalTimes[cptArrival].value][5],lAim::typeAgent[ArrivalTimes[cptArrival].value][6]];
			cptArrival <- cptArrival + 1;
		}
		
		
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
		
		
		
		if !demonstrationMode
		{
			ask connection
			{
				do initTable;
				myself.id_simulation <- self.id_simulation;
			}
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
		if (cycle mod 1000 = 0)
		{
			write cycle;
		}
		
		//First we generate the agent for whom it's the arrival time
		do spawn;
		do count;

		ask interactionPeople {
			do activation;	
		}
		
		//Clean some variables
		ask interactionPeople {
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
			if isActive {
				do computeDistance;	
			}
		}
		
		//For each agent we set his neighbourhood in the interacton network
		ask interactionPeople parallel:true{
			if isActive {
				do setInteraction;	
			}
		}
		
		//Set the destination of the agent
		ask interactionPeople parallel:true{
			if isActive {
				do aim;
			}
		}
		
		//Count how many people have pass the strategic area
		ask interactionPeople 
		{
			if ((isActive) and (checkPassing = 1))
			{
				myself.peoplePass <- myself.peoplePass + 1;
				do checking;			
			}
			 
		}
		
		if realStartCycle = -1 and peoplePass > 0
		{
			realStartCycle <- cycle;
			if !demonstrationMode
			{
				ask connection
				{
					do insertRealStartTime(myself.realStartCycle);
				}
			}
		}
		
		
	
		//Compute the force system applying on every agent
		ask interactionPeople parallel:true{
			if isActive {
				do computeForce;
			}	
		}
		
		//With the force system, compute velocity and mouvement
		ask interactionPeople {
			if isActive {
				do computeVelocity;
				do mouvement;
			}
		}
		
		//Compute the nervousness transmit by the neighborhood
		ask interactionPeople parallel:true{
			do spreadNervousness;	
		}
		
		//Compute the inner nervousness
		ask interactionPeople parallel:true
		{
			if isActive {
				do computeNervousness;
			}
		}
		
		//Compose finla nervousnnes with inner and neighborhood
		if (isNervousnessTransmition)
		{
			ask interactionPeople parallel:true
			{
				if isActive {
					do computeNervousnessEmpathy;
				}
			}
		}
		
		ask interactionPeople parallel:true
			{
				if isActive {
					do setColor;
				}
			}
		
		ask field parallel:true {
			do reset;
		}
		
		//Mark the field
		ask interactionPeople
		{
			if isActive {
				do cellMark;	
			}
		}
		
		//Set color of each cells based on the nervousness
		ask field parallel:true{
			do setColor;
		}
		
		do setMax;
		
		do computeAverage;
		
		ask interactionPeople {
			do record;
		}
		
		if cycle = simulationDuration {
			do finalRecord;
			//write(""+ id_simulation + " is over at :" + date("now"));
			do halt ;
			do pause;
		} 	
		
		if !demonstrationMode and  cycle mod 200 = 0 and cycle > 0
		{
			ask connection
			{
				do recordAgentState;
			}
		}
		
		
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
			if isActive {
				count <- count +1;
				meanNervousness <- meanNervousness + nervousness;
			}
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
			if isActive {
				count <- count +1;
				averageSpeed <- averageSpeed+ norm(actual_velocity);
			}
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
			if isActive {
				count <- count +1;
				meanOrientedSpeed <- meanOrientedSpeed+ orientedSpeed;
			}
		}
		
		if count != 0
		{meanOrientedSpeed <- meanOrientedSpeed/count;}
	}
	
	reflex nervousPeople_count
	{
		nbNervoussPeople <- 0;
		
		ask interactionPeople
		{
			if(isActive and nervousness >= 0.5) {
				nbNervoussPeople <- nbNervoussPeople + 1;
			}
		}
	}
	
	
	//Init parameter
	action initParameter
	{
		fluctuationType <- parameter["FLUCTUATIONTYPE"];
		deltaT <- float(parameter["DELTAT"]);
		relaxation <- float(parameter["RELAXATIONTIME"]);
		isRespawn <- bool(parameter["ISRESPAWN"]);
		isFluctuation <- bool(parameter["ISFLUCTUATION"]);
		pedDesiredSpeed <- float(parameter["PEDESTRIANSPEED"]);
		pedMaxSpeed <- float(parameter["PEDESTRIANMAXSPEED"]);
		pedSizeMax <- float(parameter["PEDESTRIANMAXSIZE"]);
		pedSizeMin <- float(parameter["PEDESTRIANMINSIZE"]);
		simulationDuration <- int(parameter["SIMULATIONDURATION"]);
		intervalLength <- int(parameter["TEMPORALFIELDINTERVALLENGTH"]);
		interactionType <- parameter["INTERACTIONTYPE"];
		is360 <- bool(parameter["IS360"]);
		angleInteraction <- float(parameter["INTERACTIONANGLE"]);
		perceptionRange <- float(parameter["INTERACTIONRANGE"]);
		isNervousnessTransmition <- bool(parameter["ISNERVOUSNESSTRANSMITION"]);
		empathy <- float(parameter["INTERACTIONPARAMETER"]);
		spaceLength <- int(parameter["SPACELENGTH"]);
		spaceWidth <- int (parameter["SPACEWIDTH"]);
		Ai <- float(parameter["SOCIALFORCESTRENGTH"]);
		Bi <- float(parameter["SOCIALFORCETHRESHOLD"]);
		lambda <- float(parameter["SOCIALFORCEVISION"]);
		body <- float(parameter["BODYCONTACTSTRENGTH"]);
		friction <- float(parameter["BODYFRICTIONSTRENGTH"]);
		threshold <- float(parameter['THRESHOLD']);
	}
	
	//Spawn agents with the arrival time set on the initialisation
	action spawn
	{
		loop while:cptArrival<length(ArrivalTimes) and ArrivalTimes[cptArrival].key <= cycle
		{
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
	
	action finalRecord
	{
		if !demonstrationMode
		{
			ask connection
			{
				do finalRecord;
			}	
		}
	}
}

