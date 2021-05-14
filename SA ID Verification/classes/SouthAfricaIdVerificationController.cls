public class SouthAfricaIdVerificationController {
    
    
    
    @AuraEnabled
    public static String createOrUpdateID(Long idNumber,String gender,Boolean isCitizen,Date DOB){
        
        
        // This Logic is used to upsert identity record
        
        Identity__c identity = new Identity__c();
        
        try{
            
            Decimal SearchCount = 0;
            
            
            List<Identity__c> existingIdentity = [Select id, ID_Number__c, Search_Count__c From Identity__c
                                                  where ID_Number__c =: idNumber Limit 1];
            
            system.debug(existingIdentity);
            
            if(existingIdentity.size() > 0){
                
                SearchCount =  existingIdentity[0].Search_Count__c + 1;
                
            }
            
            
            
            identity.ID_Number__c = idNumber;
            identity.Gender__c = gender;
            identity.SA_Citizen__c = isCitizen;
            identity.Date_of_Birth__c = DOB; 
            identity.Search_Count__c = SearchCount;
            
            upsert identity ID_Number__c;
            
            
            //Calling future method to get all holidays related to Birth Year using Calendarific API. 
            
            fetchHolidays(DOB,identity.Id);
            
            
        }catch(DmlException e) {
            
            system.debug('The following exception has occurred: ' + e.getMessage());
        }
        
        return identity.id;
    }
    
    @future(callout=true)
    public static void fetchHolidays(date DOB,Id relatedID) {
        
        
        //Getting API Parameters from Metadata 
        
        Calendarific_Auth__mdt  cAuth = Calendarific_Auth__mdt.getInstance('SA_Auth');
        String baseUrl = cAuth.base_Url__c;
        String api_key = cAuth.Api_Key__c;
        String country = cAuth.Country__c;
        
        
        // Calling API only if its a new Identity
        
        List<Holiday__c> existingholiday = [Select Id,Name,Type__c,Description__c,Identity__C,Date__c From
                                            Holiday__c where identity__C =: relatedID];
        
        
        if(existingholiday.size() == 0){
            
            List<Holiday__c> newHolidayList = new List<Holiday__c>();
            Integer dobYear = DOB.year();
            
            
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(baseUrl+'?api_Key='+api_Key+'&country='+country+'&year='+dobYear);
            request.setMethod('GET');
            HttpResponse response = http.send(request);
            
            if (response.getStatusCode() == 200) {
                
                //Json Parsing to get the holiday details and store it in Holiday Object.
                
                Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                
                Map<String, Object> resp = (Map<String, Object>) results.get('response');
                
                List<Object> holidays = (List<Object>) resp.get('holidays');
                
               
                for (Object holiday: holidays) {
                    
                    Map<String, Object> holidayDetails = (Map<String, Object>)holiday;
                    
                    String holidayName = (String) holidayDetails.get('name');
                    String holidayDescription = (String) holidayDetails.get('description');
                    
                    system.debug('holidayName::'+holidayName);
                    system.debug('holidayDescription::'+holidayDescription);
                    
                    Map<String, Object> holidayDate = (Map<String, Object>) holidayDetails.get('date');
                    String HolidaydateIso = (String) holidayDate.get('iso'); 
                    Date hDate = Date.valueOf(HolidaydateIso);
                    
                    List<Object> hDayType = (List<Object>) holidayDetails.get('type');
                    String HolidayType = (String) hDayType[0];  
                    
                    
                    
                    newHolidayList.add(new Holiday__c(name = holidayName,
                                                      Description__c = holidayDescription,
                                                      Date__c = hDate,
                                                      Type__c = HolidayType,
                                                      identity__C = relatedID
                                                     ));
                    
                }
                
                
                if(newHolidayList.size() > 0){
                    insert newHolidayList;  
                }
                
                
            }
            
        }
       
    }
    
    //Method to get the Holiday Information from the Object and return it to Aura Component.
    
    @AuraEnabled
    public static holidayWrapper getHolidayDetail(Date DOB,String relatedID){
        
        system.debug('relatedID:::'+relatedID);
        List<Holiday__c> holiday = [Select Id,Name,Type__c,Description__c,Identity__C,Date__c From
                                    Holiday__c where identity__c =: relatedID
                                    and Date__c =: DOB];
        
       system.debug('holiday:::'+holiday);

        if(holiday.size() > 0){
            
            return new holidayWrapper(holiday[0].Name,
                                      holiday[0].Description__c,
                                      holiday[0].Type__c);
        }
        
        return null;
        
    }
    
    
    public class holidayWrapper {
        
        @AuraEnabled
        public string holidayName{get;set;}
        @AuraEnabled
        public string holidayDescription{get;set;}
        @AuraEnabled
        public string HolidayType{get;set;}
        
        holidayWrapper(String holidayName, String holidayDescription, String HolidayType){
            
            this.holidayName = holidayName;
            this.holidayDescription = holidayDescription;
            this.HolidayType = HolidayType;
        }
        
        
    }
    
}
