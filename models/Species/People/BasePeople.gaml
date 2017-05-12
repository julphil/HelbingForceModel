/**
* Name: BasePeople
* Author: julien
* Description: 
* Tags: Tag1, Tag2, TagN
*/

model BasePeople

import "../Wall/BaseWall.gaml"

species basePeople
{
	rgb d_color;
	rgb color;
	
	float size;
	int group;
	float mass min:1.0 max:120.0 <- 80.0;
	

	// Destination
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
    
    //Goal attraction force
	point goal_attraction_force <- {0.0,0.0};

	//Compute forces
	point people_forces <- {0.0,0.0};
	point wall_forces <- {0.0,0.0};
 	
	init
	{
		self.size <- rnd(pedSizeMin,pedSizeMax);
		self.desired_speed <- pedDesiredSpeed;
		max_velocity <- 1.3 * desired_speed;
		
		shape <- circle(size);
		//In this version, you can have one group of black agent going left. Or two group with the same black group plus a yellow group going rigth
		if nd mod 2 = 0 or !isDifferentGroup
		{
			if(isDifferentGroup)
			{
				d_color <- # black;	
			}
			else
			{
				d_color <- rnd_color(255);
			}
			if(type="random") {
//				HERElocation <- { spaceLength - rnd(spaceLength / 2 - 1), rnd(spaceWidth - (1 + size)*2) + 1 + size };
				location <- { spaceLength - rnd(spaceLength - 3), rnd(spaceWidth - (1 + size)*2) + 1 + size };
				if (number_of_people > 1)
				{
					loop while:( agent_closest_to(self).location distance_to self.location < size*2){
						location <- { spaceLength - rnd(spaceLength - 3), rnd(spaceWidth - (1 + size)*2) + 1 + size };
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
				//HEREaim <- { spaceLength/2 -0.5, spaceWidth/2};
				aim <- { 2 -0.5, spaceWidth/2};
			} else {
				aim <- {-size*2,location.y};
			}
			group <- 0;
		} else
		{
			d_color <- # yellow;
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
		
		color <- d_color;
	}

	//Check if the agent is out. If it the case, dependant if respawn is actived or not, it delte the agent or replace it 
	action sortie
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
	action aim
	{
		float aimX; 
		float aimY;
		//HEREif((bottleneckSize >= spaceWidth) or (group = 0 and location.x < spaceLength/2) or (group = 1 and location.x > spaceLength/2)) { //Already pass the bottleneck
		if((bottleneckSize >= spaceWidth) or (group = 0 and location.x < 2) or (group = 1 and location.x > spaceLength/2)) { //Already pass the bottleneck
			aimX <- spaceLength*group+size*2*group;
			aimY <- location.y;
		} else  { 
			if location.x > 4.0 or location.y < spaceWidth/2 - bottleneckSize/2 or location.y > spaceWidth/2 + bottleneckSize/2
			{
				aimX <- 3.0;
				aimY <- spaceWidth/2;
			}
			else
			{
				aimX <- 1.5;
				aimY <-  spaceWidth/2;
			}
		}
		
		aim <- {aimX,aimY};
	}

	//Force functions
	//Social repulsion force + physical interaction force
	action people_repulsion_force_function
	{
		point social_repulsion_force <- { 0.0, 0.0 };
		point physical_repulsion_force  <- { 0.0, 0.0 };
		point physical_tangencial_force  <- { 0.0, 0.0 };
		
		people_forces <- {0.0, 0.0};
		
		ask basePeople parallel:true 
		{
			if self != myself
			{
				float distanceCenter <- norm({ myself.location.x - self.location.x, myself.location.y - self.location.y });
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
				
				point nij <- { (myself.location.x - wallClosestPoint.x) / (distance+myself.size), (myself.location.y - wallClosestPoint.y) / (distance+myself.size)};
				
				
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

	action computeForce
	{
		//Compute forces
		do  people_repulsion_force_function;
		do wall_repulsion_force_function;
	}

	//Calculation of the force and moveent of the agent
	action computeVelocity
	{	
		//Save the current distance to the aim before any move
		lastDistanceToAim <- self.location distance_to aim;

		//update the goal direction
		float norme <- sqrt((aim.x - location.x) * (aim.x - location.x) + (aim.y - location.y) * (aim.y - location.y));
		desired_direction <- { (aim.x - location.x) / (norme + 0.000000001), (aim.y - location.y) / (norme + 0.000000001) };

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
		
		
		if cycle > round(relaxation/deltaT)
		{
			if cycle < 10+relaxation/deltaT
			{
				presenceTime <- cycle -relaxation/deltaT as int;
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
		}
	}

	aspect default
	{
		

		draw circle(size) color: color;
		if arrow{
		draw line([{location.x+ desired_direction.x,location.y + desired_direction.y},{location.x,location.y}]) color: #blue begin_arrow:0.1;
		draw line([{location.x+ goal_attraction_force.x*deltaT,location.y + goal_attraction_force.y*deltaT},{location.x,location.y}]) color: #pink begin_arrow:0.1;
		draw line([{location.x+ people_forces.x*deltaT/mass,location.y + people_forces.y*deltaT/mass},{location.x,location.y}]) color: #purple begin_arrow:0.1;
		draw line([{location.x+ wall_forces.x*deltaT,location.y + wall_forces.y*deltaT},{location.x,location.y}]) color: #orange begin_arrow:0.1;
		draw line([{location.x+ actual_velocity.x,location.y + actual_velocity.y},{location.x,location.y}]) color: #red begin_arrow:0.1;
		}
	}

}
