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
                                        
    init {
    	connect <- testConnection(params:POSTGRES);


        //Parameter     
        list<list> t <-   list<list> (self select(params:POSTGRES, 
                         select:"SELECT name,commentaire,typeConfig,fluctuationType,deltaT,relaxationTime,isRespawn,isFluctuation,pedestrianSpeed,pedestrianMaxSpeed,pedestrianMaxSize,pedestrianMinSize,simulationDuration,temporalFieldIntervalLength,interactionType,is360,interactionAngle,interactionRange,isNervousnessTransmition,interactionParameter,spaceLength,spaceWidth,socialForceStrength,socialForceThreshold,socialForceVision,bodyContactStrength,bodyFrictionStrength,isNervousness 
							FROM configuration NATURAL JOIN parameterset WHERE id_configuration = ?;"
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
                         select:"SELECT id_area,coordltx,coordlty,coordrdx,coordrdy 
									FROM includeagent NATURAL JOIN area  where id_configuration = ? and id_agentset = ? ORDER BY listorder;"
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
                         select:"SELECT id_obstacle,id_wall,coordx,coordy,largeur,longueur 
									FROM includeobstacle NATURAL JOIN obstacle NATURAL JOIN wall WHERE id_configuration = ?;"
							, values:[id_configuration]));
							

    	loop i from:0 to: length(t[2])-1 {
    		map tmp;

    		loop j from:0 to: length(t[0])-1 {
    			add t[0][j]::t[2][i][j] to: tmp;
    		}

    		add tmp to: walls;

    	}
		
    	
    	
    }
    
    action recordAgent 
    {
    	//INSERT Iin simulation
		list<list> t <- list<list> (self select(params:POSTGRES, 
                         select:"WITH row AS (
							INSERT INTO simulation (id_configuration,date_depart) VALUES (?,'" + date("now") + "') RETURNING id_simulation )
							SELECT id_simulation
							FROM row;"
							,values:[id_configuration]));	
		
							
    	
    	
    	string valueInsert <- "INSERT INTO Agent (size,coorspawnax,coorspawnay,coorspawnbx,coorspawnby,spawntime,id_simulation,states)\nVALUES\n";
    	list<string> agentRecord;
    	
    	ask interactionPeople
    	{

    		string record <- "(" + size + "," + pointAX + "," + pointAY + "," + pointBX + "," + pointBY + "," + spawnTime + "," + t[2][0][0] + ",";
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
    	
    	int l <- length(agentRecord);
    	loop i from:0 to:l-2
    	{
    		valueInsert <- valueInsert + agentRecord[i] + ",\n";
    	}
    	valueInsert <- valueInsert + agentRecord[l-1] + ";";
    	
    }
}

