/**
* Name: socialForceModel
* Author: laurent
* Description:  Implementation of Helbing social force model
* Tags: Tag1, Tag2, TagN
*/

model socialForceModel

global { 
	//Nombre de personne
	int number_of_agents min: 1 <- 2 ;
	
	int number_of_middle_walls min: 0 <- 40;
	
	
	
	// taille du terrain
	int widthHeight min: 10 <- 50;
	
	int number_of_side_walls <- widthHeight*2;
	
	int bottleneckSize <- 10;
	
	int nd <- 0;
	int nbMiddleWall <- 0;
	int nbSideWall <- 0;
	
	float delta <- 2.0;
	
	float relaxation <- 1.0;
	
	float phi <- 100.0;
	
	float c <- 0.5;
	
	float sigma <- 0.3;
	
	float Vab <- 2.1;
	
	float Uab <- 10.0;
	
	float R <- 0.2;
	
	geometry shape <- square(widthHeight);
	
	init { 
		//Creation des personnes
		create people number: number_of_agents;
		create wall number: number_of_middle_walls + number_of_side_walls;
	}  
}  
  
//Les personnes
species people skills:[moving] {  
	// Couleur de l'agent
	rgb color;
	
	// Taille d'une personne
	float size <- 1.0;
	
	//Intensité de réaction du péton
	float Ai <- 2.0;
	
	//Seuil de réactivité
	float Bi <- 2.0;
	
	//Sensibilité du champs de vision [0,1] => 0 -> 0° et 1 -> 360°
	float lambda <- 0.25;
	
	// Destination
	point aim ;
	
	// Direction désiré
	point desired_direction;
	
	float desired_speed <- 1;
	
	point actual_velocity <- {0.0, 0,0};
	
	init {
		if nd mod 2 = 0 { 
			color <- #black;
			location <- {widthHeight-rnd(5),rnd(widthHeight)};
			//location <- {widthHeight,widthHeight/2.0+1}; 
			aim <- {0, location.y};
    	} else {
    		color <- #yellow;
    		location <- {0+rnd(5),rnd(widthHeight)};
    		//location <- {0,widthHeight/2.0-1};
    		aim <- {widthHeight, location.y};
    	}
		nd <- nd+1;
		
		desired_direction <- {(aim.x - location.x) / (abs(sqrt( (aim.x - location.x)*(aim.x - location.x) + (aim.y - location.y)*(aim.y - location.y)))), (aim.y - location.y) / (abs(sqrt( (aim.x - location.x)*(aim.x - location.x) + (aim.y - location.y)*(aim.y - location.y))))} ;
	}
	
	/*reflex change {
		if ( abs(location.x - aim.x) < 1 and abs(location.y - aim.y) < 1 ) {
			aim <- {rnd(widthHeight)as int, rnd(widthHeight)as int};
			actual_velocity <- {0,0};
		} 
	}*/
	
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
		 *  Calculé l'ensembles des forces
		 **/
		
		// force pour ateindre l'objectif 
		point force_mouvement <- {
				(desired_speed * desired_direction.x - actual_velocity.x)/relaxation,
				(desired_speed * desired_direction.y - actual_velocity.y)/relaxation
			};
			
		//Force de repulser des piétons
		point social_repulsion_force <- {0.0,0.0};
		
			
		ask people
		{
			if(self != myself) {
				point distance <- {myself.location.x - self.location.x, myself.location.y - self.location.y };
				float dij <- sqrt(distance.x * distance.x + distance.y * distance.y);
				
				float rij <- myself.size/2.0 + self.size/2.0;
				
				
				point nij <- {
					(myself.location.x - self.location.x)/dij,
					(myself.location.y - self.location.y)/dij
				};
				
				
				float phiij <- -nij.x * myself.desired_direction.x + -nij.y * myself.desired_direction.y;
				
				social_repulsion_force <- {
					social_repulsion_force.x + (myself.Ai * exp( (rij-dij)/myself.Bi ) * nij.x * ( lambda + (1-lambda) * (1+phiij)/2)),
					social_repulsion_force.y + (myself.Ai * exp( (rij-dij)/myself.Bi ) * nij.y * ( lambda + (1-lambda) * (1+phiij)/2))
				};
			}
		}
		
		point wall_repulsion_force <- {0.0,0.0};
		
		ask wall
		{
			if(self != myself) {
				point distance <- {myself.location.x - self.location.x, myself.location.y - self.location.y };
				float dij <- sqrt(distance.x * distance.x + distance.y * distance.y);
				
				float rij <- myself.size/2.0 + self.size/2.0;
				
				
				point nij <- {
					(myself.location.x - self.location.x)/dij,
					(myself.location.y - self.location.y)/dij
				};
				
				
				float phiij <- -nij.x * myself.desired_direction.x + -nij.y * myself.desired_direction.y;
				
				social_repulsion_force <- {
					social_repulsion_force.x + (myself.Ai * exp( (rij-dij)/myself.Bi ) * nij.x * ( myself.lambda + (1-myself.lambda) * (1+phiij)/2)),
					social_repulsion_force.y + (myself.Ai * exp( (rij-dij)/myself.Bi ) * nij.y * ( myself.lambda + (1-myself.lambda) * (1+phiij)/2))
				};
			}
		}
		
		// calcul de la somme des forces
		point w <- {force_mouvement.x + social_repulsion_force.x + wall_repulsion_force.x,force_mouvement.y + social_repulsion_force.y + wall_repulsion_force.y};
		
		
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
			
		write ""+ color.green + ": " + speed + "," + heading + "," + social_repulsion_force;
		
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
		draw circle(1)  color: color;
	}
}


//Les Murs
species wall {  
	
	float size <- 1.0;
	
	init {
		if(nbMiddleWall < number_of_middle_walls) {
			if(nbMiddleWall <= number_of_middle_walls/2) {
				location <- {widthHeight/2.0, nbMiddleWall+1};
				} else {
					location <- {widthHeight/2.0, nbMiddleWall + bottleneckSize};
				}
			nbMiddleWall <- nbMiddleWall+1;
		}
		else if (nbSideWall <= number_of_side_walls/2) {
				location <- {nbSideWall,0};
				nbSideWall <- nbSideWall+1;
			} else {
				location <- {nbSideWall-widthHeight,widthHeight};
				nbSideWall <- nbSideWall+1;
			}
	}
	
	aspect default { 
		draw square(1)  color: rgb(0,0,0);
	}
}


experiment helbing type: gui {
	parameter 'Nombre de personne' var: number_of_agents;
	parameter 'Taille du terrain' var:widthHeight;
	output {
		display SocialForceModel{
			species people;
			species wall;
		}
	}
}