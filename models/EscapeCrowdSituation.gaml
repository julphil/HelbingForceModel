/**
* Name: NormalCrowdSituation
* Author: Julien Philippe
* Description:  Implementation of Helbing social force model in escape panic situation.
*/

model EscapeCrowdSituation

global
{
	int number_of_agents min: 1 <- 20;
	int number_of_walls min: 0 <- 4;

	//space dimension
	int spaceWidth min: 5 <- 7;
	int spaceLength min: 5 <-50;
	int bottleneckSize min: 0 <- 30;

	//incremental var use in species init
	int nd <- 0;
	int nbWalls <- 0;

	//Acceleration relaxation time
	float relaxation <- 2.0;

	//Interaction strength
	float Ai min: 0.0 <- 3.0;

	//Range of the repulsive interactions
	float Bi min: 0.0 <- 0.5;

	//Peception [0,1] => 0 -> 0° and 1 -> 360°
	float lambda min: 0.0 max: 1.0 <- 0.5;
	
	//Body force coefficient
	float body <- 1000.0;
	
	//Fiction coefficient
	float friction <- 5.0;
	
	float maxAcc <- 0.0;
	float meanAcc <- 0.0;
	int nbFor <- 0;
	


	//Space shape
	geometry shape <- rectangle(spaceLength, spaceWidth);
	init
	{
		
		create people number: number_of_agents;
		if bottleneckSize < spaceWidth {
			create wall number: number_of_walls;
			} else {
			create wall number: number_of_walls-2;	
		}
	}
		
}

species people
{
	rgb color;
	float size <- 0.5;
	int group;
	float nervousness <- 1.0;

	// Destination
	point aim;
	point desired_direction;
	float desired_speed <- 1.34;
	point actual_velocity <- { 0.0, 0, 0 };
	
	//Fluctuations
	point normal_fluctuation;
	point maximum_fluctuation;

	//Force functions
	point social_repulsion_force_function
	{
		point social_repulsion_force <- { 0.0, 0.0 };
		ask people parallel:true
		{
			if (self != myself)
			{
				point distanceCenter <- { myself.location.x - self.location.x, myself.location.y - self.location.y };
				float distance <- myself distance_to self;
				point nij <- { (myself.location.x - self.location.x) / norm(distanceCenter), (myself.location.y - self.location.y) / norm(distanceCenter) };
				float phiij <- -nij.x * actual_velocity.x / (norm(actual_velocity) + 0.0000001) + -nij.y * actual_velocity.x / (norm(actual_velocity) + 0.0000001);
				social_repulsion_force <- {
				social_repulsion_force.x + (Ai * exp(-distance / Bi) * nij.x * (lambda + (1 - lambda) * (1 + phiij) / 2)), social_repulsion_force.y + (Ai * exp(-distance / Bi) * nij.y * (lambda + (1 - lambda) * (1 + phiij) / 2))
				};
			}

		}

		return social_repulsion_force;
	}

	point wall_repulsion_force_function 
	{
		point wall_repulsion_force <- { 0.0, 0.0 };
		ask wall parallel:true
		{
			if (self != myself)
			{
				point wallClosestPoint <- closest_points_with(myself ,self.shape.contour)[1];
				float distance <- norm({ myself.location.x - wallClosestPoint.x, myself.location.y - wallClosestPoint.y });
				point nij <- { (myself.location.x - wallClosestPoint.x) / distance, (myself.location.y - wallClosestPoint.y) / distance};
				
				
				float theta;
				
				if (distance-myself.size <= 0.0 or myself.location overlaps self or self overlaps myself.location) {
					theta <- -distance;
				} else {
					theta <- 0.0;
				}
				
				
				point tij <- {-nij.y,nij.x};
				
				float deltaVitesseTangencielle <- 
					( myself.actual_velocity.x)*tij.x + (myself.actual_velocity.y)*tij.y;
				
				wall_repulsion_force <- {
					wall_repulsion_force.x + ((Ai * exp(-distance / Bi)+body*theta) * nij.x + friction * theta * deltaVitesseTangencielle * tij.x), 
					wall_repulsion_force.y + ((Ai * exp(-distance / Bi)+body*theta) * nij.y + friction * theta * deltaVitesseTangencielle * tij.y)
				};
			}
		}

		return wall_repulsion_force;
	}

	point physical_interaction_force_function 
	{
		point physical_interaction_force  <- { 0.0, 0.0 };
		
		ask people parallel:true 
		{
			if (self distance_to myself <= size and self != myself)
			{
				point distanceCenter <- { myself.location.x - self.location.x, myself.location.y - self.location.y };
				float distance <- myself distance_to self;
				point nij <- { (myself.location.x - self.location.x) / norm(distanceCenter), (myself.location.y - self.location.y) / norm(distanceCenter) };
				float phiij <- -nij.x * actual_velocity.x / (norm(actual_velocity) + 0.0000001) + -nij.y * actual_velocity.x / (norm(actual_velocity) + 0.0000001);
				
				
				float theta;
				
				if ((myself.size + size) - norm(distanceCenter) <= 0.0) {
					theta <- 0.0;
				} else {
					theta <- (myself.size + size) - norm(distanceCenter);
				}

				point tij <- {-nij.y,nij.x};
				
				float deltaVitesseTangencielle <- 
					(actual_velocity.x - myself.actual_velocity.x)*tij.x + (actual_velocity.y - myself.actual_velocity.y)*tij.y;
				
				physical_interaction_force <- {
					physical_interaction_force.x + body * theta * nij.x + friction * theta * deltaVitesseTangencielle * tij.x,
					physical_interaction_force.y + body * theta * nij.y + friction * theta * deltaVitesseTangencielle * tij.y
				};
				
			}
		}
		
		return physical_interaction_force; 	
	}
	
	point fluctuation_term_function
	{
		point fluctuation_term <- {(1.0-nervousness)*normal_fluctuation.x + nervousness*maximum_fluctuation.x,(1.0-nervousness)*normal_fluctuation.y + nervousness*maximum_fluctuation.y};
		return fluctuation_term;
	}
	
	init
	{
		shape <- circle(size);
		if nd mod 2 = 0
		{
			color <- # black;
			location <- { spaceLength - rnd(spaceLength / 2 - 1), rnd(spaceWidth - (1 + size)*2) + 1 + size };
			aim <- { spaceLength/2 -5, spaceWidth/2};
			group <- 0;
		} else
		{
			color <- # yellow;
			location <- { 0 + rnd(spaceLength / 2 - 1), rnd(spaceWidth - (1 + size)*2) + 1 + size };
			aim <- { spaceLength + 5, spaceWidth/2 };
			group <- 1;
		}

		nd <- nd + 1;
		desired_direction <- {
		(aim.x - location.x) / (abs(sqrt((aim.x - location.x) * (aim.x - location.x) + (aim.y - location.y) * (aim.y - location.y)))), (aim.y - location.y) / (abs(sqrt((aim.x - location.x) * (aim.x - location.x) + (aim.y - location.y) * (aim.y - location.y))))
		};
		
		normal_fluctuation <- { gauss(0,0.01),gauss(0,0.01)};
		maximum_fluctuation <- {0,0};
		
		loop while:(norm(maximum_fluctuation) < norm(normal_fluctuation)) {
			maximum_fluctuation <- { gauss(0,0.1),gauss(0,0.1)};	
		}
	}

	reflex sortie
	{
		if location.x >= spaceLength and group = 1
		{
			location <- { 0, location.y};//rnd(spaceWidth - (1 + size)*2) + 1 + size };
			aim <- { spaceLength + 5, spaceWidth/2 };
		} else if location.x <= 0 and group = 0
		{
			location <- { spaceLength, location.y};//rnd(spaceWidth - (1 + size)*2) + 1 + size };
			aim <- { spaceLength/2 -5, spaceWidth/2};
		}
		if location.y < 0 
		{
			location <- {location.x, 0.0};
		} else if location.y > spaceWidth 
		{
			location <- {location.x,spaceWidth};
		}

	}

	reflex step
	{
		if((group = 0 and location.x < spaceLength/2) or (group = 1 and location.x > spaceLength/2)) {
			aim <- {spaceLength*group,location.y};
		} else if (location.y < spaceWidth/2 - bottleneckSize/2 ) {
			aim <- {aim.x,spaceWidth/2 - bottleneckSize/2 + 1};
		} else if (location.y > spaceWidth/2 + bottleneckSize/2 ) {
			aim <- {aim.x,spaceWidth/2 + bottleneckSize/2 - 1};
		} else if location.y <=1 {
			aim <- {aim.x,1};
			actual_velocity <- {0.0,0.0};
		} else if location.y >= spaceWidth -1 {
			aim <- {aim.x,spaceWidth -1};
			actual_velocity <- {0.0,0.0};
		} else {
			aim <- {aim.x,location.y};
		}

		//update the goal direction
		float norme <- sqrt((aim.x - location.x) * (aim.x - location.x) + (aim.y - location.y) * (aim.y - location.y));
		desired_direction <- { (aim.x - location.x) / (norme + 0.000000001), (aim.y - location.y) / (norme + 0.000000001) };

		//Goal attraction force
		point goal_attraction_force <- { (desired_speed * desired_direction.x - actual_velocity.x) / relaxation, (desired_speed * desired_direction.y - actual_velocity.y) / relaxation };

		// Sum of the forces
		point force_sum <- {
		goal_attraction_force.x  + social_repulsion_force_function().x + wall_repulsion_force_function().x + physical_interaction_force_function().x + fluctuation_term_function().x, goal_attraction_force.y + social_repulsion_force_function().y + wall_repulsion_force_function().y + physical_interaction_force_function().y + fluctuation_term_function().y
		};

		// Acceleration
		float norme_sum <- norm(force_sum);
		float max_velocity <- 1.3 * desired_speed;
		if (norme_sum <= max_velocity)
		{
			actual_velocity <- { actual_velocity.x + force_sum.x, actual_velocity.y + force_sum.y };
		} else
		{
			actual_velocity <- { force_sum.x * (max_velocity / norme_sum), force_sum.y * (max_velocity / norme_sum) };
		}

		//Movement
		location <- { location.x + actual_velocity.x, location.y + actual_velocity.y };
		
	}

	aspect default
	{
		draw circle(size) color: color;
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
				length <- spaceLength + 0.0;
				width <- 1.0;
				shape <- rectangle(length, width);
				location <- { spaceLength / 2, 0.5 };
				break;
			}

			match 1
			{
				length <- spaceLength + 0.0;
				width <- 1.0;
				shape <- rectangle(length, width);
				location <- { spaceLength / 2, spaceWidth - 0.5 };
				break;
			}

			match 2
			{
				length <- 1.0;
				width <- spaceWidth / 2 - 1.0 - bottleneckSize / 2;
				shape <- rectangle(length, width);
				location <- { spaceLength / 2.0, width / 2 + 1 };
				break;
			}

			match 3
			{
				length <- 1.0;
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

experiment helbingPanic type: gui
{
	parameter 'Pedestrian number' var: number_of_agents;
	parameter 'Space length' var: spaceLength;
	parameter 'Space width' var: spaceWidth;
	parameter 'Bottleneck size' var: bottleneckSize;
//	parameter 'Interaction strength' var: Ai;
//	parameter 'Range of the repulsive interactions' var: Bi;
//	parameter 'Peception' var: lambda;
//	parameter 'Body contact strength' var: body;
//	parameter 'Body friction' var: friction;
	
	output
	{
		display SocialForceModel
		{
			species people;
			species wall;
		}

	}

}

