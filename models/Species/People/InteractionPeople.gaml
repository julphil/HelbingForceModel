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
	float lastNervousness;
	
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
			if self != myself
			{
				float distanceCenter <- matDistances[int(myself),0];
					
					float distance <- distanceCenter -(self.size+myself.size);
					point nij <- { (myself.location.x - self.location.x) / (distanceCenter+epsilon), (myself.location.y - self.location.y) / (distanceCenter+epsilon) };
					float phiij <- -nij.x * desired_direction.x + -nij.y * desired_direction.y;
				
				if ((perceptionRange < 0.0 or float(matDistances[int(myself),0]) < perceptionRange) and (is360 or (acos(phiij) < angleInteraction and acos(phiij) > -angleInteraction) or acos(phiij) > 360-angleInteraction) )
					{
						add self to: myself.interaction;
					}
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
				point nij <- { (myself.location.x - self.location.x) / (distanceCenter+epsilon), (myself.location.y - self.location.y) / (distanceCenter+epsilon) };
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
		nbNeighbour <- 0;
		
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
			else if 	interactionType = "Mean"
			{
				int le <- length(interaction);
				
				if interaction contains nil
				{
					remove nil all:true  from: interaction; 	
				}
				
				loop p over:interaction {
					if !dead(p)
					{
						neighbourNervoussness <- neighbourNervoussness + p.lastNervousness;
					}
				}
				neighbourNervoussness <- neighbourNervoussness/(le+epsilon);
				nbNeighbour <- le;
				
			}
			else if interactionType = "Maximum"
			{
				float max <- 0.0;

				if interaction contains nil
				{
					remove nil all:true  from: interaction; 	
				}
				
				loop p over:interaction {
					if !dead(p) and p.nervousness > max
					{
						max <- p.lastNervousness;
					}
				}

				neighbourNervoussness <- max;
				nbNeighbour <- length(interaction);
			}
			else if interactionType = "BiasedFortuneWheel"
			{
				if interaction contains nil
				{
					remove nil all:true  from: interaction; 	
				}
				
				float lastProb <- 0.0;
				nbNeighbour <- length(interaction);
				
				list<pair<float,float>> wheel;
				
				loop p over:interaction {
					if !dead(p)
					{
						lastProb <- lastProb + (abs(nervousness-p.lastNervousness))/nbNeighbour;
						add lastProb::p.lastNervousness to:wheel;
					}
				}
				
				bool continue <- nbNeighbour > 0;
				float random <- rnd(1.0);
				int index <- 0;
				
				loop while:continue
				{
					if (wheel[index].key > random)
					{
						continue <- false;
						neighbourNervoussness <- wheel[index].value;
					}
					else {
						index <- index + 1;
						
						if index >= nbNeighbour
						{
							continue <- false;
							neighbourNervoussness <- nervousness;
						}
					}
				}
			}		
		}
}
	
	action colorPropagation
	{
		color <- rgb(255*nervousness,255-255*nervousness,0.0);
	}
	
	action computeNervousnessEmpathy
	{
		if 	interactionType = "Mean"
		{
			nervousness <- (nervousness + neighbourNervoussness*nbNeighbour)/(nbNeighbour+1);
		}
		else if interactionType = "Maximum" or interactionType = "BiasedFortuneWheel"
		{
			if nbNeighbour > 0 {
				nervousness <- (1-empathy)*nervousness + empathy*neighbourNervoussness;
			}
			
		}
		lastNervousness <- nervousness;
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
	rgb cellColorTotal;
	rgb cellColorTemporal;
	
	float instantAverageNerv;
	float instantCumuledNerv;
	float totalAverageNerv;
	float totalCumuledNerv;
	float totalCumuledAverageNerv;
	float temporalNerv;
	float chargeNerv;
	
	int cptCharge;
	int cptActiv;
	
	int nbCycle;
	
	init {
		insider <- [];
		
		instantAverageNerv <- 0.0;
		instantCumuledNerv <- 0.0;
		totalAverageNerv <- 0.0;
		totalCumuledNerv <- 0.0;
		totalCumuledAverageNerv <- 0.0;
		
		temporalNerv <- 0.0;
		chargeNerv <- 0.0;
	
		cptCharge <- -2;
		cptActiv <- 0;
		
		do setColor;
		
		cellColor <- #white;
		cellColorTotal <- #white;	
		cellColorTemporal <- #white;
	}
	
	action reset 
	{
		insider <- [];
		instantAverageNerv <- 0.0;
		instantCumuledNerv <- 0.0;
	}
	
	action addAgent(agent a) {
		add a as interactionPeople to:insider;
	}
	
	action setColor
	{
		if isWall
		{
			cellColor <- #black;
			cellColorTotal <- #black;
			cellColorTemporal <- #black;
			instantAverageNerv <- -1.0;
			instantCumuledNerv <- -1.0;
			totalAverageNerv <- -1.0;
			totalCumuledNerv <- -1.0;
			totalCumuledAverageNerv <- -1.00;
		}
		else {
			if cptCharge >= intervalLength
			{
				cptCharge <- 0;
				cptActiv <- 0;
				chargeNerv <- 0.0;
			}
			
			cptCharge <- cptCharge + 1;
			
			if length(insider) = 0 {
	       		cellColor <- #white;
	       	}
	        else {
	        	cptActiv <- cptActiv + 1;
	        	
	        	nbCycle <- nbCycle +1;
	        	
	    		loop a over:insider
	    		{
	    			instantCumuledNerv <-instantCumuledNerv + a.nervousness;
	    		}
	    		
	    		instantAverageNerv <- instantCumuledNerv/length(insider);
	    		totalCumuledNerv <- totalCumuledNerv + instantCumuledNerv;
	    		
	    		totalCumuledAverageNerv <- totalCumuledAverageNerv + instantAverageNerv;
	    		
	    		totalAverageNerv <- totalCumuledAverageNerv/nbCycle;
	    		
	    		chargeNerv <- chargeNerv + instantAverageNerv;
	    		
	    		cellColor <- rgb(255*instantAverageNerv,0.0,255-255*instantAverageNerv);
	    		cellColorTotal <- rgb(255*totalAverageNerv,0.0,255-255*totalAverageNerv);
	        }
	        if cptCharge >= intervalLength
			{
				if cptActiv > 0 
				{
					temporalNerv <- chargeNerv/cptActiv;
					cellColorTemporal <- rgb(255*temporalNerv,0.0,255-255*temporalNerv);
				}
				else
				{ 
					cellColorTemporal <- #white;
				}
			}
	        
	       }
	}
	
	aspect aspectNervousness 
	{
	        	draw square(1) color:cellColor;
	}
	
	aspect aspectNervousnessTotal
	{
		draw square(1) color:cellColorTotal;
	}
	
	aspect aspectNervousnessTemporal
	{
		draw square(1) color:cellColorTemporal;
	}
	        	
}