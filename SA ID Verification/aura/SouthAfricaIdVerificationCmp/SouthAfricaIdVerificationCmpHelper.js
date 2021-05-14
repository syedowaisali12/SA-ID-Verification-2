({
    //Decoding Gender, Citizen Status and Date of Birth From verification ID Number
    
    getGender : function(idNumber) {
        
        var genderCode = idNumber.substring(6, 10);
        var gender;
        
        if(genderCode < 5000){
            gender = 'Female';
        }else{
            gender = 'Male';
        }
        
        return gender;
    },
    
    getCitizenStatus : function(idNumber){
        var citizenshipCode = idNumber.substring(10, 11);
        var isCitizen = false;
        
        if(citizenshipCode == 0){
            isCitizen = true;
        }
        
        return isCitizen;
    },
    
    getDOB : function(idNumber){
        
        var yearPart =  parseInt(idNumber.substring(0, 2), 10);
        var monthPart = parseInt(idNumber.substring(2, 4), 10) - 1;
        var dayPart = parseInt(idNumber.substring(4, 6), 10);
        var dateOfBirth = new Date(yearPart, monthPart, dayPart);
        dateOfBirth = $A.localizationService.formatDate(dateOfBirth, "YYYY-MM-DD");
        
        return dateOfBirth;
    },
    
    
    //Calling server and retunring the response to promise.
    
    callServer : function(component, helper, actionName, params) {
        return new Promise($A.getCallback(function(resolve, reject) {
            let action = component.get(actionName);
            action.setParams(params);
            action.setCallback(helper, function(actionResult) {
                if (actionResult.getState() === 'SUCCESS') {
                    resolve({'c':component, 'h':helper, 'result':actionResult.getReturnValue()});
                } else {
                    let errors = actionResult.getError();
                    reject(new Error(errors && Array.isArray(errors) && errors.length === 1 ? errors[0].message : JSON.stringify(errors)));
                }
            });
            $A.enqueueAction(action);
        }));
        
    },
    
    
    
})
