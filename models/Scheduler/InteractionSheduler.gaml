/**
* Name: InteractionEscapeCrowdSheduler
* Author: julien
* Description: 
* Tags: Tag1, Tag2, TagN
*/

model InteractionEscapeCrowdSheduler

import "../Species/People/InteractionPeople.gaml"

global
{
	
	//Simulation survey
	int nb_interactionPeople <- number_of_people;
	list<rgb> lcolor;
	
	
	//Agent creation
	init
	{
//		pedMaxSpeed <- pedDesiredSpeed*1.3;
		pedMaxSpeed <- 7.0;
		
		create interactionPeople number: number_of_people;
		if bottleneckSize <= spaceWidth {
			create wall number: number_of_walls;
			} else {
			create wall number: number_of_walls-2;	
		}
	}
	
	reflex count
	{
		nb_interactionPeople <- length(interactionPeople);
	}
	
	reflex scheduler
	{
		ask interactionPeople parallel:true{
			do sortie;
		}
		
		ask interactionPeople parallel:true{
			do interactionClean;
			do aim;	
			do computeVelocity;
			
		}
		ask interactionPeople {
			do mouvement;
		}
		ask interactionPeople parallel:true{
			do computeNervousness;
		}
		ask interactionPeople parallel:true
		{
			do colorChoice;
		}
		ask interactionPeople parallel:true{
			do colorPropagation;
		}
		lcolor <- [];
		ask interactionPeople
		{
			if !(lcolor contains self.color)
			{
				add self.color to: lcolor;
			}
		} 
	}
	
	//If agents does not respawn, pause the simulation at the time they're  no more agent in the simulation
	reflex stopIt when:nb_interactionPeople <= 0 {
		if headless {do halt;}
		do pause;
	}
}

