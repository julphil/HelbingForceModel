/**
* Name: InteractionPeople
* Author: julien
* Description: Agents of this species are mobile agents interacting whith eachother to communicate emotion/information
*/

model InteractionPeople

import "PanicPeople.gaml"
import "../../Parameter/InteractionParameter.gaml"
import "../../Entity/Node.gaml"

species interactionPeople parent:panicPeople
{
	rgb d_color;
	rgb n_color;
	float neighbourNervoussness; //Nervousness transmit by interacting neighbours
	int nbNeighbour; 
	float lastNervousness; //For the transmition, we always use the total nervousness (inner + neighbours) of the last instant, to avoid problème of order
	float innerNervousness;
	
	list<int> nervousityDistributionMark; //Use to know the repartition of nervous people in the spce
 
 	//Interaction agents
 	list<interactionPeople> interaction;
 	
 	//Var use to know if the agent pass the strategic area : 0 if not, 2 if yes, and 1 to indicated that he pass but the global agent didn't count it yet 
 	int verifPassing <- 0;
 	
 	graphNode currentNode;
 	
 	
 	bool isActive <- false;
 	int spawnTime;
 	
 	list<list> recordData;
 	
	init
	{
		color <- #white;
		
		nervousityDistributionMark <- list_with(12,0);
		
		location <- {-1000,-10000};
		
	}

	action activation {
		if spawnTime = cycle {
			isActive <- true;
			n_color <- d_color;
			location <- { rnd(pointAX,pointBX), rnd(pointAY,pointBY) };
		}
	}
	
	action record {
		add [location.x,location.y,nervousness,isActive] to:recordData;
	}

	//Set contener variables empty
	action resetStepValue
	{
		matDistances <- nil as_matrix({nb_interactionPeople,1});
		interaction <- [];
	}
	
	//Calculate all distance between this agent and all other agents
	action computeDistance
	{	
		ask interactionPeople parallel:true 
		{
			if isActive {
				if self != myself and int(self) < length(myself.matDistances)
				{
					if(matDistances[int(myself),0] != nil) //If the other agent has already done the calculus,  we take his result
					{
						myself.matDistances[int(self),0] <- matDistances[int(myself),0];
					} else {
						myself.matDistances[int(self),0] <-  norm({ myself.location.x - self.location.x, myself.location.y - self.location.y });
					}
				} else if int(self) > length(myself.matDistances) //The case is not suppose to happend, if it happend, it's a bug
				{
					//write location;
				}
			} else
			{
				
			}
		}
		
	}
	
	//Determine which other agents are in the range of interaction, all agents in the range is add to a list 
	action setInteraction
	{
		ask interactionPeople 
		{
			if isActive and self != myself
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
			if isActive and self != myself
			{
				
				float distanceCenter <- matDistances[int(myself),0];
				
				//If agents are too far away  forces are negligible, so it's more optimized to not compute it
				if distanceCenter < calculRange
				{
					float distance <- distanceCenter -(self.size+myself.size);
					
					point nij <- { (myself.location.x - self.location.x) / (distanceCenter+epsilon), (myself.location.y - self.location.y) / (distanceCenter+epsilon) };
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
		}
		
		people_forces <- {social_repulsion_force.x+physical_repulsion_force.x + physical_tangencial_force.x,social_repulsion_force.y+physical_repulsion_force.y + physical_tangencial_force.y};
	}
	
	//Compute the nervousness neighbours transmit to the agent
	action spreadNervousness
	{
		neighbourNervoussness <- 0.0;
		nbNeighbour <- 0;
		
		if( !empty(interaction))
		{
			if interaction contains nil
				{
					remove nil all:true  from: interaction; 	
				}
			
			if 	interactionType = "Mean"
			{
				int le <- length(interaction);
				
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
			else if interactionPeople = "Closest"
			{
				interactionPeople closest <- interaction[0];
				float dist <- matDistances[int(closest),0];
				
				loop p over:interaction
				{
					if !dead(p) and float(matDistances[int(p),0]) < dist
					{
						closest <- p;
						dist <- matDistances[int(closest),0];
					}
				}
				
				neighbourNervoussness <- closest.lastNervousness;
				nbNeighbour <- 1;
			}		
		}
}
	
	//Set the color of the agent based on nervousness value
	action setColor
	{
		color <- rgb(255*nervousness,255-255*nervousness,0.0);
	}
	
	//Set the total value of nervousness with a compromise between the agent inner nervousness and his neighbours's blanced with a empathy coefficient
	action computeNervousnessEmpathy
	{
			if nbNeighbour > 0 {
				innerNervousness <- nervousness;
				nervousness <- (1-empathy)*nervousness + empathy*neighbourNervoussness;
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
	
	//Check if the agent is out. If it the case, dependant if respawn is actived or not, it delte the agent or replace it 
	action sortie
	{
		if isRespawn 
		{
			
			if location.x >= spaceLength and group = 1
			{
				location <- { 0, location.y};
			} else if location.x <= 0 and group = 0
			{
				location <- { spaceLength, location.y};
			}
		}
		else if ((location.x >= spaceLength) or (location.x <= 0)) and indexAim = length(lAim)-1
		{
			do unactivate;
		}
		
		if location.y < 0 
		{
			location <- {location.x, 0.0};
			presenceTime <- 0;
			cumuledOrientedSpeed <- 0.0;
		} else if location.y > spaceWidth 
		{
			location <- {location.x,spaceWidth};
			presenceTime <- 0;
			cumuledOrientedSpeed <- 0.0;
		}

	}
	
	action unactivate
	{
		isActive <- false;
		location <- {-1000,-1000};
		
	}
	
	//The agent mark the cell (in the nervousnees field) he is on with his nervousness
	action cellMark {
		ask field[(self.location.x) as int,(self.location.y) as int]
		{
			do addAgent(myself);
		}
	}
	
	//This aspect his made to visulazed interaction
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

//This grid represent the nervousness field, it allows us to survey nervousness propagation 
grid field width:spaceLength height:spaceWidth {
	list<interactionPeople> insider; //People inside the cell
	bool isWall; //If this cell is occupied by a wall, the nervousness is nul
	//3 color, one for instant, other for the interval we choose and the last is the average nervousness along the simulation 
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
	
	int cptCharge;//Use to reset the value when the current interval is over and a new one begin
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
	
		//A cell whitout agent (so without nervousness within) must be white, when cells with agent but with a value of nervousness of 0.0 are blue	
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
	
	//if an agent is in this cell, he must be add to the list
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