/**
* Name: pedestrian
* Author: Julien Philippe
* Description:  Implementation of Helbing social force model
*/

model socialForceModel

global { 
	//Nombre de personne
	int number_of_agents min: 1 <- 2 ;
	
	int number_of_walls min: 0 <- 4;
	
	
	
	// taille du terrain
	int widthHeight min: 10 <- 50;
	
	
	int bottleneckSize min: 0 <- 10;
	
	int nd <- 0;
	int nbWalls <- 0;
	
	float relaxation <- 1.0;
	
	geometry shape <- square(widthHeight);
	
	init { 
		//Creation des personnes
		create people number: number_of_agents;
		create wall number: number_of_walls;
	}  
}  
  
//Les personnes
species people skills:[moving] {  
	// Couleur de l'agent
	rgb color;
	
	// Taille d'une personne
	float size <- 1.0;
	
	//Intensité de réaction du péton
	float Ai <- 5.0;
	
	//Seuil de réactivité
	float Bi <- 1.0;
	
	//Sensibilité du champs de vision [0,1] => 0 -> 0° et 1 -> 360°
	float lambda <- 0.6;
	
	// Destination
	point aim ;
	
	// Direction désiré
	point desired_direction;
	
	float desired_speed <- 1.0;
	
	point actual_velocity <- {0.0, 0,0};
	
	point social_repulsion_force_function {
		//Force de repulser des piétons
		point social_repulsion_force <- {0.0,0.0};
		
		ask people
		{
			if(self != myself) {
				point distanceCentre <- {myself.location.x - self.location.x, myself.location.y - self.location.y };
				float distance <- myself distance_to self;
				
				
				point nij <- {
					(myself.location.x - self.location.x)/norm(distanceCentre),
					(myself.location.y - self.location.y)/norm(distanceCentre)
				};
				
				
				float phiij <- -nij.x * myself.desired_direction.x + -nij.y * myself.desired_direction.y;
				
				social_repulsion_force <- {
					social_repulsion_force.x + (myself.Ai * exp( -distance/myself.Bi ) * nij.x * ( lambda + (1-lambda) * (1+phiij)/2)),
					social_repulsion_force.y + (myself.Ai * exp( -distance/myself.Bi ) * nij.y * ( lambda + (1-lambda) * (1+phiij)/2))
				};
			}
		}
		
		return social_repulsion_force;
	}
	
	point wall_repulsion_force_function {
		point wall_repulsion_force <- {0.0,0.0};
		
		ask wall
		{
			if(self != myself) {
				point distanceCenter <- {myself.location.x - self.location.x, myself.location.y - self.location.y };
				float distance <- myself distance_to self;
				
				point nij <- {
					(myself.location.x - self.location.x)/norm(distanceCenter),
					(myself.location.y - self.location.y)/norm(distanceCenter)
				};
				
				
				float phiij <- -nij.x * myself.desired_direction.x + -nij.y * myself.desired_direction.y;
				
				wall_repulsion_force <- {
					wall_repulsion_force.x + (myself.Ai * exp( -distance/myself.Bi ) * nij.x * ( myself.lambda + (1-myself.lambda) * (1+phiij)/2)),
					wall_repulsion_force.y + (myself.Ai * exp( -distance/myself.Bi ) * nij.y * ( myself.lambda + (1-myself.lambda) * (1+phiij)/2))
				};
			}
		}
		
		return wall_repulsion_force;
	}
	
	init {
		shape <- circle(size);
		if nd mod 2 = 0 { 
			color <- #black;
			location <- {widthHeight-rnd(widthHeight/2-1),rnd(widthHeight)};
			aim <- {0, location.y};
    	} else {
    		color <- #yellow;
    		location <- {0+rnd(widthHeight/2-1),rnd(widthHeight)};
    		aim <- {widthHeight, location.y};
    	}
		nd <- nd+1;
		
		desired_direction <- {(aim.x - location.x) / (abs(sqrt( (aim.x - location.x)*(aim.x - location.x) + (aim.y - location.y)*(aim.y - location.y)))), (aim.y - location.y) / (abs(sqrt( (aim.x - location.x)*(aim.x - location.x) + (aim.y - location.y)*(aim.y - location.y))))} ;
	}
	
	reflex sortie {
		if abs(location.x - aim.x) < 1 {
			if (aim.x = 0) {
				location <- {widthHeight,rnd(widthHeight)};
			} else {
				location <- {0,rnd(widthHeight)};
			}	
		}
	}
	
	reflex step {
		aim <- {aim.x, location.y};
		
		// Mettre à jour la direction désiré
		float norme <- sqrt( (aim.x - location.x)*(aim.x - location.x) + (aim.y - location.y)*(aim.y - location.y));
		desired_direction <- {(aim.x - location.x) / (abs(norme)), (aim.y - location.y) / (abs(norme))} ;
		
		/**
		 *  Calculer l'ensembles des forces
		 **/
		
		// force pour ateindre l'objectif 
		point force_mouvement <- {
				(desired_speed * desired_direction.x - actual_velocity.x)/relaxation,
				(desired_speed * desired_direction.y - actual_velocity.y)/relaxation
			};
			
		
		// calcul de la somme des forces
		point w <- {
			force_mouvement.x + social_repulsion_force_function().x + wall_repulsion_force_function().x,
			force_mouvement.y + social_repulsion_force_function().y + wall_repulsion_force_function().y
		};
		
		
		// déterminé la nouvelle acceleration
		float norme_w <- abs(sqrt(w.x * w.x + w.y * w.y));
		
		float max_velocity <- 1.3 * desired_speed; 
		
		if (norme_w <= max_velocity) {
			actual_velocity <- {actual_velocity.x + w.x,actual_velocity.y +  w.y};  
		} else {
			actual_velocity <- {
				w.x * ( max_velocity / norme_w),
				w.y * ( max_velocity / norme_w)
			};
		}
		
//		speed <- norm(actual_velocity);
//		
//		if speed != 0 {
//			heading <- acos((actual_velocity.x)/speed);
//			} else {
//				heading <-0;
//			}
			
//		write ""+ color.green + ": " + speed + "," + heading + "," + social_repulsion_force;
		
		//On vérifie qu'on est pas en dehors de la zone avant le déplcement
		float Locx;
		float Locy;
		
		
		if(location.x + actual_velocity.x >= 0-size and location.x + actual_velocity.x <= widthHeight+size) {
				Locx <- location.x + actual_velocity.x;
			} else {
				Locx <- location.x;
			}
		if( location.y + actual_velocity.y >= 0-size and location.y + actual_velocity.y <= widthHeight+size) {
			Locy <- location.y + actual_velocity.y;
		} else {
			Locy <- location.y;
		}
		
		location <- {Locx,Locy};
//		do move;
		
	}
	
	aspect default { 
		draw circle(size)  color: color;
	}

	
}


//Les Murs
species wall {
	float width;
	float length;
	  
	init {
		switch nbWalls {
			match 0 {length <- widthHeight + 0.0; width <- 1.0;shape <- rectangle(length,width);location <- {widthHeight/2,0.5};}
			match 1 {length <- widthHeight + 0.0; width <- 1.0;shape <- rectangle(length,width);location <- {widthHeight/2,widthHeight-0.5};}
			match 2 {length <- 1.0; width <- widthHeight/2-1.0-bottleneckSize/2;shape <- rectangle(length,width);location <- {widthHeight/2.0,width/2+1};}
			match 3 {length <- 1.0; width <- widthHeight/2-1.0-bottleneckSize/2;shape <- rectangle(length,width);location <- {widthHeight/2.0,widthHeight/2-1.0-bottleneckSize/2+bottleneckSize + width/2+1};}
		}
		nbWalls <- nbWalls +1;
	}
	
	aspect default { 
		draw rectangle(length,width)  color: rgb(0,0,0);
	}
}


experiment helbing type: gui {
	parameter 'Nombre de personne' var: number_of_agents;
	parameter 'Taille du terrain' var:widthHeight;
	parameter 'Bottleneck size' var: bottleneckSize;
	output {
		display SocialForceModel{
			species people;
			species wall;
		}
	}
}