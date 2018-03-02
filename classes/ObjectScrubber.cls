/**
 * Created by Jay on 8/24/2017.
 */

/*
* This class is to clear out the unwanted/unqueryable objects in Salesforce.
* The getRetList() method returns a list of clean objects that can be queried by FieldAnlysis2
* with no problems. The Constructor finds all objects that are queryable and NOT in the blackList of objects.
* This method is meant to be used with the ORgCrawler package on the FieldAnalysisController and FieldAnalysis Page
*/
public with sharing class ObjectScrubber {

	private final set<String> blackList = new Set<String>{'vote','contentdocumentlink','contentfoldermember','contentfolderitem','userrecordaccess','entitydefinition','fielddefinition','entityparticle','picklistvalueinfo','relationshipinfo','relationshipdomain','searchlayout','publisher','datatype','userfieldaccess','userentityaccess','ownerchangeoptioninfo','datastatistics','ideacomment','collaborationgrouprecord','flexqueueitem','apexpageinfo','dataclouddandbcompany','datacloudaddress','listviewchartinstance','platformaction','outgoingemail','outgoingemailrelation','selectedObj','selectedObject','chatterconversation','chatteractivity','chatteransweresactivity','chatteranswersreputationlevel','chatterconversationmember','chattermessage','chatterinvitation','dandbcompany'};
	private Set<String> retList;

	public ObjectScrubber() {
		retList = new Set<String>();
		Map<String, SObjectType> sobjectMap = Schema.getGlobalDescribe();
		for(String s : sobjectMap.keySet()){
			Schema.DescribeSObjectResult objectDesc = Schema.getGlobalDescribe().get(s).getDescribe();
			if(!blackList.contains(s) && objectDesc.isQueryable()){
				retlist.add(objectDesc.getLabel().replace('\'',''));
			}
		}
	}

	public List<String> getRetList() {
		return new List<String>(retList);
	}
}