/**
* Name: pedestrian
* Author: Julien Philippe
* Description:  Implementation of Helbing social force model
*/
model socialForceModel


global
{
	int number_of_agents min: 1 <- 2;
	int number_of_walls min: 0 <- 4;

	//space dimension
	int spaceWidth min: 5 <- 30;
	int spaceLength min: 5 <- 50;
	int bottleneckSize min: 0 <- 10;

	//incremental var use in species init
	int nd <- 0;
	int nbWalls <- 0;

	//Acceleration relaxation time
	float relaxation <- 1.0;
	
	//Interaction strength
	float Ai min:0.0 <- 5.0;

	//Range of the repulsive interactions
	float Bi min:0.0 <- 2.0;
	
	//Peception [0,1] => 0 -> 0° and 1 -> 360°
	float lambda min:0.0 max:1.0 <- 0.5;

	//Space shape
	geometry shape <- rectangle(spaceLength, spaceWidth);
	init
	{
		create people number: number_of_agents;
		create wall number: number_of_walls;
	}

}

species people skills: [moving]
{
	rgb color;
	float size <- 1.0;

	

	// Destination
	point aim;
	point desired_direction;
	float desired_speed <- 1.0;
	point actual_velocity <- { 0.0, 0, 0 };
	point social_repulsion_force_function
	{
		point social_repulsion_force <- { 0.0, 0.0 };
		ask people
		{
			if (self != myself)
			{
				point distanceCenter <- { myself.location.x - self.location.x, myself.location.y - self.location.y };
				float distance <- myself distance_to self;
				point nij <- { (myself.location.x - self.location.x) / norm(distanceCenter), (myself.location.y - self.location.y) / norm(distanceCenter) };
//				float phiij <- -nij.x * myself.desired_direction.x + -nij.y * myself.desired_direction.y;
				float phiij <- -nij.x * actual_velocity.x/(norm(actual_velocity)+0.0000001) + -nij.y * actual_velocity.x/(norm(actual_velocity)+0.0000001);
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
		ask wall
		{
			if (self != myself)
			{
				point distanceCenter <- { myself.location.x - self.location.x, myself.location.y - self.location.y };
				float distance <- myself distance_to self;
				point nij <- { (myself.location.x - self.location.x) / norm(distanceCenter), (myself.location.y - self.location.y) / norm(distanceCenter) };
				float phiij <- -nij.x * myself.desired_direction.x + -nij.y * myself.desired_direction.y;
				wall_repulsion_force <- {
				wall_repulsion_force.x + (Ai * exp(-distance / Bi) * nij.x * (lambda + (1 - lambda) * (1 + phiij) / 2)), wall_repulsion_force.y + (Ai * exp(-distance / Bi) * nij.y * (lambda + (1 - lambda) * (1 + phiij) / 2))
				};
			}

		}

		return wall_repulsion_force;
	}

	init
	{
		shape <- circle(size);
		if nd mod 2 = 0
		{
			color <- # black;
			location <- { spaceLength - rnd(spaceLength / 2 - 1), rnd(spaceWidth - 1 - size) + 1 + size };
			aim <- { -size, location.y };
		} else
		{
			color <- # yellow;
			location <- { 0 + rnd(spaceLength / 2 - 1), rnd(spaceWidth - 1 - size) + 1 + size };
			aim <- { spaceLength+size, location.y };
		}

		nd <- nd + 1;
		desired_direction <- {
		(aim.x - location.x) / (abs(sqrt((aim.x - location.x) * (aim.x - location.x) + (aim.y - location.y) * (aim.y - location.y)))), (aim.y - location.y) / (abs(sqrt((aim.x - location.x) * (aim.x - location.x) + (aim.y - location.y) * (aim.y - location.y))))
		};
	}

	reflex sortie
	{
		if location.x >= spaceLength
		{
			location <- { 0, rnd(spaceWidth - 1 - size) + 1 + size };
		} else if location.x <= 0
		{
			location <- { spaceLength, rnd(spaceWidth - 1 - size) + 1 + size };
		}

	}

	reflex step
	{
		aim <- { aim.x, location.y };

		//update the goal direction
		float norme <- sqrt((aim.x - location.x) * (aim.x - location.x) + (aim.y - location.y) * (aim.y - location.y));
		desired_direction <- { (aim.x - location.x) / (norme + 0.000000001), (aim.y - location.y) / (norme + 0.000000001) };

		//Goal attraction force
		point goal_attraction_force <- { (desired_speed * desired_direction.x - actual_velocity.x) / relaxation, (desired_speed * desired_direction.y - actual_velocity.y) / relaxation };

		// Sum of the forces
		point force_sum <- {
		goal_attraction_force.x + social_repulsion_force_function().x + wall_repulsion_force_function().x, goal_attraction_force.y + social_repulsion_force_function().y + wall_repulsion_force_function().y
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
		float Locx;
		float Locy;
		if (location.x + actual_velocity.x >= 0 - size and location.x + actual_velocity.x <= spaceLength + size)
		{
			Locx <- location.x + actual_velocity.x;
		} else
		{
			Locx <- location.x;
		}

		if (location.y + actual_velocity.y >= 0 - size and location.y + actual_velocity.y <= spaceWidth + size)
		{
			Locy <- location.y + actual_velocity.y;
		} else
		{
			Locy <- location.y;
		}

		location <- { Locx, Locy };
		write location;
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
			}

			match 1
			{
				length <- spaceLength + 0.0;
				width <- 1.0;
				shape <- rectangle(length, width);
				location <- { spaceLength / 2, spaceWidth - 0.5 };
			}

			match 2
			{
				length <- 1.0;
				width <- spaceWidth / 2 - 1.0 - bottleneckSize / 2;
				shape <- rectangle(length, width);
				location <- { spaceLength / 2.0, width / 2 + 1 };
			}

			match 3
			{
				length <- 1.0;
				width <- spaceWidth / 2 - 1.0 - bottleneckSize / 2;
				shape <- rectangle(length, width);
				location <- { spaceLength / 2.0, spaceWidth / 2 - 1.0 - bottleneckSize / 2 + bottleneckSize + width / 2 + 1 };
			}

		}

		nbWalls <- nbWalls + 1;
	}

	aspect default
	{
		draw rectangle(length, width) color: rgb(0, 0, 0);
	}

}

experiment helbing type: gui
{
	parameter 'Pedestrian number' var: number_of_agents;
	parameter 'Space length' var: spaceLength;
	parameter 'Space width' var: spaceWidth;
	parameter 'Bottleneck size' var: bottleneckSize;
	parameter 'Interaction strength' var: Ai;
	parameter 'Range of the repulsive interactions' var: Bi;
	parameter 'Peception' var: lambda;
	output
	{
		display SocialForceModel
		{
			species people;
			species wall;
		}

	}

}