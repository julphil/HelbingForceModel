/**
* Name: PanicCrowdSituation
* Author: Julien Philippe
* Description:  Implementation of Helbing social force model in escape panic situation.
*/

model EscapeCrowdSituation

global
{
	//Simulated time between two step (in second)
	float deltaT min: 0.0001 max: 1.0 <- 0.1;
	
	//Number of agent
	int number_of_people min: 1 <- 20;
	int number_of_walls min: 0 <- 4;
	
	//Use to choose the kind of simulation you want
	bool isDifferentGroup <- true; 
	bool isRespawn <- true;
	bool isFluctuation  <- false;
	string type;

	//space dimension
	int spaceWidth min: 2 <- 7;
	int spaceLength min: 5 <-20;
	float bottleneckSize min: 0.0 <- 10.0;

	//incremental var use in species initialisation
	int nd <- 0;
	int nbWalls <- 0;

	//Acceleration  time
	float relaxation min: 0.01 max: 1.0 <- 0.2;

	//Interaction strength
	float Ai min: 0.0 <- 2000.0;

	//Range of the repulsive interactions
	float Bi min: 0.0 <- 0.08;

	//Peception [0,1] => 0 -> 0° and 1 -> 360°
	float lambda min: 0.0 max: 1.0 <- 0.5;
	
	//Body force coefficient
	float body <- 120000.0;
	
	//Fiction coefficient
	float friction <- 240000.0;
	
	//pedestrian caracteristics
	float pedSize <- 0.25;
	float pedDesiredSpeed min: 0.5 max: 10.0 <- 3.34;

	//Space shape
	geometry shape <- rectangle(spaceLength, spaceWidth);
	
	//Agent creation
	init
	{
		create people number: number_of_people;
		if bottleneckSize <= spaceWidth {
			create wall number: number_of_walls;
			} else {
			create wall number: number_of_walls-2;	
		}
	}
	
	//If agents does not respawn, pause the simulation at the time they're  no more agent in the simulation
	reflex stopIt when:length(people) <= 0 {
		do pause;
	}

}

species people
{
	rgb color;
	float size;
	int group;
	float nervousness <- 0.0;
	float mass min:1.0 max:120.0 <- 80.0;
	

	// Destination
	point aim;
	point desired_direction;
	float desired_speed;
	point actual_velocity <- { 0.0, 0, 0 };
	float max_velocity;
	
	//Fluctuations
    point normal_fluctuation;
    point maximum_fluctuation;
    
    //Use to compute the average speed
    float lastDistanceToAim;
    float orientedSpeed;
    float cumuledOrientedSpeed;
    int presenceTime <- 0;
    
    //Goal attraction force
	point goal_attraction_force <- {0.0,0.0};

	//Compute forces
	point people_forces <- {0.0,0.0};
	point wall_forces <- {0.0,0.0};
	point fluctuation_forces <- {0.0,0.0};
 
	//Force functions
	//Social repulsion force + physical interaction force
	point people_repulsion_force_function
	{
		point social_repulsion_force <- { 0.0, 0.0 };
		point physical_repulsion_force  <- { 0.0, 0.0 };
		point physical_tangencial_force  <- { 0.0, 0.0 };
		
		ask people parallel:true 
		{
			if self != myself
			{
				point distanceCenter <- { myself.location.x - self.location.x, myself.location.y - self.location.y };
				float distance <- myself distance_to self;	
				point nij <- { (myself.location.x - self.location.x) / norm(distanceCenter), (myself.location.y - self.location.y) / norm(distanceCenter) };
				//float phiij <- -nij.x * actual_velocity.x / (norm(actual_velocity) + 0.0000001) + -nij.y * actual_velocity.x / (norm(actual_velocity) + 0.0000001);
				float phiij <- -nij.x * desired_direction.x + -nij.y * desired_direction.y;
				
				//Social force
				social_repulsion_force <- {
				social_repulsion_force.x + (Ai * exp(-distance / Bi) * nij.x * (lambda + (1 - lambda) * (1 + phiij) / 2)), social_repulsion_force.y + (Ai * exp(-distance / Bi) * nij.y * (lambda + (1 - lambda) * (1 + phiij) / 2))
				};
				
				//Physical force
				if (distance <= size)
				{
					float theta;
					
					if ((myself.size + size) - norm(distanceCenter) <= 0.0) { //If there is no contact
						theta <- 0.0;
					} else {
						theta <- (myself.size + size) - norm(distanceCenter);
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
		return {social_repulsion_force.x+physical_repulsion_force.x + physical_tangencial_force.x,social_repulsion_force.y+physical_repulsion_force.y + physical_tangencial_force.y};
	}
	
	//Wall dodge  force + physical interaction force
	point wall_repulsion_force_function 
	{
		point wall_repulsion_force <- { 0.0, 0.0 };
		ask wall parallel:true
		{
			if (self != myself)
			{
				point wallClosestPoint <- closest_points_with(myself.location ,self.shape.contour)[1];
				float distance <- norm({ myself.location.x - wallClosestPoint.x, myself.location.y - wallClosestPoint.y });
				point nij <- { (myself.location.x - wallClosestPoint.x) / distance, (myself.location.y - wallClosestPoint.y) / distance};
				
				
				float theta;
				
				if (distance-myself.size <= 0.0 or myself.location overlaps self or self overlaps myself.location) { //if there is a contact
					theta <- myself.size-distance;

					if(distance-myself.size <= 0.0 and (myself.location overlaps self or self overlaps myself.location))
					{
						nij <- {-nij.x,-nij.y};
					}
				}
				else {
					theta <- 0.0;
				}
				
				
				point tij <- {-nij.y,nij.x};
				
				float deltaVitesseTangencielle <- 
					( -myself.actual_velocity.x)*tij.x + (myself.actual_velocity.y)*tij.y;
				
				wall_repulsion_force <- {
					wall_repulsion_force.x + ((Ai * exp(myself.size-distance / Bi)+body*theta) * nij.x + friction * theta * deltaVitesseTangencielle * tij.x), 
					wall_repulsion_force.y + ((Ai * exp(myself.size-distance / Bi)+body*theta) * nij.y + friction * theta * deltaVitesseTangencielle * tij.y)
				};
			}
		}
		return wall_repulsion_force;
	}
	
	//Noise in the movement of the pedestrian, rely on nervousness level
	point fluctuation_term_function
   {
		if !isFluctuation {return {0.0,0.0};}
		//The noise is independant of the deltaT, otherwise more the deltaT is little, more the noise is negligent (close to its mean, 0)
		if(cycle mod (1/deltaT) <= 0.001)
		{

			normal_fluctuation <- { gauss(0,0.1),gauss(0,0.1)};
			maximum_fluctuation <- {0,0};
			          
			loop while:(norm(maximum_fluctuation) < norm(normal_fluctuation))
			{
				maximum_fluctuation <- { gauss(0,2.5),gauss(0,2.5)};
			}
		}
		   		   	
		point fluctuation_term <- {(1.0-nervousness)*normal_fluctuation.x + nervousness*maximum_fluctuation.x,(1.0-nervousness)*normal_fluctuation.y + nervousness*maximum_fluctuation.y};
		return fluctuation_term;
   } 
	
	
	init
	{
		self.size <- pedSize;
		self.desired_speed <- pedDesiredSpeed;
		max_velocity <- 1.3 * desired_speed;
		
		shape <- circle(size);
		//In this version, you can have one group of black agent going left. Or two group with the same black group plus a yellow group going rigth
		if nd mod 2 = 0 or !isDifferentGroup
		{
			color <- # black;
			if(type="random") {
				location <- { spaceLength - rnd(spaceLength / 2 - 1), rnd(spaceWidth - (1 + size)*2) + 1 + size };
				if (number_of_people > 1)
				{
					loop while:( agent_closest_to(self).location distance_to self.location < size*2){
						location <- { spaceLength - rnd(spaceLength / 2 - 1), rnd(spaceWidth - (1 + size)*2) + 1 + size };
					}
				}
			} //random location in a halfspace
				else if type = "lane" //lane configuration starting location
				{
					if(nd <20) {
						location <- {nd+1,2.85};
					} else {
						location <- {nd-20,4.1};
				}
			}
			
			if (bottleneckSize < spaceWidth)
			{
				aim <- { spaceLength/2 -0.5, spaceWidth/2};
			} else {
				aim <- {-size*2,location.y};
			}
			group <- 0;
		} else
		{
			color <- # yellow;
			if type = "random" {
				location <- { 0 + rnd(spaceLength / 2 - 1), rnd(spaceWidth - (1 + size)*2) + 1 + size };
				if (number_of_people > 1)
				{
					loop while:(agent_closest_to(self).location distance_to self.location < size*2){
						location <- { 0 + rnd(spaceLength / 2 - 1), rnd(spaceWidth - (1 + size)*2) + 1 + size };
					}
				}
			} //random location in a halfspace
			else if type = "lane" //lane configuration starting location
			{
				if(nd <20) {
					location <- {nd,1.6};
				} else {
					location <- {nd-20,5.35};
				}
			}
			if (bottleneckSize < spaceWidth)
			{
				aim <- { spaceLength/2 + 0.5, spaceWidth/2 };
			} else {
				aim <- {spaceLength+size*2,location.y};
			}
			group <- 1;
		}
		 
		nd <- nd + 1;
		desired_direction <- {
		(aim.x - location.x) / (abs(sqrt((aim.x - location.x) * (aim.x - location.x) + (aim.y - location.y) * (aim.y - location.y)))), (aim.y - location.y) / (abs(sqrt((aim.x - location.x) * (aim.x - location.x) + (aim.y - location.y) * (aim.y - location.y))))
		};
		
		//Initilasation of the noise
		normal_fluctuation <- { gauss(0,0.01),gauss(0,0.01)};
		maximum_fluctuation <- {0,0};
              
		loop while:(norm(maximum_fluctuation) < norm(normal_fluctuation))
		{
	   		maximum_fluctuation <- { gauss(0,2.5),gauss(0,2.5)};    
		}
		
		
	}

	//Check if the agent is out. If it the case, dependant if respawn is actived or not, it delte the agent or replace it 
	reflex sortie
	{
		if isRespawn 
		{
			if location.x >= spaceLength and group = 1
			{
				location <- { 0, location.y};//rnd(spaceWidth - (1 + size)*2) + 1 + size };
			} else if location.x <= 0 and group = 0
			{
				location <- { spaceLength, location.y};//rnd(spaceWidth - (1 + size)*2) + 1 + size };
			}
		}
		else if (location.x >= spaceLength and group = 1) or (location.x <= 0 and group = 0)
		{
			do die;
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
	
	//Choose the destination point
	reflex aim
	{
		if((bottleneckSize >= spaceWidth) or (group = 0 and location.x < spaceLength/2) or (group = 1 and location.x > spaceLength/2)) { //Already pass the bottleneck
			aim <- {spaceLength*group+size*2*group,location.y};
		} else  { //Don't pass it
			aim <- {aim.x,spaceWidth/2};
		}
	}

	//Calculation of the force and moveent of the agent
	reflex step
	{	
		//Save the current distance to the aim before any move
		lastDistanceToAim <- self.location distance_to aim;
		

		//update the goal direction
		float norme <- sqrt((aim.x - location.x) * (aim.x - location.x) + (aim.y - location.y) * (aim.y - location.y));
		desired_direction <- { (aim.x - location.x) / (norme + 0.000000001), (aim.y - location.y) / (norme + 0.000000001) };

		//Goal attraction force
		goal_attraction_force <- { (desired_speed * desired_direction.x - actual_velocity.x) / relaxation, (desired_speed * desired_direction.y - actual_velocity.y) / relaxation };

		//Compute forces
		people_forces <- people_repulsion_force_function();
		wall_forces <-  wall_repulsion_force_function();
		fluctuation_forces <- fluctuation_term_function();

		

		// Sum of the forces
		point force_sum <- {
		goal_attraction_force.x  + people_forces.x/mass + wall_forces.x/mass + fluctuation_forces.x, goal_attraction_force.y + people_forces.y/mass + wall_forces.y/mass + fluctuation_forces.y
		};
			
		
		
		actual_velocity <- { actual_velocity.x + force_sum.x*deltaT, actual_velocity.y + force_sum.y*deltaT };
		float norm_actual_velocity <- norm(actual_velocity);
		if(norm_actual_velocity>max_velocity )
		{
			actual_velocity <- {actual_velocity.x*max_velocity/norm_actual_velocity,actual_velocity.y*max_velocity/norm_actual_velocity};
		}

		//Movement
		location <- { location.x + actual_velocity.x*deltaT, location.y + actual_velocity.y*deltaT };
		
		//Calculate the current nervousness
		orientedSpeed <- (lastDistanceToAim - (self.location distance_to aim));
		cumuledOrientedSpeed <- cumuledOrientedSpeed + orientedSpeed;
		presenceTime <- presenceTime  + 1;
		//nervousness <- 1-((cumuledOrientedSpeed/(presenceTime*deltaT))/desired_speeddesired_speed*deltaT);
		nervousness <- 1-((orientedSpeed)/(desired_speed*deltaT));
		if nervousness < 0.0 {nervousness <-0.0;} else if nervousness > 1.0 {nervousness <- 1.0;} 
		
	}

	aspect default
	{
		draw circle(size) color: color;
		draw line([{location.x+ desired_direction.x,location.y + desired_direction.y},{location.x,location.y}]) color: #blue begin_arrow:0.1;
		draw line([{location.x+ goal_attraction_force.x*deltaT,location.y + goal_attraction_force.y*deltaT},{location.x,location.y}]) color: #pink begin_arrow:0.1;
		draw line([{location.x+ people_forces.x*deltaT/mass,location.y + people_forces.y*deltaT/mass},{location.x,location.y}]) color: #purple begin_arrow:0.1;
		draw line([{location.x+ wall_forces.x*deltaT,location.y + wall_forces.y*deltaT},{location.x,location.y}]) color: #orange begin_arrow:0.1;
		draw line([{location.x+ actual_velocity.x,location.y + actual_velocity.y},{location.x,location.y}]) color: #red begin_arrow:0.1;
	}

}

species wall
{
	float width;
	float length;
	init
	{
		switch nbWalls
		{
			match 0
			{
				length <- spaceLength + 10.0;
				width <- 100.0;
				shape <- rectangle(length, width);
				location <- { spaceLength / 2, -49.0 };
				break;
			}

			match 1
			{
				length <- spaceLength + 10.0;
				width <- 100.0;
				shape <- rectangle(length, width);
				location <- { spaceLength / 2, spaceWidth - (-49.0) };
				break;
			}

			match 2
			{
				length <- 0.1;
				width <- spaceWidth / 2 - 1.0 - bottleneckSize / 2;
				shape <- rectangle(length, width);
				location <- { spaceLength / 2.0, width / 2 + 1 };
				break;
			}

			match 3
			{
				length <- 0.1;
				width <- spaceWidth / 2 - 1.0 - bottleneckSize / 2;
				shape <- rectangle(length, width);
				location <- { spaceLength / 2.0, spaceWidth / 2 - 1.0 - bottleneckSize / 2 + bottleneckSize + width / 2 + 1 };
				break;
			}

		}

		nbWalls <- nbWalls + 1;
	}
	

	aspect default
	{
		draw rectangle(length, width) color: rgb(0, 0, 0);
	}

}

experiment helbingPanicSimulation type: gui
{
	parameter 'Generation type' var: type among:["random","lane"] init:"random" category:"Simulation parameter" ;
	parameter 'Delta T' var: deltaT category:"Simulation parameter" slider:false unit:"Second";
	parameter 'Relaxation time' var: relaxation category:"Simulation parameter" unit:"Second" slider:false;
	parameter 'Is Different group ?' var: isDifferentGroup category:"Simulation parameter";
	parameter 'Respawn' var: isRespawn category:"Simulation parameter";
	parameter 'Fluctuation' var: isFluctuation category:"Simulation parameter";
	parameter 'Pedestrian number' var: number_of_people category:"Simulation parameter";
	parameter 'Pedestrian speed' var: pedDesiredSpeed category:"Simulation parameter" unit:"m.s-1" slider:false;
	
	parameter 'Space length' var: spaceLength category:"Space parameter" unit:"Meter";
	parameter 'Space width' var: spaceWidth category:"Space parameter" unit:"Meter";
	parameter 'Bottleneck size' var: bottleneckSize category:"Space parameter" unit:"Meter";
	
	parameter 'Interaction strength' var: Ai category:"Forces parameter" unit:"Newton";
	parameter 'Range of the repulsive interactions' var: Bi category:"Forces parameter" unit:"Meter";
	parameter 'Peception' var: lambda category:"Forces parameter" slider:false;
	parameter 'Body contact strength' var: body category:"Forces parameter" unit:"kg.s-2";
	parameter 'Body friction' var: friction category:"Forces parameter" unit:"kg.m-1.s-1";
	
	output
	{
		display SocialForceModel_display
		{
			species people;
			species wall;
		}
		display SocialForceModel_NBPeople
		{
			chart "Number of peoples still inside " {
				data "nb_people" value: length(people);
				
			}
			
			
		}
		
		display SocialForceModel_nervousnness
		{
			chart "global nervoussness" {
				data "global nervoussness" value: mean(people collect each.nervousness);
			}
		}
		
		display SocialForceModel_averageSpeed
		{
			chart "Average speed" {
				data "Average speed" value: mean(people collect norm(each.actual_velocity));
				data "Average directed speed" value: mean(people collect each.orientedSpeed)/deltaT;
			}
		}
	}

}

//A hallway where agent are already in lane configuaration
experiment helbingPanicSimulation_lane type: gui parent:helbingPanicSimulation
{
	parameter 'Generation type' init:"lane";
	parameter 'Pedestrian number' var: number_of_people init:40;
	parameter 'Fluctuation' var: isFluctuation init:true;
}

//One agent, not  a real simulation, but usefull to debug
experiment helbingPanicSimulation_uniqueAgent type: gui parent:helbingPanicSimulation
{
	parameter 'Pedestrian number' var: number_of_people init:1;
	parameter 'Space length' var: spaceLength init:10;
	parameter 'Space width' var: spaceWidth init:10;
	parameter 'Bottleneck size' var: bottleneckSize init:0.0;
}

//On group trying to pass a bottle neck
experiment helbingPanicSimulation_bottleneck_1group type: gui parent:helbingPanicSimulation
{
	parameter 'Is Different group ?' var: isDifferentGroup init:false;
	parameter 'Respawn' var: isRespawn init:false;
	parameter 'Pedestrian number' var: number_of_people init:40;
	parameter 'Space width' var: spaceWidth init:15;
	parameter 'Bottleneck size' var: bottleneckSize init:1.0;
}

//Two group trying to pass a bottleneck in diffrent direction
experiment helbingPanicSImulation_bottleneck_2group parent: helbingPanicSimulation_bottleneck_1group
{
	parameter 'Is Different group ?' var: isDifferentGroup init:true;
}

