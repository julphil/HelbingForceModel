/**
* Name: BaseWall
* Author: julien
* Description: 
* Tags: Tag1, Tag2, TagN
*/

model BaseWall

import "../../Parameter/InteractionParameter.gaml"

species wall schedules: []
{
	float width;
	float length;
	//Location of the center of the wall, (not the upper left angle)
	float locationX;
	float locationY;
	
	string type;
	
	init
	{
		location <- {locationX,locationY};
		if type = "rectangle"
		{
			shape <- rectangle(length, width);
		}
		else if type = "circle"
		{
			shape <- circle(length);
		}
	}
	

	aspect default
	{
		if type = "rectangle"
		{
			draw rectangle(length, width) color: rgb(0, 0, 0);
		}
		else if type = "circle"
		{
			draw circle(length) color: rgb(0, 0, 0);
		}
	}

}

