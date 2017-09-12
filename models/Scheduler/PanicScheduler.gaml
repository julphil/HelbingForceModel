/**
* Name: PanicScheduler
* Author: julien
* Description: 
* Tags: Tag1, Tag2, TagN
*/

model PanicScheduler

import "../Species/People/PanicPeople.gaml"

global
{
	
	//Simulation survey
	int nb_panicPeople <- number_of_people;
	
	//Agent creation
	init
	{
		file dataFile <- csv_file(dataFileName,",");
		matrix data <- matrix(dataFile);
		
		loop i from:0 to:data.rows-1
		{
			if data[0,i] = "agent" {
				list<pair<point>> listAim;
				loop index from:7  to:data.columns-4 step:4 {
					add {data[index,i] as float,data[index+1,i] as float}::{data[index+2,i] as float,data[index+3,i] as float} to:listAim;
				}
				
				create panicPeople number:data[2,i] with:[init_color::data[1,i],pointAX::data[3,i],pointAY::data[4,i],pointBX::data[5,i],pointBY::data[6,i],lAim::listAim];
			} else if data[0,i] = "wall" {
				create wall with:[locationX::data[1,i],locationY::data[2,i],length::data[3,i],width::data[4,i]];
			} 
		}
		
		
		number_of_people <- length(panicPeople);
		nb_panicPeople <- length(panicPeople);
		
//		pedMaxSpeed <- pedDesiredSpeed*1.3;
		pedMaxSpeed <- 7.0;
		
	}
	
	reflex count
	{
		nb_panicPeople <- length(panicPeople);
	}
	
	reflex scheduler
	{
		ask panicPeople parallel:true{
			do resetStepValue;
		}
		
		ask panicPeople parallel:true{
			do sortie;
		}
		
		ask panicPeople parallel:true{
			do computeDistance;
		}
		
		ask panicPeople parallel:true{
			do aim;	
		}
			
		ask panicPeople parallel:true{
			do computeForce;
		}
		ask panicPeople {
			do computeVelocity;
			do mouvement;
		}
		ask panicPeople parallel:true{
			do computeNervousness;
		}
	}
	
	//If agents does not respawn, pause the simulation at the time they're  no more agent in the simulation
	reflex stopIt when:nb_panicPeople <= 0 {
		if lastCycle = -1
		{
			lastCycle <- cycle;
		}
		do pause;
	}
}