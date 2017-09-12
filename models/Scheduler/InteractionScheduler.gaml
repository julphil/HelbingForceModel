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
	
	//Simulation survey
	int nb_interactionPeople <- number_of_people;
	list<rgb> lcolor;
	matrix data;
	float meanNervousness;
	float averageSpeed;
	float meanOrientedSpeed;
	int nbNervoussPeople;
	
	int peopleOut;
	
	list<int> nervousityDistribution;
	
	list<list> typeAgent;
	list<pair<int,int>> ArrivalTimes;
	int cptArrival <- 0;
	
	//maxValue <cycle,value>
	pair<int,int> maxNervousPeople <- -1::0;
	pair<int,float> maxNervousness <- -1::0.0;
	pair<int,int> maxPeopleIn <- -1::0;
	pair<int,pair<float,float>> maxSpeed <- -1::(0.0::0.0);
	pair<int,pair<float,float>> maxOrientedSpeed <- -1::(0.0::0.0);
	pair<int,float> maxSpeedDifference <- -1::0.0;
	matrix<float> nervousnessMap;
	matrix<float> cumuledNervousnessMap;
	matrix<float> temporalNervousnessMap;
	
	
	//Agent creation
	init
	{	
		file dataFile <- csv_file(dataFileName,",");
		data <- matrix(dataFile);
		
		int cpt <- 0;
		loop i from:0 to:data.rows-1
		{
			if data[0,i] = "agent" {
				list<pair<point>> listAim;
				loop index from:7  to:data.columns-4 step:4 {
					add {data[index,i] as float,data[index+1,i] as float}::{data[index+2,i] as float,data[index+3,i] as float} to:listAim;
				}
				
				create interactionPeople number:1 with:[init_color::data[1,i],pointAX::data[3,i],pointAY::data[4,i],pointBX::data[5,i],pointBY::data[6,i],lAim::listAim];
				
				add [data[1,i],data[2,i],data[3,i],data[4,i],data[5,i],data[6,i],listAim]  to:typeAgent;
				
				list<pair<int,int>> tempArrivalTimes;
				int lastTime <- 0;
				
				loop while:lastTime<simulationDuration
				{
					lastTime <- round(lastTime - 1/((data[2,i] as float) * deltaT)*ln(1-rnd(1.0)));
					add lastTime::cpt to:tempArrivalTimes;
				}
				ArrivalTimes <- ArrivalTimes + tempArrivalTimes;
				
				cpt <- cpt +1;
				
			} else if data[0,i] = "wall" {
				create wall with:[locationX::data[1,i],locationY::data[2,i],length::data[3,i],width::data[4,i]];
			} 
		}
		
		ArrivalTimes <- ArrivalTimes sort_by each.key;
		
		
		number_of_people <- length(interactionPeople);
		nb_interactionPeople <- length(interactionPeople);
		pedMaxSpeed <- 7.0;
		
		nervousityDistribution <- list_with(12,0);
		
		outFileData <- "cycle,number of peoples,Average nervousness,number of nervous peoples,average speed,average speed in the goal direction";
		save outFileData to:outputFileName +".csv" rewrite:true;	
		
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
		
		nervousnessMap <- matrix_with({spaceLength,spaceWidth},0.0);
		cumuledNervousnessMap <- matrix_with({spaceLength,spaceWidth},0.0);
		temporalNervousnessMap <- matrix_with({spaceLength,spaceWidth},0.0);
		
		calculRange <- calculRange + pedSizeMin*2;
	}
	
	action count
	{
		
		nb_interactionPeople <- length(interactionPeople);
		
	}
	
	reflex count
	{
		do count;
	}
	
	reflex scheduler
	{	
		do spawn;
		do count;

		ask interactionPeople{
			do resetStepValue;
		}
		
		ask interactionPeople{
			do sortie;
		}
		int nb_interactionPeopleTMP <- nb_interactionPeople;
		do count;
		peopleOut <- peopleOut + (nb_interactionPeopleTMP - nb_interactionPeople);
		
		ask interactionPeople parallel:true
		{
			do computeDistance;
		}
		
		ask interactionPeople parallel:true{
			do setInteraction;
		}
		
		ask interactionPeople parallel:true{
			do aim;
		}
	
		ask interactionPeople parallel:true{
			do computeForce;	
		}
		
		ask interactionPeople {
			do computeVelocity;
			do mouvement;
		}
		
		ask interactionPeople parallel:true{
			do spreadNervousness;	
		}
		
		ask interactionPeople parallel:true
		{
			do computeNervousness;
			
		}
		
		if (isNervousnessTransmition)
		{
			ask interactionPeople parallel:true
			{
				do computeNervousnessEmpathy;
				do setColor;
			}
		}
		
		nervousityDistribution <- list_with(12,0);
		
		ask interactionPeople parallel:true
		{
			do nervousnessMark;
		}
		
		ask interactionPeople
		{
			loop i from:0 to:length(nervousityDistributionMark)-1 {
				nervousityDistribution[i] <- nervousityDistribution[i] + nervousityDistributionMark[i]; 
			}
		}
		
		ask field parallel:true {
			do reset;
		}
		
		ask interactionPeople
		{
			do cellMark;
		}
		
		ask field parallel:true{
			do setColor;
		}
		
		do setMax;
		
		do saveData;
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
			
			
			save outFileData to:outputFileName +".csv" rewrite:false;
			
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
}

