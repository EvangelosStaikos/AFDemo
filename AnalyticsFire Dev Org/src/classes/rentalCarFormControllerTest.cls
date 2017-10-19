/*************************************************************************************
Class Name     :  rentalCarFormControllerTest
Purpose        :  Test class for the rentalCarFormController class
History:                                                            
-------                                                            
VERSION  AUTHOR         		DATE            	DETAIL          		    TICKET REFERENCE/ NO.
1.       Evangelos Staikos	    2017-10-06      	Original Version            N/A
***************************************************************************************/
@isTest
private class rentalCarFormControllerTest {

	/******************************************************
	* Method Name	:  testController
	* Description	:  Test controller and helper methods
	* Return Type	:  void
	* Parameters	:  none
	*******************************************************/
    static testMethod void testController() {
        
        // Setup test car data
        list<Car__c> carList = new list<Car__c>();
        Car__c c1 = new Car__c(Price_per_day__c = 100, Name = 'Car 1', ImageUrl__c = '127.0.0.1', Description__c = 'car facts');
        Car__c c2 = new Car__c(Price_per_day__c = 500, Name = 'Car 2', ImageUrl__c = '127.0.0.1', Description__c = 'other car facts'); 
        carList.add(c1);carList.add(c2);
        insert carList;
        
        PageReference pageRef;
        rentalCarFormController controller = new rentalCarFormController();
        
        // Test blank submission
        controller.app.Start_Date__c = date.today().addDays(1);
        controller.app.End_Date__c = date.today().addDays(-1);
        pageRef = controller.submit();
        system.assert(controller.errorMessage.contains('Please enter a first name'));
        system.assert(controller.errorMessage.contains('Please enter a last name'));
        system.assert(controller.errorMessage.contains('Please enter a phone number'));
        system.assert(controller.errorMessage.contains('Please enter an email address'));
        system.assert(controller.errorMessage.contains('Please enter a billing address'));
        system.assert(controller.errorMessage.contains('Please enter a billing city'));
        system.assert(controller.errorMessage.contains('Please select a billing state'));
        system.assert(controller.errorMessage.contains('Please enter a billing postal code'));
        system.assert(controller.errorMessage.contains('Please select a car model'));
        
        // Test field overflows
        String reallyLongString = 'abcde';
        for (integer i = 0; i < 9; i++){
        	reallyLongString += reallyLongString;
        }
        
        controller.firstName = reallyLongString;
 		controller.LastName = reallyLongString;
		controller.phoneNumber = '1234567891212341412412345678';
		controller.emailAddress = reallyLongString;
		controller.billingStreet = reallyLongString;
		controller.billingCity = reallyLongString;
		controller.billingState = reallyLongString;
		controller.billingPostal = reallyLongString;
		pageRef = controller.submit();
        system.assert(controller.errorMessage.contains('First name must be no more than 40 characters'));
        system.assert(controller.errorMessage.contains('Last name must be no more than 40 characters'));
        system.assert(controller.errorMessage.contains('Phone number must be no more than 11 characters'));
        system.assert(controller.errorMessage.contains('Email address must be no more than 80 characters'));
        system.assert(controller.errorMessage.contains('Billing address must be no more than 255 characters'));
        system.assert(controller.errorMessage.contains('Billing city must be no more than 255 characters'));
        system.assert(controller.errorMessage.contains('Billing state must be no more than 255 characters'));
        system.assert(controller.errorMessage.contains('Billing postal code must be no more than 5 characters'));
        
        // Test regex
        controller.firstName = 'Evangelos';
 		controller.LastName = 'Staikos';
		controller.phoneNumber = '1-(800)-123-4567 ext';
		controller.emailAddress = 'test@test';
		controller.billingStreet = '123 Main Street';
		controller.billingCity = 'Test';
		controller.billingState = 'TX';
		controller.billingPostal = '10000';
		pageRef = controller.submit();
        system.assert(controller.errorMessage.contains('Please enter a valid email address'));
        
        // Test date validation
        controller.emailAddress = 'test@test.com';
        controller.app.Start_Date__c = date.today().addDays(-1);
        controller.formDateChanged();
        pageRef = controller.submit();
        system.assert(controller.errorMessage.contains('You must pick a start date that is today or later'));
        
        controller.app.Start_Date__c = date.today().addDays(1);
        controller.app.End_Date__c = date.today().addDays(-1);
        controller.formDateChanged();
        pageRef = controller.submit();
        system.assert(controller.errorMessage.contains('You must pick an end date that is at least one day after the start date'));
        
        // Test new contact and account application submission
        controller.app.Start_Date__c = date.today().addDays(1);
        controller.app.End_Date__c = date.today().addDays(11);
        controller.formDateChanged();
        controller.selectedCar = 'Car 1';
        controller.formCarChanged();
        system.assertEquals(1000.00, controller.totalPrice);
        controller.submit();
        
        Contact pullContact = [Select id, accountId, firstName from Contact where email = 'test@test.com'];
        system.assert(pullContact.firstName.equals('Evangelos'));
        
        Rental_Application__c application = [Select id, Email_Address__c, opportunity__c, contact__c from Rental_Application__c where contact__c = :pullContact.id];
        system.assert(application.Email_Address__c.equals('test@test.com'));
        
        Opportunity pullOpp = [Select id, accountId, amount from Opportunity where id = :application.opportunity__c];
        system.assertEquals(pullOpp.amount, controller.totalPrice);
        
        // Test another rental on same contact with updates
        controller.selectedCar = 'Car 2';
        controller.firstName = 'Evangelos LongNameLongName';
        controller.lastName = 'Staikos LongNameLongName';
        controller.formCarChanged();
        controller.app.id = null;
        system.assertEquals(5000.00, controller.totalPrice);
        controller.submit();
        
        pullContact = [Select id, accountId, firstName from Contact where email = 'test@test.com'];
        system.assert(pullContact.firstName.contains('LongName'));
        
        Integer tracker = 0;
        for ( Rental_Application__c apps : [Select id, Email_Address__c, opportunity__c, contact__c from Rental_Application__c where contact__c = :pullContact.id]){
        	tracker++;
        }
        system.assertEquals(2, tracker);
        
        String appId = controller.app.id;
        
        // Test admin flow
        Test.setCurrentPage(new PageReference('Page.rentalCarForm?btnActn=FM_Approve'));
        ApexPages.currentPage().getParameters().put('btnActn', 'FM_Approve');
        ApexPages.currentPage().getParameters().put('record', appId);
        controller = new rentalCarFormController();
        pageRef = controller.adminFlow();
        system.debug(controller.errorMessage);
        system.assert(pageRef.getUrl().contains(appId));
        
        Test.setCurrentPage(new PageReference('Page.rentalCarForm?btnActn=BM_Approve'));
        ApexPages.currentPage().getParameters().put('btnActn', 'BM_Approve');
        ApexPages.currentPage().getParameters().put('record', appId);
        controller = new rentalCarFormController();
        pageRef = controller.adminFlow();
        system.debug(controller.errorMessage);
        system.assert(pageRef.getUrl().contains(appId));
    }
}