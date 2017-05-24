/**
* Name: EscapeCrowdExperiment
* Author: julien
* Description: 
* Tags: Tag1, Tag2, TagN
*/

model EscapeCrowdExperiment

import "../Scheduler/PanicScheduler.gaml"

experiment helbingPanicSimulation type: gui
{
	parameter 'Data file' var:dataFileName category:"Simulation parameter" init:"null";
	parameter 'Fluctuation type' var: fluctuationType among:["Speed","Vector"] init:"Vector" category:"Simulation parameter" ;
	parameter 'Delta T' var: deltaT category:"Simulation parameter" slider:false unit:"Second";
	parameter 'Relaxation time' var: relaxation category:"Simulation parameter" unit:"Second" slider:false;
	parameter 'Respawn' var: isRespawn category:"Simulation parameter" init:false;
	parameter 'Fluctuation' var: isFluctuation category:"Simulation parameter";
	parameter 'Pedestrian speed' var: pedDesiredSpeed category:"Simulation parameter" unit:"m.s-1" slider:false;
	parameter 'Pedestrian maximum speed' var: pedMaxSpeed category:"Simulation parameter" unit:"m.s-1" slider:false init:6.0;
	parameter 'Pedestrian minimun size' var:pedSizeMin category:"Simulation parameter" unit:"m" slider:false;
	parameter 'Pedestrian maximum size' var:pedSizeMax category:"Simulation parameter" unit:"m" slider:false;
	parameter "Display force" var:arrow category:"Simulation parameter" init:false;
	
	parameter 'Space length' var: spaceLength category:"Space parameter" unit:"Meter";
	parameter 'Space width' var: spaceWidth category:"Space parameter" unit:"Meter";
	
	parameter 'Interaction strength' var: Ai category:"Forces parameter" unit:"Newton";
	parameter 'Range of the repulsive interactions' var: Bi category:"Forces parameter" unit:"Meter";
	parameter 'Peception' var: lambda category:"Forces parameter" slider:false;
	parameter 'Body contact strength' var: body category:"Forces parameter" unit:"kg.s-2";
	parameter 'Body friction' var: friction category:"Forces parameter" unit:"kg.m-1.s-1";
	
	output
	{
		display SocialForceModel_display
		{
			species panicPeople;
			species wall;

           
			
		}
		
		display SocialForceModel_NBPeople
		{
			chart "Number of interactionPeoples still inside " {
				data "nb_People" value: nb_panicPeople;
				
			}	
		}
		
		
		display SocialForceModel_nervousnness
		{
			chart "global nervoussness" {
				data "global nervoussness" value: mean(panicPeople collect each.nervousness);
			}
		}
		
		display SocialForceModel_averageSpeed
		{
			chart "Average speed" {
				data "Average speed" value: mean(panicPeople collect norm(each.actual_velocity));
				data "Average directed speed" value: mean(panicPeople collect each.orientedSpeed)/deltaT;
			}
		}
		
		monitor "Nb people" value:nb_panicPeople;
		monitor "Leaving time" value:lastCycle*deltaT;
	}

}

//One agent, not  a real simulation, but usefull to debug
experiment helbingPanicSimulation_uniqueAgent type: gui parent:helbingPanicSimulation
{
	parameter 'Data file' init:"../Experiment/DataFiles/singleAgent.csv";
	
	parameter 'Pedestrian number' var: number_of_people init:1;
	parameter 'Space length' var: spaceLength init:10;
	parameter 'Space width' var: spaceWidth init:10;
}

//On group trying to pass a bottle neck
experiment helbingPanicSimulation_bottleneck_1group type: gui parent:helbingPanicSimulation
{
	parameter 'Data file' init:"../Experiment/DataFiles/oneRoomOneExit.csv";
	
	parameter 'Respawn' var: isRespawn init:false;
	parameter 'Pedestrian number' var: number_of_people init:40;
	parameter 'Space width' var: spaceWidth init:15;
}

//Two group trying to pass a bottleneck in diffrent direction
experiment helbingPanicSImulation_bottleneck_2group parent: helbingPanicSimulation_bottleneck_1group
{
	parameter 'Data file' init:"../Experiment/DataFiles/twoGroupBottleNeck.csv";
	
}

experiment helbingRoom parent:helbingPanicSimulation
{
	parameter 'Data file' init:"../Experiment/DataFiles/roomsAndCorridor.csv";
	parameter 'Space length' var: spaceLength init:35;
	parameter 'Space width' var: spaceWidth init:19;
}



