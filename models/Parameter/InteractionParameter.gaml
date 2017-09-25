/**
* Name: InteractionParameter
* Author: julien
* Description: 
* Tags: Tag1, Tag2, TagN
*/

model InteractionParameter

global
{
	//Propagation parameter
	string interactionType;
	bool is360;
	float perceptionRange min:-1.0 max:30.0;
	bool isNervousnessTransmition;
	float empathy <- 0.0;
	float angleInteraction;
	
	//Duration of the interval in which we mesure nervousness in the simulated space
	int intervalLength;
	
	//If true, the interaction graph must be write in a file
	bool graphOutput;
}

