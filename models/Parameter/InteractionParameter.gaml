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
	string stateChangingType;
	float  stateChangingThreshold min:0.01 max:1.0;
	string neighbourType;
	string interactionType;
	bool is360;
	float perceptionRange min:-1.0 max:30.0;
}

