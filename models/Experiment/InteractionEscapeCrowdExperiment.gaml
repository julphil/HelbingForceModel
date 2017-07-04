/**
* Name: InteractionEscapeCrowdExperiment
* Author: julien
* Description: 
* Tags: Tag1, Tag2, TagN
*/

model InteractionEscapeCrowdExperiment

import "../Scheduler/InteractionScheduler.gaml"



experiment helbingPanicSimulation type: gui
{
	parameter 'Data file' var:dataFileName category:"Simulation parameter" init:"null";
	parameter 'Output file' var:outputFileName category:"Simulation parameter" init:"null";
	parameter 'Fluctuation type' var: fluctuationType among:["Speed","Vector"] init:"Speed" category:"Simulation parameter" ;
	parameter 'Delta T' var: deltaT category:"Simulation parameter" slider:false unit:"Second" init: 0.01;
	parameter 'Relaxation time' var: relaxation category:"Simulation parameter" unit:"Second" slider:false;
	parameter 'Respawn' var: isRespawn category:"Simulation parameter" init:false slider:false;
	parameter 'Fluctuation' var: isFluctuation category:"Simulation parameter" init:true;
	parameter 'Pedestrian speed' var: pedDesiredSpeed category:"Simulation parameter" unit:"m.s-1" slider:false;
	parameter 'Pedestrian maximum speed' var: pedMaxSpeed category:"Simulation parameter" unit:"m.s-1" slider:false init:6.0;
	parameter 'Pedestrian minimun size (radius)' var:pedSizeMin category:"Simulation parameter" unit:"m" slider:false;
	parameter 'Pedestrian maximum size (radius)' var:pedSizeMax category:"Simulation parameter" unit:"m" slider:false;
	parameter "Display force" var:arrow category:"Simulation parameter" init:false;
	parameter "Maximum people" var:max_people category:"Simulation parameter" init:500;
	parameter "Simulation duration" var:simulationDuration category:"Simulation parameter" init: 30000 unit:"cycle";
	parameter "Temporal Interval Lengrh" var:intervalLength category:"Simulation parameter" init:1000 unit:"cycle" min:1;
	
	
	parameter 'State changing type' var: stateChangingType among:["Always","Pure random","Random based on nervousness","Nervousness threshold"] init:"Always" category:"Interaction parameter" ;
	parameter 'State changing threshold' var: stateChangingThreshold category:"Interaction parameter" slider:false init:0.5;
	parameter 'Interaction choice' var: interactionType among:["One neighbour","Majority","Mean","Maximum"] init:"Mean" category:"Interaction parameter" ;
	parameter 'Neighbour choice' var: neighbourType among:["Closest","Random"] init:"Random" category:"Interaction parameter" ;
	parameter 'Has a 360° perception' var:is360 init:true category:"Interaction parameter" ;
	parameter "Interaction angle" var:angleInteraction init:40.0 max:360.0 min:0.0 category:"Interaction parameter"; 
	parameter 'Perception range' var:perceptionRange init:2.0 category:"Interaction parameter" slider:false;
	parameter 'Nervousness transmition' var:isNervousnessTransmition init:true category:"Interaction parameter";
	parameter 'Empathy' var:empathy init:0.5 category:"Interaction parameter";
	
	
	
	parameter 'Space length' var: spaceLength category:"Space parameter" unit:"Meter";
	parameter 'Space width' var: spaceWidth category:"Space parameter" unit:"Meter";
	
	parameter 'Interaction strength' var: Ai category:"Forces parameter" unit:"Newton";
	parameter 'Range of the repulsive interactions' var: Bi category:"Forces parameter" unit:"Meter";
	parameter 'Peception' var: lambda category:"Forces parameter" slider:false;
	parameter 'Body contact strength' var: body category:"Forces parameter" unit:"kg.s-2";
	parameter 'Body friction' var: friction category:"Forces parameter" unit:"kg.m-1.s-1";
	
	output
	{
		display SocialForceModel_display type:opengl
		{
			species interactionPeople;
			species wall;

           
			
		}
		
		display SocialForceModel_Field {
            species field aspect:aspectNervousness;
        }
        
        display SocialForceModel_FieldTotal {
            species field aspect:aspectNervousnessTotal;
        }
        
        display SocialForceModel_FieldTemporal {
            species field aspect:aspectNervousnessTemporal;
        }
        
		
		display SocialForceModel_NBinteractionPeople
		{
			chart "Number of interactionPeoples still inside " {
				data "nb_interactionPeople" value: nb_interactionPeople;
				
			}
			
			
		}
		
		display SocialForceModel_nervousnness
		{
			chart "global nervoussness" {
				data "global nervoussness" value: meanNervousness;
			}
		}
		
		display SocialForceModel_averageSpeed
		{
			chart "Average speed" {
				data "Average speed" value: averageSpeed;
				data "Average directed speed" value: meanOrientedSpeed/deltaT;
			}
		}
		
		display SocialForceModel_nervousPeople
		{
			chart "Number of nervous people" {
				data "Number of nervous people" value: nbNervoussPeople;
			}
		}
		
//		display SocialForceModel_nbColor
//		{
//			chart "Color number" {
//				data "Average speed" value: length(lcolor);
//			}
//		}
		monitor "Nb interactionPeople" value:nb_interactionPeople;
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
	parameter 'Space width' var: spaceWidth init:15;
	
	output
	{
		display SocialForceModel_graph
		{
			species interactionPeople aspect:graph;
		}
	}
}

experiment smallWorld type: gui parent:helbingPanicSimulation
{
		parameter 'Data file' init:"../Experiment/DataFiles/smallWorld.csv";
	
	parameter 'Space length' var: spaceLength init:10;
	parameter 'Space width' var: spaceWidth init:10;
	
	output
	{
		display SocialForceModel_graph
		{
			species interactionPeople aspect:graph;
		}
	}
}

experiment helbingRoom parent:helbingPanicSimulation
{
	parameter 'Data file' init:"../Experiment/DataFiles/roomsAndCorridor.csv";
	parameter 'Space length' var: spaceLength init:35;
	parameter 'Space width' var: spaceWidth init:19;
}

experiment corridorExit parent:helbingPanicSimulation
{
	parameter 'Data file' init:"../Experiment/DataFiles/corridorExit5/lambda3/corridorExit_1m.csv";
	parameter 'Space length' var: spaceLength init:60;
	parameter 'Space width' var: spaceWidth init:7;

	
	output
	{
		display SocialForce_ModelNervousnnessDistribution 
		{
			chart "Nervoussness Distribution" type:histogram
			{
				data "[0,[" value: nervousityDistribution[0];
				data "[5,[" value: nervousityDistribution[1];
				data "[10,[" value: nervousityDistribution[2];
				data "[15,[" value: nervousityDistribution[3];
				data "[20,[" value: nervousityDistribution[4];
				data "[25,[" value: nervousityDistribution[5];
				data "[30,[" value: nervousityDistribution[6];
				data "[35,[" value: nervousityDistribution[7];
				data "[40,[" value: nervousityDistribution[8];
				data "[45,[" value: nervousityDistribution[9];
				data "[50,[" value: nervousityDistribution[10];
				data "[55,[" value: nervousityDistribution[11];
			}
		}
		
		}
		
		
}


