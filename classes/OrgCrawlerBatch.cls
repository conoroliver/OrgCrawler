global class OrgCrawlerBatch implements database.Batchable <sObject>, Database.Stateful {

	String objName;
	Schema.SObjectType sObj;
	ObjectInfo__c objectInfo;
	List<String> objNames;
	List<String> fieldNames;
	Map<String, FieldInfo__c> fieldInfos;
	AnalysisInfo__c currAi;
	String whereClause;
	Boolean noRecords;
	Map<String, String> objQueryMap;

	/*
	* The constructor for the FieldAnalysis2 class.
	* @params: The string name of the object for the batch to run on and the AnalysisInfo__c object
	* that the ObjectInfo__c object is related to
	*/
	//global OrgCrawlerBatch(List<String> objNames, AnalysisInfo__c currAi)
	global OrgCrawlerBatch(Map<String, String> objQueryMap, AnalysisInfo__c currAi)
		{
			//Sets the name of the object the batch is running on
			this.noRecords = true;
			this.objQueryMap = objQueryMap;
			//this.objNames = objNames;
			this.objNames = new List<String>(objQueryMap.keyset());
			this.whereClause = objQueryMap.get(objNames.get(0));
			this.objName=objNames.get(0);
			this.currAi=currAi;
			sobj = Schema.getGlobalDescribe().get(objName);
			//Creates a new ObjectInfo__C object and sets the Name (the label we usually see)
			//and the AnalaysisInfo__c parent object
			objectInfo = new ObjectInfo__c();
			objectInfo.Name = sobj.getDescribe().getLabel();
			objectInfo.Parent_AnalysisInfo__c = currAi.Id;
			objectInfo.Query__c = whereClause;
			//Commits the ObjectInfo__c object so its ID can be referenced
			insert objectInfo;
			//Initializes the list of field names that we are querying for
			fieldNames = new List<String>();
			//Initializes the map that holds the Name of the FieldInfo__c object and the FieldInfo__c object itself
			fieldInfos = new Map<String, FieldInfo__c>();
			//for loop to iterate through all the SObjectFields in an object
			for (Schema.SObjectField sField : sObj.getDescribe().fields.getMap().values()) {
				//Sets the field name to a variable for ease of use
				String name = sField.getDescribe().getName();
				//Don't add ID because of how we filter using these fields later
				if (name != 'Id' ) {
					fieldNames.add(name);
					FieldInfo__c newFieldObject = new FieldInfo__c();
					newFieldObject.Parent_Object__c = objectInfo.Id;
					newFieldObject.name = name;
					//This line is the best way to get a field label when the object name and field name are strings
					newFieldObject.Label__c = sobj.getDescribe().fields.getMap().get(
							name).getDescribe().getLabel();
					//Add values of the FieldInfo__c object name and the FieldInfo__c object to the map
					fieldInfos.put(name, newFieldObject);
				}
			}
		}
	global database.QueryLocator start(database.BatchableContext bc)
		{
			//Initialize the string that will be used for querying
			String fields = '';
			for (Integer i = 0; i < fieldNames.size() - 1; i++) {
				fields += fieldNames.get(i) + ', ';
			}
			fields += fieldNames.get(fieldNames.size() - 1);
			//Selects ALL fields for querying
			//Will return all records with all fields
			//String query = 'SELECT ' + fields + ' FROM ' + objName;
			String query = 'SELECT ' + fields + ' FROM ' + objName + ' '+ whereClause;
			return database.getQueryLocator(query);
		}
	global void execute(database.BatchableContext bc, list<sObject> scope)
		{
			//Set number of records to 0 if no rows are returned
			this.noRecords = false;
			//Number of records is the number of returned records through the query
			objectInfo.Number_of_Records__c = scope.size();

			//Iterate through all the fields of the object
			for (String f : fieldNames) {
				Datetime lastModDate = Datetime.newInstance(1,1,1,0,0,0);
				//Set the FieldInfo__c object to the one created earlier that relates to the specified field (thank you maps)
				FieldInfo__c currFieldInfo = fieldInfos.get(f);
				Integer numPopulated = 0;
				//Iterate through all records and check if the field is not null. If so, increment numPopulated
				ID lastRecId;
				for (sObject record : scope) {
					if (record.get(f) != null) {
						numPopulated++;
					}
					if((Datetime)record.get('LastModifiedDate')>lastModDate){
						lastModDate = (Datetime)record.get('LastModifiedDate');
						lastRecId = record.Id;
					}
				}
				currFieldInfo.Last_Modified_Record__c = lastRecId;

				currFieldInfo.Populated_Number__c = numPopulated;
				//Checks that there are records with this field. If no, Percent_Populated should be 0
				if (numPopulated != 0) {
					currFieldInfo.Percent_Populated__c =
					(Decimal)numPopulated / (Decimal)objectInfo.Number_of_Records__c * 100;
				} else {
					currFieldInfo.Percent_Populated__c = 0.0;
				}
			}

		}
	global void finish(database.BatchableContext bc)
		{
			if(noRecords){
				objectInfo.Number_of_Records__c = 0;
				for(String f : fieldNames ){
					FieldInfo__c currField = fieldInfos.get(f);
					currField.Populated_Number__c = 0;
					currField.Percent_Populated__c = 0.0;
					currField.Last_Modified_Record__c = null;
				}
			}
			objectInfo.isFinished__c = true;
			update objectInfo;
			insert fieldInfos.values();
			objQueryMap.remove(objNames.get(0));
			objNames.remove(0);
			if(objQueryMap.size()>0){
			//if(objNames.size()>0){
				Database.executeBatch(new OrgCrawlerBatch(objQueryMap, currAi));
			}
			else {
				currAi.isFinished__c = true;
				update currAi;
			}
		}
}