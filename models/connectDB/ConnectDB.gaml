/**
* Name: ConnectDB
* Author: julienlitis
* Description: 
* Tags: Tag1, Tag2, TagN
*/

model ConnectDB

import "../Species/People/InteractionPeople.gaml"

species connection skills:[SQLSKILL] {
	
	bool connect;
	
	map<string, string>  POSTGRES <- [
                                        'host'::'localhost',
                                        'dbtype'::'postgres',
                                        'database'::'gamaexp',
                                        'port'::'5432',
                                        'user'::'gama',
                                        'passwd'::'gama'];
    
    map parameter;
    
    list<map> agentset;
    
    list<map> walls;
    
    int id_configuration;
    
    int id_simulation;
    
    date datedebut;
                                        
    init {
    	connect <- testConnection(params:POSTGRES);
		
		datedebut <- date("now");

        //Parameter     
        list<list> t <-   list<list> (self select(params:POSTGRES, 
                         select:"SELECT name,commentaire,typeConfig,fluctuationType,deltaT,relaxationTime,isRespawn,isFluctuation,pedestrianSpeed,pedestrianMaxSpeed,pedestrianMaxSize,pedestrianMinSize,simulationDuration,temporalFieldIntervalLength,interactionType,is360,interactionAngle,interactionRange,isNervousnessTransmition,interactionParameter,spaceLength,spaceWidth,socialForceStrength,socialForceThreshold,socialForceVision,bodyContactStrength,bodyFrictionStrength,isNervousness, threshold 
							FROM configuration c INNER JOIN parameterset p on c.id_parameterset = p.id_parameterset WHERE id_configuration = ?;"
							, values:[id_configuration]));
    	
    	
    	loop i from:0 to: length(t[0])-1 {
    		add t[0][i]::t[2][0][i] to: parameter;
    	}
    	
    	
    	//Agent set
    	t <- list<list> (self select(params:POSTGRES, 
                         select:"SELECT  id_agentset,paramgeneration,ispoisson,color 
									FROM agentset a WHERE EXISTS 
										(SELECT id_agentset FROM includeagent b WHERE id_configuration = ? AND b.id_agentset = a.id_agentset);"
							, values:[id_configuration]));

    	
    	
    	loop i from:0 to: length(t[2])-1 {
    		map tmp;
    		
    		loop j from:0 to: length(t[0])-1 {
    			add t[0][j]::t[2][i][j] to: tmp;
    		}
    		
    		
    		//Area link to agentset	
    		list<list> t2 <- list<list> (self select(params:POSTGRES, 
                         select:"SELECT a.id_area,coordltx,coordlty,coordrdx,coordrdy 
									FROM includeagent i INNER JOIN area a ON i.id_area = a.id_area where id_configuration = ? and id_agentset = ? ORDER BY listorder;"
							, values:[id_configuration,t[2][i][0]]));
							
			list<map> zone;
			loop j from:0 to:length(t2[2])-1{
				map tmp2;
				
				loop k from:0 to:length(t2[0])-1{
					add t2[0][k]::t2[2][j][k] to: tmp2;
				}
				add tmp2 to:zone;
    		}
    		
    		add "ZONE"::zone to: tmp;
    		add tmp to: agentset;
    	}
    	    	    	
    	//Walls
    	t <- list<list> (self select(params:POSTGRES, 
                         select:"SELECT o.id_obstacle,id_wall,coordx,coordy,largeur,longueur 
									FROM includeobstacle i INNER JOIN obstacle o ON i.id_obstacle = o.id_obstacle INNER JOIN wall w ON o.id_obstacle = w.id_obstacle WHERE id_configuration = ?;"
							, values:[id_configuration]));
							

    	loop i from:0 to: length(t[2])-1 {
    		map tmp;

    		loop j from:0 to: length(t[0])-1 {
    			add t[0][j]::t[2][i][j] to: tmp;
    		}

    		add tmp to: walls;

    	}
		
    	
    }
    
    
    action initTable
    {
    	
    	//INSERT Iin simulation
		list<list> t <- list<list> (self select(params:POSTGRES, 
                         select:"WITH row AS (
							INSERT INTO simulation (id_configuration,date_depart,date_fin) VALUES (?,'"+ datedebut +"','" + date("now") + "') RETURNING id_simulation )
							SELECT id_simulation
							FROM row;"
							,values:[id_configuration]));	
		
		id_simulation <- int(t[2][0][0]);
    	
    	t <- list<list> (self select(params:POSTGRES, 
                         select:"WITH row AS (
							INSERT INTO partofaset (id_simulationset, id_simulation ) VALUES (" + id_simulationset + ","+ id_simulation + ") RETURNING id_simulation )
							SELECT id_simulation
							FROM row;"
							));	
		
		
		list<string> agentRecord;
		string valueInsert <- "INSERT INTO Agent (sim_id,size,coorspawnax,coorspawnay,coorspawnbx,coorspawnby,spawntime,id_simulation)\nVALUES\n";
		ask interactionPeople
    	{
    		string record <- "(" + int(self) + "," + size + "," + pointAX + "," + pointAY + "," + pointBX + "," + pointBY + "," + spawnTime + "," + myself.id_simulation + ")";
    		add record to: agentRecord;
    		
    	}
	    	
	    	
	    	
    	int l <- length(agentRecord);
    	loop i from:0 to:l-2
    	{
    		valueInsert <- valueInsert + agentRecord[i] + ",\n";
    	}
    	
	    	
    	valueInsert <- valueInsert + agentRecord[l-1];
    	
    	t <- list<list> (self select(params:POSTGRES, 
                         select:"WITH row AS (" + valueInsert +" RETURNING id_agent )
							SELECT id_agent
							FROM row;"
							));	
    }
    
    action insertRealStartTime(int realStart)
    {
    	string valueInsert <- "Update Simulation set activation_step = " + realStart + " where id_simulation = " + id_simulation;
    	
    	int n <-  executeUpdate (params: POSTGRES, 
                                       updateComm: valueInsert );
    	
    }
    
    action recordAgentState
    {
    	list<list> t;
    	string valueInsert <- "INSERT INTO State (step,sim_id,id_simulation,states)\nVALUES\n";
    	list<string> agentRecord;
    	
    	ask interactionPeople
	    	{
	    		if (isActive or wasActive)
	    		{
		    		string record <- "(" + int(cycle) + "," + int(self) + "," + myself.id_simulation +  ",";
		    		record <- record + "'{"; 
		    		
		    		loop i from:0 to:length(recordData)-2
		    		{
		    			record <- record + "{";
		    			loop j from:0 to:length(recordData[i])-2
		    			{
		
		    				record <- record + float(recordData[i][j]);
		    				record <- record + ","; 
		    			}
		    			record <- record + float(recordData[i][length(recordData[i])-1]);
		    			
		    			record <- record + "},"; 
		    		}
		    		record <- record + "{";
		    		
		    		loop j from:0 to:length(recordData[length(recordData)-1])-2
		    			{
		    				record <- record + float(recordData[length(recordData)- 1][j]);
		    				record <- record + ","; 
		    			}
		    			record <- record + float(recordData[length(recordData)- 1][length(recordData[length(recordData)- 1])-1]);	
		    		record <- record + "}"; 
		    		
		    		
		    		record <- record + "}'"; 
		
		    		
		    		record <- record + ")"; 
		    		add record to: agentRecord;
	    		}
	    		
	    	}
	    	
	    	int l <- length(agentRecord);
	    	loop i from:0 to:l-2
	    	{
	    		valueInsert <- valueInsert + agentRecord[i] + ",\n";
	    	}
	    	
	    	
	    	valueInsert <- valueInsert + agentRecord[l-1];
	    	
	    	t <- list<list> (self select(params:POSTGRES, 
	                         select:"WITH row AS (" + valueInsert +" RETURNING id_state )
								SELECT id_state
								FROM row;"
								));	
								
			ask interactionPeople
			{
				recordData <- [];
				
				if wasActive and !isActive
				{
					wasActive <- false;
				}
			}
    }
    
    action finalRecord
    {
    	list<list> t;
    	
    	//Push the information on the db that the simulation is over
    	int n <- executeUpdate(params:POSTGRES,updateComm:"UPDATE simulation SET isOver = 't',date_fin = current_timestamp WHERE id_simulation = ?",values:[id_simulation]);
    	
    	//Lauch the stocked process to analyse the simulation and insert result in tmpanalysetable
    	t <- list<list> (self select(params:POSTGRES, 
                         select:"SELECT analyse_simulation(?);"
							,values:[id_simulation]));	
    	/*
    	//INSERT Iin simulation
		t <- list<list> (self select(params:POSTGRES, 
                         select:"WITH row AS (
							INSERT INTO simulation (id_configuration,date_depart,date_fin) VALUES (?,'"+ datedebut +"','" + date("now") + "') RETURNING id_simulation )
							SELECT id_simulation
							FROM row;"
							,values:[id_configuration]));	
		
		id_simulation <- int(t[2][0][0]);
    	
    	t <- list<list> (self select(params:POSTGRES, 
                         select:"WITH row AS (
							INSERT INTO partofaset (id_simulationset, id_simulation ) VALUES (" + id_simulationset + ","+ id_simulation + ") RETURNING id_simulation )
							SELECT id_simulation
							FROM row;"
							));
    	
    	loop cpt from:0 to:length(interactionPeople)-1 step:100
    	{
    		//write "" + (length(interactionPeople)-1) + " : " +  cpt;
	    	string valueInsert <- "INSERT INTO Agent (sim_id,size,coorspawnax,coorspawnay,coorspawnbx,coorspawnby,spawntime,id_simulation,states)\nVALUES\n";
	    	list<string> agentRecord;
	    	
	    	ask interactionPeople
	    	{
	    		if (int(self) > cpt) and (int(self) <= cpt+100)
	    		{
		    		string record <- "(" + int(self) + "," + size + "," + pointAX + "," + pointAY + "," + pointBX + "," + pointBY + "," + spawnTime + "," + myself.id_simulation + ",";
		    		record <- record + "'{"; 
		    		
		    		loop i from:0 to:length(recordData)-2
		    		{
		    			record <- record + "{";
		    			loop j from:0 to:length(recordData[i])-2
		    			{
		
		    				record <- record + float(recordData[i][j]);
		    				record <- record + ","; 
		    			}
		    			record <- record + float(recordData[i][length(recordData[i])-1]);
		    			
		    			record <- record + "},"; 
		    		}
		    		record <- record + "{";
		    		
		    		loop j from:0 to:length(recordData[length(recordData)-1])-2
		    			{
		    				record <- record + float(recordData[length(recordData)- 1][j]);
		    				record <- record + ","; 
		    			}
		    			record <- record + float(recordData[length(recordData)- 1][length(recordData[length(recordData)- 1])-1]);	
		    		record <- record + "}"; 
		    		
		    		
		    		record <- record + "}'"; 
		
		    		
		    		record <- record + ")"; 
		    		add record to: agentRecord;
	    		}
	    		
	    	}
	    	
	    	
	    	
	    	int l <- length(agentRecord);
	    	loop i from:0 to:l-2
	    	{
	    		valueInsert <- valueInsert + agentRecord[i] + ",\n";
	    	}
	    	
	    	
	    	valueInsert <- valueInsert + agentRecord[l-1];
	    	
	    	t <- list<list> (self select(params:POSTGRES, 
	                         select:"WITH row AS (" + valueInsert +" RETURNING id_agent )
								SELECT id_agent
								FROM row;"
								));	
		}
	write(""+ id_simulation + " is over at :" + date("now"));
		/*			
		valueInsert <- "INSERT INTO Interactions (id_simulation,cycle,sim_id_agent_seeing,sim_id_agent_seen)\nVALUES\n";
		list<string> interactionRecord;
		
		ask interactionPeople
		{
			loop i from:0 to:length(recordNetwork)-1
			{
				if(length(recordNetwork[i]) > 0)
				{
					loop j from:0 to:length(recordNetwork[i])-1
					{
						add "(" + myself.id_simulation + "," + i + "," + int(self) + "," + recordNetwork[i][j] + ")" to:interactionRecord;
						
					}
				}
			}
		}
		
		if length(interactionRecord) > 0
		{
			if length(interactionRecord) > 1
			{
				loop i from:0 to:length(interactionRecord)-2
				{
					valueInsert <- valueInsert + interactionRecord[i] + ",\n";
				}
			}
		
				valueInsert <- valueInsert + interactionRecord[length(interactionRecord)-1] + "\n";
			
			
			t <- list<list> (self select(params:POSTGRES, 
	                         select:"WITH row AS (" + valueInsert +" RETURNING id_interaction )
								SELECT id_interaction
								FROM row;"
								));	
		}
		*/
		
    	
    }
}

