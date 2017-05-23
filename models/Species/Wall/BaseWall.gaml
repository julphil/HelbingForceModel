/**
* Name: BaseWall
* Author: julien
* Description: 
* Tags: Tag1, Tag2, TagN
*/

model BaseWall

import "../../Parameter/BaseParameter.gaml"

species wall schedules: []
{
	float width;
	float length;
	float locationX;
	float locationY;
	
	init
	{
		location <- {locationX,locationY};
		shape <- rectangle(length, width);
	}
	

	aspect default
	{
		draw rectangle(length, width) color: rgb(0, 0, 0);
	}

}

