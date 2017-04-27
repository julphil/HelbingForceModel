/**
* Name: InteractionEscapeCrowdSpeciesWall
* Author: julien
* Description: 
* Tags: Tag1, Tag2, TagN
*/

model SpeciesWall

import "../../Parameter/BaseParameter.gaml"

species wall schedules: []
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
				length <- 1.0;
				width <- spaceWidth / 2 - 1.0 - bottleneckSize / 2;
				shape <- rectangle(length, width);
				//HERElocation <- { spaceLength / 2.0, width / 2 + 1 };
				location <- { 2.0, width / 2 + 1 };
				break;
			}

			match 3
			{
				length <- 1.0;
				width <- spaceWidth / 2 - 1.0 - bottleneckSize / 2;
				shape <- rectangle(length, width);
				//HERElocation <- { spaceLength / 2.0, spaceWidth / 2 - 1.0 - bottleneckSize / 2 + bottleneckSize + width / 2 + 1 };
				location <- { 2, spaceWidth / 2 - 1.0 - bottleneckSize / 2 + bottleneckSize + width / 2 + 1 };
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

