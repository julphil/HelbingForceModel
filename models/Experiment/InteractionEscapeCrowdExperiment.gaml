/**
* Name: InteractionEscapeCrowdExperiment
* Author: Julien PHILIPPE
* Description: 
*/

model InteractionEscapeCrowdExperiment

import "../Scheduler/InteractionScheduler.gaml"

experiment helbingPanicSimulation type: gui
{
	parameter 'Configuration id' var: id_configuration init:15 ;
	parameter 'Simulation set id' var: id_simulationset init:2 ;
	
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
		
		/*display SocialForceModel_nervousnness
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
		}*/
		
		monitor "Nb interactionPeople" value:nb_interactionPeople;
		monitor "Leaving time" value:lastCycle*deltaT;
		
	}

}

experiment MAIN_EXPERIMENT_corridorExit parent:helbingPanicSimulation
{
	parameter 'Space length' var: spaceLength init:60;
	parameter 'Space width' var: spaceWidth init:7;
	parameter 'Demonstration mode (not registering)' var:demonstrationMode init:true;

	
	output
	{
//		display SocialForce_ModelNervousnnessDistribution 
//		{
//			chart "Nervoussness Distribution" type:histogram
//			{
//				data "[0,[" value: nervousityDistribution[0];
//				data "[5,[" value: nervousityDistribution[1];
//				data "[10,[" value: nervousityDistribution[2];
//				data "[15,[" value: nervousityDistribution[3];
//				data "[20,[" value: nervousityDistribution[4];
//				data "[25,[" value: nervousityDistribution[5];
//				data "[30,[" value: nervousityDistribution[6];
//				data "[35,[" value: nervousityDistribution[7];
//				data "[40,[" value: nervousityDistribution[8];
//				data "[45,[" value: nervousityDistribution[9];
//				data "[50,[" value: nervousityDistribution[10];
//				data "[55,[" value: nervousityDistribution[11];
//			}
//		}
		
		display SocialForce_Passing
		{
			chart "BottleNeck Passing" {
				data "Nb people passing/seconde" value:peoplePass/(cycle+1)/deltaT;
			}
		}
		
		}
		
		
}

