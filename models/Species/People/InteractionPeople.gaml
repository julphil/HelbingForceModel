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
	rgb d_color;
	rgb n_color;
	float neighbourNervoussness;
	int nbNeighbour;
	
	list<int> nervousityDistributionMark;
 
 	//Interaction agent
 	list<interactionPeople> interaction;
 	
	init
	{
		n_color <- d_color;
		
		nervousityDistributionMark <- list_with(12,0);
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
			if self != myself and int(self) < length(myself.matDistances)
			{
				//if int(self) > length(myself.matDistances) {write "" + cycle + " " + name + " " + length(matDistances) + " " + length(myself.matDistances);}
				if(matDistances[int(myself),0] != nil)
				{
					myself.matDistances[int(self),0] <- matDistances[int(myself),0];
				} else {
					myself.matDistances[int(self),0] <-  norm({ myself.location.x - self.location.x, myself.location.y - self.location.y });
				}
			} else if int(self) > length(myself.matDistances)
			{
				write location;
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
		
		if( !empty(interaction) and ( 
			(stateChangingType = "Always") or
			(stateChangingType = "Random based on nervousness" and (rnd(1000) / 1000)< nervousness) or
			(stateChangingType = "Pure random" and (rnd(1000) / 1000)> stateChangingThreshold) or
			(stateChangingType = "Nervousness threshold" and nervousness > stateChangingThreshold)
			)
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
		color <- rgb(255*nervousness,255-255*nervousness,0.0);
	}
	
	action computeNervousnessEmpathy
	{
		nervousness <- (nervousness + neighbourNervoussness*nbNeighbour)/(nbNeighbour+1);
	}
	
	action nervousnessMark
	{
		if nervousness > 0.5 and location.x>=0
		{
			int index <- int(location.x/5);
			
			if index < length(nervousityDistributionMark) and nervousityDistributionMark[index] = 0
			{
				nervousityDistributionMark[index] <- 1;
			}
		}
	}
	
	action validMark
	{
		loop i from: 0 to: length(nervousityDistributionMark)-1{
			if nervousityDistributionMark[i] = 1 {
				nervousityDistributionMark[i] <- 2;
			}
		}
	}
	
	action cellMark {
		ask field[(self.location.x) as int,(self.location.y) as int]
		{
			do addAgent(myself);
		}
	}
	
	aspect graph
	{
		float rayon <- number_of_people/(2*#pi);
		
		draw circle(size) color: color at:{spaceLength/2+rayon*cos(((360)/number_of_people)*int(self)),spaceWidth/2+rayon*sin(((360)/number_of_people)*int(self))};
	
		if interaction contains nil
		{
			remove nil all:true  from: interaction; 	
		}
				
		loop p over:interaction {
			if !dead(p)
			{
				draw line([{spaceLength/2+rayon*cos(((360)/number_of_people)*int(self)),spaceWidth/2+rayon*sin(((360)/number_of_people)*int(self))},{spaceLength/2+rayon*cos(((360)/number_of_people)*int(p)),spaceWidth/2+rayon*sin(((360)/number_of_people)*int(p))}]) color:#red;	
			}
		}
	}

}

grid field width:spaceLength height:spaceWidth {
	list<interactionPeople> insider;
	bool isWall;
	rgb cellColor;
	float nerv;
	
	init {
		insider <- [];
		do setColor;
		nerv <- 0.0;
	}
	
	action reset 
	{
		insider <- [];
		nerv <- 0.0;
	}
	
	action addAgent(agent a) {
		add a as interactionPeople to:insider;
	}
	
	action setColor
	{
		if isWall
		{
			cellColor <- #black;
		}
		else {
			if length(insider) = 0 {
	       		cellColor <- #white;
	       	}
	        else {
	    		loop a over:insider
	    		{
	    			nerv <- nerv + a.nervousness;
	    		}
	    		
	    		nerv <- nerv/length(insider);
	    		
	    		cellColor <- rgb(255*nerv,0.0,255-255*nerv);
	        }
	       }
	}
	
	aspect aspectNervousness 
	{
	        	draw square(1) color:cellColor;
	}
	        	
}