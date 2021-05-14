({
    myAction : function(component, event, helper) {
        
    },
    
    
    //Sending Decoded Information to Backend and getting the Holiday Detail in Return.
    
    search: function (component, event, helper) {
        
        component.set('v.showDetailsSection',false);
        var idNumber = component.get("v.idNumber");
        var gender = helper.getGender(idNumber);
        var isCitizen = helper.getCitizenStatus(idNumber);
        var DOB = helper.getDOB(idNumber);
        
        component.set("v.Gender",gender);
        component.set("v.DOB",DOB);
        
        if(isCitizen == true){
            
        component.set("v.SAcitizen","Yes");    
            
        }else{
           
            component.set("v.SAcitizen","No");
            
        }
       
       //Promises to call two Async methods one after another. 
        
        helper.callServer(
            component,
            helper,
            'c.createOrUpdateID',
            {
                'idNumber': idNumber,
                'gender': gender,
                "isCitizen" : isCitizen,
                "DOB" : DOB
            }
            
        ).then(function(r) {
            
            helper.callServer(
                component,
                helper,
                'c.getHolidayDetail',
                {
                    'DOB' : DOB,
                    'relatedID': r.result
                }
            ).then(function(r) {
                
                if(r.result == null){
                   
                    component.set('v.holidayFound', true);
                }else{
                    component.set('v.holidayFound', false);
                }
                
                component.set('v.holidayDetails', r.result);
                component.set('v.showDetailsSection',true);
                
            })
            
            
        })
        
    },
    
    
    //Validating Veridication ID Number Using Regular Expression
    
    validateId: function (component, event, helper) {
        
        var isEnterKey = event.keyCode === 13;
        
            var vId = component.find('id-search').get('v.value');
            
            var regex = /^(((\d{2}((0[13578]|1[02])(0[1-9]|[12]\d|3[01])|(0[13456789]|1[012])(0[1-9]|[12]\d|30)|02(0[1-9]|1\d|2[0-8])))|([02468][048]|[13579][26])0229))(( |-)(\d{4})( |-)(\d{3})|(\d{7}))/;
            
            if(!regex.test(vId)){
                
                component.set("v.err",true);
                component.set("v.isButtonActive",true);
            }else{
                
                component.set("v.isButtonActive",false);
                component.set("v.err",false);
                component.set("v.idNumber",vId);
            
        }
    }
})
