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
 
 	//Interaction agent
 	list<interactionPeople> interaction;
 	
	init
	{
		self.size <- pedSize;
		self.desired_speed <- pedDesiredSpeed;
		max_velocity <- 1.3 * desired_speed;
		
		shape <- circle(size);
		//In this version, you can have one group of black agent going left. Or two group with the same black group plus a yellow group going rigth
		if nd mod 2 = 0 or !isDifferentGroup
		{
			//d_color <- # black;
			d_color <- rnd_color(255);
			if(type="random") {
//				HERElocation <- { spaceLength - rnd(spaceLength / 2 - 1), rnd(spaceWidth - (1 + size)*2) + 1 + size };
				location <- { spaceLength - rnd(spaceLength - 3), rnd(spaceWidth - (1 + size)*2) + 1 + size };
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
		
		//Initilasation of the noise
		normal_fluctuation <- { gauss(0,0.01),gauss(0,0.01)};
		maximum_fluctuation <- {0,0};
              
		loop while:(norm(maximum_fluctuation) < norm(normal_fluctuation))
		{
	   		maximum_fluctuation <- { gauss(0,desired_speed*2.6),gauss(0,desired_speed*2.6)};    
		}
		
		color <- d_color;
		n_color <- d_color;
	}

	action interactionClean
	{
		interaction <- [];
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
				float distanceCenter <- norm({ myself.location.x - self.location.x, myself.location.y - self.location.y });
				float distance <- distanceCenter -(self.size+myself.size);
				point nij <- { (myself.location.x - self.location.x) / distanceCenter, (myself.location.y - self.location.y) / distanceCenter };
				//float phiij <- -nij.x * actual_velocity.x / (norm(actual_velocity) + 0.0000001) + -nij.y * actual_velocity.x / (norm(actual_velocity) + 0.0000001);
				float phiij <- -nij.x * desired_direction.x + -nij.y * desired_direction.y;
				float vision <- (lambda + (1 - lambda) * (1 + phiij) / 2);
				float repulsion <- Ai * exp(-distance / Bi);
				
				if ((perceptionRange < 0.0 or distance < perceptionRange) and (is360 or vision > 0.90 ))
				{
					add self to: myself.interaction;
				}
				
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
		if( !empty(interaction) and ( 
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
						r <- r+ p.color.red;
						g <- g+ p.color.green;
						b <- b+ p.color.blue;
					}
				}
				
				n_color <- rgb(r/le,g/le,b/le);
				
			}		
		}
}
	
	action colorPropagation
	{
		color <- n_color;
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
