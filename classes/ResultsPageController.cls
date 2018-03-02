/**************************************************************************
*    Created By:       Robert Jones
*    Date:             1 Aug 2017
*    Last Modified:    13 Aug 2017
*    Purpose:          This controller is used to retrieve the AnalysisInfo  
*                      ID from the URL, query for objects and related fields
*                      from the analysis, and creates a JSON string from the   
*                      query results to be passed to the VF page.
*
***************************************************************************/

public with sharing class ResultsPageController {

    public PageReference renderOutput() {
        return null;
    }


    //Custom settings used to pass information to the VF page.
    Public AnalysisInfo__c Analyze{get;set;}
    Public List<objectinfo__c> RObj{get;set;}
    Public String JSONstring {get;set;}
    Public Boolean shouldRenderOutput {get;set; }
    Public Date created;
    Public String createdStr{get;set;}
    Public User analyzeUser{get;set;}
    
    public ResultsPageController() {
    
        // Pulls the ID from the URL and queries for name of that AnalysisInfo Object
        analyze = [select name, Date_Run__c,createdbyid from analysisinfo__c where id = :apexpages.currentpage().getparameters().get('id')].get(0);
        analyzeUser = [select name from user where id = :analyze.createdbyid];
        shouldRenderOutput = False;
        created = date.newinstance(analyze.date_run__c.year(), analyze.date_run__c.month(), analyze.date_run__c.day());
        createdStr = String.valueOf(created);
        
        
        //Query used to get each object from AnalysisInfo along with the related fields and thier metadata for each object.
        RObj = (
        [Select id,name, Number_of_Records__c,
        (Select id, name, created_date__c, label__c, last_modified_date__c, percent_populated__c, populated_number__c, Last_Modified_Record__c from Fieldinfo__r) 
        from ObjectInfo__c where Parent_AnalysisInfo__c = :apexpages.currentpage().getparameters().get('id')]);
        
        //Creates a JSON string from the query results.
        JSONstring = JSON.serialize(RObj);
    }

    public PageReference goHome(){
        PageReference pageRef = new PageReference('/home/home.jsp');
        return pageRef;
    }

}