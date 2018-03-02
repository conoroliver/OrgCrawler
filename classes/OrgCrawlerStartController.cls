/**
 * Created by Clay on 8/27/2017.
 */
public with sharing class OrgCrawlerStartController {
    public List<String> lstSObj {get; set;}//List of SObjects in the org
    public List<String> selectedObjects { get; set; }//currently selected objects

    public boolean runAlert {get; set;}//check value for success message
    public boolean errorAlert {get; set;}//check value for errors

    public String queryName {get; set;}//name of the AnalysisInfo object
    public String JSONlstObj{get; set;}//serialized string of lstSObj to be passed to Javascript
    public String queryObject{get;set;}
    public String queryString{get;set;}
    public String selectedQueryObjectJSON{ get; set; }

    public Map<String, String> labelToNameMap{get; set;}//map used to get the proper names to be used in the batch class
    public Map<String, String> retMap {get; set;}//map to be pass into controller containing set of (object name, where clause)
    public AnalysisInfo__c aI{get; set;}//the current AnalysisInfo object

    public OrgCrawlerStartController() {
        runAlert = false;
        errorAlert = false;
        retMap = new Map<String, String>();

        //set up the label map
        labelToNameMap = new Map<String, String>();
        for (Schema.SObjectType obj :Schema.getGlobalDescribe().values()) {
            labelToNameMap.put(obj.getDescribe().getLabel(), obj.getDescribe().getName());
        }

        //The ObjectScrubber retrieves all objects in org while removing blacklisted objects
        ObjectScrubber scrub = new ObjectScrubber();
        lstSObj = scrub.getRetList();
        //Used to alphabetize objects on VF page
        lstSObj.sort();
        JSONlstObj = JSON.serialize(lstSObj);
    }

    public String getObjectFields() {
        return JSON.serialize(new List<String>(Schema.getGlobalDescribe().get(labelToNameMap.get(queryObject)).getDescribe().fields.getMap().keyset()));
    }

    public PageReference goHome() {
        PageReference pageRef = new PageReference('/home/home.jsp');
        return pageRef;
    }

    public PageReference step2() {
        return Page.OrgCrawlerWhereV972832;

    }

    public PageReference queryComplete() {
        return Page.OrgCrawlerStart;
    }


    //Starts the batch process if there are objects selected and a query name has been given
    public void runBatch() {
        //get the selected objects from JS
        selectedObjects = (List<String>)JSON.deserialize(Apexpages.currentPage().getParameters().get('param1'), List<String>.class);
        List<String> passedObjs = new List<String>();
        for (String s : selectedObjects) {
            passedObjs.add(labelToNameMap.get(s));
            if(!retMap.containsKey(labelToNameMap.get(s))){
                retMap.put(labelToNameMap.get(s),'');
            }
        }
        //start up batch if there are selected objects and there is a query name
        if (!passedObjs.isEmpty() && queryName != '') {
            aI = new AnalysisInfo__c();
            aI.Name = queryName;
            aI.Date_Run__c = Date.today();
            aI.TotalNumberofObjects__c = selectedObjects.size();
            insert aI;
            Database.executeBatch(new OrgCrawlerBatch(retMap, aI));
            runAlert = true;
            errorAlert = false;
        } else {
            errorAlert = true;
        }
    }

    public void finalQuery() {
        queryString = 'WHERE ' +
        (String)JSON.deserialize(ApexPages.currentPage().getParameters().get('param2'), String.class);
        retMap.put(labelToNameMap.get(queryObject), queryString);
    }
}