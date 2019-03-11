/**
* Name: InteractionPeople
* Author: julien
* Description: Agents of this species are mobile agents interacting whith eachother to communicate emotion/information
*/

model InteractionPeople

import "../Wall/BaseWall.gaml"
import "../../Parameter/InteractionParameter.gaml"

species interactionPeople
{
	//////////////////////BASE PEOPLE
	string init_color;
	rgb color;
	
	float size;
	int group;
	float mass min:1.0 max:120.0 <- 80.0;
	
	//Creation location
	float pointAX;
	float pointAY;
	float pointBX;
	float pointBY;

	// Destination
	list<pair<point>> lAim;
	int indexAim <- 0;
	geometry aimZone;
	point aim;
	point desired_direction;
	float desired_speed;
	point actual_velocity <- { 0.0, 0, 0 };
	float max_velocity;
    
    //Use to compute the average speed
    float lastDistanceToAim;
    float orientedSpeed;
    float cumuledOrientedSpeed;
    list<float> lOrientedSpeed;
    int presenceTime <- 0;
    int spawnTime;
    
    //Goal attraction force
	point goal_attraction_force <- {0.0,0.0};

	//Compute forces
	point people_forces <- {0.0,0.0};
	point wall_forces <- {0.0,0.0};
	
	//Distance withall other agent
	matrix matDistances;
	
	int checkPassing <- 0;
	
	//////////////////////PANIC PEOPLE
	float nervousness <- 0.0;
	
	//Fluctuations
    point normal_fluctuation;
    point maximum_fluctuation;
    
	point fluctuation_forces <- {0.0,0.0};
 
 
	//////////////////////INTERACTION PEOPLE
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

 	
 	bool isActive <- false;
 	bool wasActive  <- false;
 	
 	list<list> recordData;
 	list<float> recordDataTemp;
 	
 	list<list> recordNetwork;
 	
 	int cptRecord <- 0;
 	
	init
	{
		/////////////////////BASE PEOPLE
		self.size <- rnd(pedSizeMin,pedSizeMax);
		self.desired_speed <- pedDesiredSpeed;
		max_velocity <- 1.3 * desired_speed;
		
		shape <- circle(size);
			
		location <- { rnd(pointAX,pointBX), rnd(pointAY,pointBY) };
		if (number_of_people > 1)
		{
			loop while:( agent_closest_to(self).location distance_to self.location < size*2){
				location <- { rnd(pointAX,pointBX), rnd(pointAY,pointBY) };
			}
		}
		
		aimZone <- polygon([lAim[indexAim].key as point,{(lAim[indexAim].key as point).x,lAim[indexAim].value.y},lAim[indexAim].value,{lAim[indexAim].value.x,(lAim[indexAim].key as point).y}]);
		
		if init_color = "rnd"
		{	
			color <- rnd_color(255);
		}
		else
		{
			color <-init_color as rgb;
		}
		
		do aim;
		
		actual_velocity <- {desired_speed * desired_direction.x,desired_speed * desired_direction.y};
		
		
		//////////////////////PANIC PEOPLE
		//Initilasation of the noise
		normal_fluctuation <- { gauss(0,0.01),gauss(0,0.01)};
		maximum_fluctuation <- {0,0};
              
		loop while:(norm(maximum_fluctuation) < norm(normal_fluctuation))
		{
	   		maximum_fluctuation <- { gauss(0,desired_speed*2.6),gauss(0,desired_speed*2.6)};    
		}
		
		//////////////////////INTERACTION PEOPLE
		color <- #white;
		
		nervousityDistributionMark <- list_with(12,0);
		
		location <- {-1000,-10000};
		
		recordDataTemp <- [0.0,0.0,0.0,0.0,0.0];
		
	}



	//Choose the destination point
	action aim
	{
		if location.x>(lAim[indexAim].key as point).x and location.x<lAim[indexAim].value.x and location.y>(lAim[indexAim].key as point).y and location.y<lAim[indexAim].value.y
		{
			indexAim <- indexAim+1;
			if checkPassing = 0 and indexAim > indexPassing
			{
				checkPassing <- 1;	
			}
			
			if indexAim >= length(lAim)
			{
				nbPeopleOut <- nbPeopleOut +1;
				do die;
			}
			
			aimZone <- polygon([lAim[indexAim].key as point,{(lAim[indexAim].key as point).x,lAim[indexAim].value.y},lAim[indexAim].value,{lAim[indexAim].value.x,(lAim[indexAim].key as point).y}]);
		}
		
		aim <-  closest_points_with(location,aimZone)[1];
		
		//update the goal direction
		float norme <- sqrt((aim.x - location.x) * (aim.x - location.x) + (aim.y - location.y) * (aim.y - location.y));
		desired_direction <- { (aim.x - location.x) / (norme + epsilon), (aim.y - location.y) / (norme + epsilon) };
				
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
	
	//Force functions
	action computeForce
	{
		//Compute forces
		do  people_repulsion_force_function;
		do wall_repulsion_force_function;
		do fluctuation_term_function;
	}

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

	//Wall dodge  force + physical interaction force
	action wall_repulsion_force_function 
	{
		wall_forces <- { 0.0, 0.0 };
		ask wall parallel:true
		{
			if (self != myself)
			{
				point wallClosestPoint <- closest_points_with(myself.location ,self.shape.contour)[1];
				float distance <- norm({ myself.location.x - wallClosestPoint.x, myself.location.y - wallClosestPoint.y })-myself.size;
				
				point nij <- { (myself.location.x - wallClosestPoint.x) / (distance+myself.size+epsilon), (myself.location.y - wallClosestPoint.y) / (distance+myself.size+epsilon)};
				
				
				float theta;
				
				if (distance <= 0.0 or myself.location overlaps self or self overlaps myself.location) { //if there is a contact
					theta <- -distance;

					if(distance <= 0.0 and (myself.location overlaps self or self overlaps myself.location))
					{
						nij <- {-nij.x,-nij.y};
					}
				}
				else {
					theta <- 0.0;
				}
				
				
				point tij <- {-nij.y,nij.x};
				
				
				float deltaVitesseTangencielle <- 
					(myself.actual_velocity.x)*tij.x + (myself.actual_velocity.y)*tij.y;
				
				myself.wall_forces <- {
					myself.wall_forces.x + ((Ai * exp(-distance / Bi)+body*theta) * nij.x - friction * theta * deltaVitesseTangencielle * tij.x), 
					myself.wall_forces.y + ((Ai * exp(-distance / Bi)+body*theta) * nij.y - friction * theta * deltaVitesseTangencielle * tij.y)
				};

			}
		}
	}
	
	//Noise in the movement of the pedestrian, rely on nervousness level
	action fluctuation_term_function
	   {
			if !isFluctuation {return {0.0,0.0};}
			if (fluctuationType = "Vector")
			{
				//The noise is independant of the deltaT, otherwise more the deltaT is little, more the noise is negligent (close to its mean, 0)
				if(cycle mod (1/deltaT) <= 0.001)
				{
		
					normal_fluctuation <- { gauss(0,1.0),gauss(0,1.0)};
					maximum_fluctuation <- {0,0};
					loop while:(norm(maximum_fluctuation) < norm(normal_fluctuation))
					{
						maximum_fluctuation <- { gauss(0,desired_speed*2.6),gauss(0,desired_speed*2.6)};
					}
				}
				
				fluctuation_forces <- {(1.0-nervousness)*normal_fluctuation.x + nervousness*maximum_fluctuation.x,(1.0-nervousness)*normal_fluctuation.y + nervousness*maximum_fluctuation.y};
			}
			else if (fluctuationType = "Speed")
			{
				desired_speed <- (1-nervousness)*pedDesiredSpeed + nervousness*pedMaxSpeed;
				fluctuation_forces <- {0.0,0.0};
			}
			   		   	
			
	   } 
	
	//Calculation of the force and moveent of the agent
	action computeVelocity
	{	
		//Save the current distance to the aim before any move
		lastDistanceToAim <- self.location distance_to aim;

		//Goal attraction force
		goal_attraction_force <- { (desired_speed * desired_direction.x - actual_velocity.x) / relaxation, (desired_speed * desired_direction.y - actual_velocity.y) / relaxation };

		// Sum of the forces
		point force_sum <- {
		goal_attraction_force.x  + people_forces.x/mass + wall_forces.x/mass, goal_attraction_force.y + people_forces.y/mass + wall_forces.y/mass
		};
			
		
		
		actual_velocity <- { actual_velocity.x + force_sum.x*deltaT, actual_velocity.y + force_sum.y*deltaT };
		float norm_actual_velocity <- norm(actual_velocity);
		max_velocity <- 1.3 * desired_speed;
		if(norm_actual_velocity>max_velocity )
		{
			actual_velocity <- {actual_velocity.x*max_velocity/norm_actual_velocity,actual_velocity.y*max_velocity/norm_actual_velocity};
		}

	}

	action mouvement
	{
		//Movement
		location <- { location.x + actual_velocity.x*deltaT, location.y + actual_velocity.y*deltaT };
	}	

	action computeNervousness
	{	
		orientedSpeed <- (lastDistanceToAim - (self.location distance_to aim));
		
		
		if cycle-spawnTime > round(relaxation/deltaT)
		{
			if cycle-spawnTime < 10+relaxation/deltaT
			{
				presenceTime <- cycle-spawnTime -relaxation/deltaT as int;
			}
			else
			{
				 remove first(lOrientedSpeed) from: lOrientedSpeed;
				 presenceTime <- 10;
			}
			add orientedSpeed to:lOrientedSpeed;
			
			float sum <- 0.0;
			loop i over:lOrientedSpeed {
				sum <- sum + i;
			}
			//Calculate the current nervousness
			nervousness <- 1-((sum/(presenceTime+epsilon))/(pedDesiredSpeed/*desired_speed*/*deltaT));
		if nervousness < 0.0 {nervousness <-0.0;} else if nervousness > 1.0 {nervousness <- 1.0;} 
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
	
	//Set the total value of nervousness with a compromise between the agent inner nervousness and his neighbours's blanced with a empathy coefficient
	action computeNervousnessEmpathy
	{
			if nbNeighbour > 0 {
				int isThresholdPass <-int(neighbourNervoussness >= threshold);
				innerNervousness <- nervousness;
				nervousness <- (1-empathy*isThresholdPass)*nervousness + empathy*neighbourNervoussness*isThresholdPass;
			}
			
		lastNervousness <- nervousness;
	}
	
	//Set contener variables empty
	action resetStepValue
	{
		matDistances <- nil as_matrix({nb_interactionPeople,1});
		interaction <- [];
	}
	
	action checking
	{
		checkPassing <- 2;
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

	
	action activation {
		if spawnTime = cycle {
			isActive <- true;
			wasActive <- true;
			n_color <- d_color;
			location <- { rnd(pointAX,pointBX), rnd(pointAY,pointBY) };
		}
	}
	
	action record {
		
		/*list temp;
		
		loop n over: interaction {
			add int(n) to:temp;
		}
		
		add temp to:recordNetwork;*/
		/*if (cycle mod int(1/deltaT) = 0)
		{
			if isActive and cptRecord > 0
			{
				add [isActive,recordDataTemp[0]/cptRecord,recordDataTemp[1]/cptRecord,recordDataTemp[2]/cptRecord,recordDataTemp[3]/cptRecord,recordDataTemp[4]/cptRecord] to:recordData;
			}
			else
			{
				add [isActive,0.1,0.0,0.0,0.0,0.0] to:recordData;
			}
			
			recordDataTemp <- [0.0,0.0,0.0,0.0,0.0];
			cptRecord <- 0;
		}
		else
		{
			if isActive
			{
				recordDataTemp <- [(recordDataTemp[0] + location.x),recordDataTemp[1] +location.y,recordDataTemp[2] +nervousness, recordDataTemp[3] +desired_direction.x,recordDataTemp[4] +desired_direction.y];
				cptRecord <- cptRecord + 1;
			}
		}*/
		add [isActive,location.x,location.y,nervousness,desired_direction.x,desired_direction.y] to:recordData;
	}
	
	//The agent mark the cell (in the nervousnees field) he is on with his nervousness
	action cellMark {
		ask field[(self.location.x) as int,(self.location.y) as int]
		{
			do addAgent(myself);
		}
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
	
	//Set the color of the agent based on nervousness value
	action setColor
	{
		color <- rgb(255*nervousness,255-255*nervousness,0.0);
	}
	
	aspect default
	{
		

		draw circle(size) color: color;
		if arrow{
			draw line([{location.x+ desired_direction.x,location.y + desired_direction.y},{location.x,location.y}]) color: #blue begin_arrow:0.1;
//			draw line([{location.x+ goal_attraction_force.x*deltaT,location.y + goal_attraction_force.y*deltaT},{location.x,location.y}]) color: #pink begin_arrow:0.1;
////			draw line([{location.x+ people_forces.x*deltaT/mass,location.y + people_forces.y*deltaT/mass},{location.x,location.y}]) color: #purple begin_arrow:0.1;
			draw line([{location.x+ wall_forces.x*deltaT,location.y + wall_forces.y*deltaT},{location.x,location.y}]) color: #orange begin_arrow:0.1;
//			draw line([{location.x+ actual_velocity.x,location.y + actual_velocity.y},{location.x,location.y}]) color: #red begin_arrow:0.1;
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














////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////GRID/////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////


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