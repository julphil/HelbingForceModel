/**
* Name: BasicCrowdExperiment
* Author: julien
* Description: 
* Tags: Tag1, Tag2, TagN
*/

model BasicCrowdExperiment

import "../Scheduler/BaseScheduler.gaml"



experiment helbingPanicSimulation type: gui
{
	parameter 'Headless mode' var:headless category:"Simulation parameter";
	parameter 'Generation type' var: type among:["random","lane"] init:"random" category:"Simulation parameter" ;
	parameter 'Delta T' var: deltaT category:"Simulation parameter" slider:false unit:"Second";
	parameter 'Relaxation time' var: relaxation category:"Simulation parameter" unit:"Second" slider:false;
	parameter 'Is Different group ?' var: isDifferentGroup category:"Simulation parameter";
	parameter 'Respawn' var: isRespawn category:"Simulation parameter";
	parameter 'Pedestrian number' var: number_of_people category:"Simulation parameter";
	parameter 'Pedestrian speed' var: pedDesiredSpeed category:"Simulation parameter" unit:"m.s-1" slider:false;
	
	parameter 'Space length' var: spaceLength category:"Space parameter" unit:"Meter";
	parameter 'Space width' var: spaceWidth category:"Space parameter" unit:"Meter";
	parameter 'Bottleneck size' var: bottleneckSize category:"Space parameter" unit:"Meter";
	
	parameter 'Interaction strength' var: Ai category:"Forces parameter" unit:"Newton";
	parameter 'Range of the repulsive interactions' var: Bi category:"Forces parameter" unit:"Meter";
	parameter 'Peception' var: lambda category:"Forces parameter" slider:false;
	parameter 'Body contact strength' var: body category:"Forces parameter" unit:"kg.s-2";
	parameter 'Body friction' var: friction category:"Forces parameter" unit:"kg.m-1.s-1";
	
	output
	{
		display SocialForceModel_display
		{
			species basePeople;
			species wall;

           
			
		}
		
		display SocialForceModel_NBinteractionPeople
		{
			chart "Number of interactionPeoples still inside " {
				data "nb_interactionPeople" value: nb_people;
				
			}
			
			
		}
		
		
		display SocialForceModel_averageSpeed
		{
			chart "Average speed" {
				data "Average speed" value: mean(basePeople collect norm(each.actual_velocity));
				data "Average directed speed" value: mean(basePeople collect each.orientedSpeed)/deltaT;
			}
		}
		monitor "Nb People" value:nb_people;
		monitor "time" value:cycle*deltaT;
		
	}

}

//A hallway where agent are already in lane configuaration
experiment helbingPanicSimulation_lane type: gui parent:helbingPanicSimulation
{
	parameter 'Generation type' init:"lane";
	parameter 'Pedestrian number' var: number_of_people init:40;
}

//One agent, not  a real simulation, but usefull to debug
experiment helbingPanicSimulation_uniqueAgent type: gui parent:helbingPanicSimulation
{
	parameter 'Pedestrian number' var: number_of_people init:1;
	parameter 'Space length' var: spaceLength init:10;
	parameter 'Space width' var: spaceWidth init:10;
	parameter 'Bottleneck size' var: bottleneckSize init:10.0;
}

//On group trying to pass a bottle neck
experiment helbingPanicSimulation_bottleneck_1group type: gui parent:helbingPanicSimulation
{
	parameter 'Is Different group ?' var: isDifferentGroup init:false;
	parameter 'Respawn' var: isRespawn init:false;
	parameter 'Pedestrian number' var: number_of_people init:40;
	parameter 'Space width' var: spaceWidth init:15;
	parameter 'Bottleneck size' var: bottleneckSize init:1.0;
}

//Two group trying to pass a bottleneck in diffrent direction
experiment helbingPanicSImulation_bottleneck_2group parent: helbingPanicSimulation_bottleneck_1group
{
	parameter 'Is Different group ?' var: isDifferentGroup init:true;
}



