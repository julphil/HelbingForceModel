/**
* Name:  PanicPeople
* Author: julien
* Description: 
* Tags: Tag1, Tag2, TagN
*/

model PanicPeople

import "BasePeople.gaml"
import "../../Parameter/PanicParameter.gaml"

species panicPeople parent:basePeople
{
	float nervousness <- 0.0;
	
	//Fluctuations
    point normal_fluctuation;
    point maximum_fluctuation;
    
	point fluctuation_forces <- {0.0,0.0};
 
 	
	init
	{
		
		//Initilasation of the noise
		normal_fluctuation <- { gauss(0,0.01),gauss(0,0.01)};
		maximum_fluctuation <- {0,0};
              
		loop while:(norm(maximum_fluctuation) < norm(normal_fluctuation))
		{
	   		maximum_fluctuation <- { gauss(0,desired_speed*2.6),gauss(0,desired_speed*2.6)};    
		}
		
	}
	
	action computeDistance
	{	
		ask panicPeople parallel:true 
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
	
	//Force functions
	//Social repulsion force + physical interaction force
	action people_repulsion_force_function
	{
		point social_repulsion_force <- { 0.0, 0.0 };
		point physical_repulsion_force  <- { 0.0, 0.0 };
		point physical_tangencial_force  <- { 0.0, 0.0 };
		
		people_forces <- {0.0, 0.0};
		
		ask panicPeople parallel:true 
		{
			if self != myself
			{
				float distanceCenter <- matDistances[int(myself),0] as float;
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
	
	//Choose the destination point
	action aim
	{
		if location.x>(lAim[indexAim].key as point).x and location.x<lAim[indexAim].value.x and location.y>(lAim[indexAim].key as point).y and location.y<lAim[indexAim].value.y
		{
			indexAim <- indexAim+1;
			aimZone <- polygon([lAim[indexAim].key as point,{(lAim[indexAim].key as point).x,lAim[indexAim].value.y},lAim[indexAim].value,{lAim[indexAim].value.x,(lAim[indexAim].key as point).y}]);
		}
		
		aim <-  closest_points_with(location,aimZone)[1];
		
		//update the goal direction
		float norme <- sqrt((aim.x - location.x) * (aim.x - location.x) + (aim.y - location.y) * (aim.y - location.y));
		desired_direction <- { (aim.x - location.x) / (norme + epsilon), (aim.y - location.y) / (norme + epsilon) };
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
   
   action computeForce
	{
		//Compute forces
		do  people_repulsion_force_function;
		do wall_repulsion_force_function;
		do fluctuation_term_function;
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
		goal_attraction_force.x  + people_forces.x/mass + wall_forces.x/mass + fluctuation_forces.x, goal_attraction_force.y + people_forces.y/mass + wall_forces.y/mass + fluctuation_forces.y
		};
			
		
		
		actual_velocity <- { actual_velocity.x + force_sum.x*deltaT, actual_velocity.y + force_sum.y*deltaT };
		float norm_actual_velocity <- norm(actual_velocity);
		max_velocity <- 1.3 * desired_speed;
		if(norm_actual_velocity>max_velocity )
		{
			actual_velocity <- {actual_velocity.x*max_velocity/norm_actual_velocity,actual_velocity.y*max_velocity/norm_actual_velocity};
		}
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

	aspect default
	{
		

		draw circle(size) color: color;
		if arrow{
			draw line([{location.x+ desired_direction.x,location.y + desired_direction.y},{location.x,location.y}]) color: #blue begin_arrow:0.1;
//			draw line([{location.x+ goal_attraction_force.x*deltaT,location.y + goal_attraction_force.y*deltaT},{location.x,location.y}]) color: #pink begin_arrow:0.1;
////			draw line([{location.x+ people_forces.x*deltaT/mass,location.y + people_forces.y*deltaT/mass},{location.x,location.y}]) color: #purple begin_arrow:0.1;
//			draw line([{location.x+ wall_forces.x*deltaT,location.y + wall_forces.y*deltaT},{location.x,location.y}]) color: #orange begin_arrow:0.1;
//			draw line([{location.x+ actual_velocity.x,location.y + actual_velocity.y},{location.x,location.y}]) color: #red begin_arrow:0.1;
		}
	}

}
