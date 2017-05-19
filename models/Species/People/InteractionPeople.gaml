/**
* Name: InteractionPeople
* Author: julien
* Description: 
* Tags: Tag1, Tag2, TagN
*/

model InteractionPeople

import "PanicPeople.gaml"
import "../../Parameter/InteractionParameter.gaml"

species interactionPeople parent:panicPeople
{

	rgb n_color;
	float neighbourNervoussness;
	int nbNeighbour;
 
 	//Interaction agent
 	list<interactionPeople> interaction;
 	
	init
	{
		n_color <- d_color;
	}

	action resetStepValue
	{
		matDistances <- nil as_matrix({number_of_people,1});
		interaction <- [];
	}
	
	action computeDistance
	{	
		ask interactionPeople parallel:true 
		{
			if self != myself
			{
				if(matDistances[int(myself),0] != nil)
				{
					myself.matDistances[int(self),0] <- matDistances[int(myself),0];
				} else {
					myself.matDistances[int(self),0] <-  norm({ myself.location.x - self.location.x, myself.location.y - self.location.y });
				}
			}
		}
		
	}
	
	action setInteraction
	{
		ask interactionPeople 
		{
			if ((perceptionRange < 0.0 or float(matDistances[int(myself),0]) < perceptionRange) )
				{
					add self to: myself.interaction;
				}
		}
	}

	//Force functions
	//Social repulsion force + physical interaction force
	action people_repulsion_force_function
	{
		point social_repulsion_force <- { 0.0, 0.0 };
		point physical_repulsion_force  <- { 0.0, 0.0 };
		point physical_tangencial_force  <- { 0.0, 0.0 };
		
		people_forces <- {0.0, 0.0};
		
		ask interactionPeople parallel:true
		{
			if self != myself
			{
				
				float distanceCenter <- matDistances[int(myself),0];
				if distanceCenter = 0 {
					write "" + name + matDistances;
					write myself.name;
					write "";
				}
				
				float distance <- distanceCenter -(self.size+myself.size);
				point nij <- { (myself.location.x - self.location.x) / distanceCenter, (myself.location.y - self.location.y) / distanceCenter };
				//float phiij <- -nij.x * actual_velocity.x / (norm(actual_velocity) + 0.0000001) + -nij.y * actual_velocity.x / (norm(actual_velocity) + 0.0000001);
				float phiij <- -nij.x * desired_direction.x + -nij.y * desired_direction.y;
				float vision <- (lambda + (1 - lambda) * (1 + phiij) / 2);
				float repulsion <- Ai * exp(-distance / Bi);
				
				//Social force
				social_repulsion_force <- {
				social_repulsion_force.x + (repulsion * nij.x * vision), social_repulsion_force.y + (repulsion * nij.y *vision)
				};
				
				//Physical force
				if (distance <= size)
				{
					float theta;
					
					if (-distance <= 0.0) { //If there is no contact
						theta <- 0.0;
					} else {
						theta <- -distance;
					}
	
					point tij <- {-nij.y,nij.x};
					
					float deltaVitesseTangencielle <- 
						(actual_velocity.x - myself.actual_velocity.x)*tij.x + (actual_velocity.y - myself.actual_velocity.y)*tij.y;
					
					physical_repulsion_force <- {
						physical_repulsion_force.x + body * theta * nij.x,
						physical_repulsion_force.y + body * theta * nij.y
					};
					
					physical_tangencial_force <- {
						physical_tangencial_force.x + friction * theta * deltaVitesseTangencielle * tij.x,
						physical_tangencial_force.y + friction * theta * deltaVitesseTangencielle * tij.y
					};
				}
			}
		}

		people_forces <- {social_repulsion_force.x+physical_repulsion_force.x + physical_tangencial_force.x,social_repulsion_force.y+physical_repulsion_force.y + physical_tangencial_force.y};
	}
	
	action colorChoice
	{
		neighbourNervoussness <- 0.0;
		
		if( !empty(interaction) //and ( 
//			(stateChangingType = "Random based on nervousness" and (rnd(1000) / 1000)< nervousness) or
//			(stateChangingType = "Pure random" and (rnd(1000) / 1000)> stateChangingThreshold) or
//			(stateChangingType = "Nervousness threshold" and nervousness > stateChangingThreshold)
			//)
		)
		{
			if interactionType = "One neighbour"
			{
				//One neighbour
				interactionPeople neighbour<- nil;
				if neighbourType = "Closest"
				{
					neighbour <- interaction closest_to self;				
				} else
				{
					neighbour <- one_of(interaction);
				}
				
				
				if neighbour != nil
				{
					n_color <- neighbour.color;
					neighbourNervoussness <- neighbour.nervousness;
					nbNeighbour <- 1;
				}
			}
			else if interactionType = "Majority"
			{
				map<rgb,int> colors;
				
				if interaction contains nil
				{
					remove nil all:true  from: interaction; 	
				}
				
				//Majority
				loop p over:interaction {
					if !dead(p)
					{
						rgb c <- p.color;
						if(colors contains c){
							put colors[c]+1 at:c in:colors;
						}
						else
						{
							add c::1 to:colors;
						}
					}
				}
				
				pair<rgb,int> max <- nil;
				
				loop c over:colors.keys{
					int value <- colors[c];
					if max = nil or value > max.value
					{
						max <- c::value;
					}
				}
				
				if max.key != nil
				{
					n_color <- max.key;
				}
			}
			else if 	interactionType = "Mean"
			{
				int r <-0;
				int g <-0;
				int b <-0;
				int le <- length(interaction);
				
				if interaction contains nil
				{
					remove nil all:true  from: interaction; 	
				}
				
				loop p over:interaction {
					if !dead(p)
					{
//						r <- r+ p.color.red;
//						g <- g+ p.color.green;
//						b <- b+ p.color.blue;
						neighbourNervoussness <- neighbourNervoussness + p.nervousness;
					}
				}
				
//				n_color <- rgb(r/le,g/le,b/le);
				neighbourNervoussness <- neighbourNervoussness/(le+epsilon);
				nbNeighbour <- le;
				
			}		
		}
}
	
	action colorPropagation
	{
//		color <- n_color;
		color <- rgb(255*nervousness,0.0,0.0);
	}
	
	action computeNervousnessEmpathy
	{
		nervousness <- (nervousness + neighbourNervoussness*nbNeighbour)/(nbNeighbour+1);
	}

}
