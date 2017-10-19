/*************************************************************************************
Class Name     :  rentalCarFormController
Purpose        :  Controller class for rentalCarForm.page
History:                                                            
-------                                                            
VERSION  AUTHOR         		DATE            	DETAIL          		    TICKET REFERENCE/ NO.
1.       Evangelos Staikos	    2017-10-06      	Original Version            N/A
***************************************************************************************/
public without sharing class rentalCarFormController {
    
    public String firstName {get; set;}
    public String lastName {get; set;}
    public String emailAddress {get; set;}
    public String phoneNumber {get; set;}
    public String billingStreet {get; set;}
    public String billingCity {get; set;}
    public String billingPostal {get; set;}
    public String billingState {get; set;}
    public String selectedCar {get; set;}
    public String errorMessage {get; set;}
    public String recordId {get; set;}
    public String buttonAction {get; set;}
    
    public Boolean disableForm {get; set;}
    public Boolean success {get; set;}
    public Boolean inAdminFlow {get; set;}
    
    public decimal totalPrice {get; set;}
    
    public Integer numDays;
    
    public list<SelectOption> billingStateValues {get; set;}
    public list<SelectOption> cars {get; set;}
    
    public map<String, Car__c> carMap;
    public Car__c currentCar {get; set;}
    public Rental_Application__c app {get; set;}
    
    /******************************************************
	* Constructor Method
	*******************************************************/
    public rentalCarFormController(){

    	// Detect button action
    	this.buttonAction = '';
        if (ApexPages.CurrentPage().getParameters().get('btnActn') != null){
        	this.buttonAction = ApexPages.CurrentPage().getParameters().get('btnActn');
        }
    	
    	// Detect record Id
    	this.recordId = '';
    	this.inAdminFlow = false;
        if (ApexPages.CurrentPage().getParameters().get('record') != null){
        	this.recordId = ApexPages.CurrentPage().getParameters().get('record');
        	this.inAdminFlow = true;
        }
    	
    	// Initialize base form vars
    	this.firstName = '';
    	this.lastName = '';
    	this.emailAddress = '';
    	this.phoneNumber = '';
    	this.billingStreet = '';
    	this.billingCity = '';
    	this.billingPostal = '';
    	this.billingState = '---';
    	this.selectedCar = '---';
 		this.errorMessage = '';
 		
 		// Trace validation
    	this.success = false;
    	this.disableForm = true;
    	
    	// Initialize car storage
    	this.cars = new list<SelectOption>();
    	this.cars.add(new SelectOption('---', '---'));
    	this.carMap = new map<String, Car__c>();
    	
    	// Initialize base application
    	this.app = new Rental_Application__c(
    		Application_Status_FM__c = 'Pending'
    	);
    	this.numDays = 0;
    	
    	// Initialize null car
    	this.currentCar = new Car__c(
    		Name = '---',
    		Price_per_day__c = 0.0,
    		Description__c = '',
    		ImageUrl__c = ''
    	);
    	this.carMap.put('---', this.currentCar);
    	
    	// Generate state picklist
    	set<String> stateVals = new set<String>{'AL','AK','AZ','AR','CA','CO','CT','DE','DC','FL','GA','HI','ID','IL','IN','IA','KS','KY','LA','ME','MD','MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ','NM','NY','NC','ND','OH','OK','OR','PA','RI','SC','SD','TN','TX','UT','VT','VA','WA','WV','WI','WY'};
    	this.billingStateValues = new list<SelectOption>();
    	this.billingStateValues.add(new SelectOption('---','---'));
    	for (String s : stateVals){
    		this.billingStateValues.add(new SelectOption(s,s));
    	}
    	
    	// Pull rental car data
    	for (Car__c c : [Select Price_per_day__c, Name, ImageUrl__c, Description__c From Car__c limit 500]){
    		this.carMap.put(c.Name, c);
    		this.cars.add(new SelectOption(c.Name, c.Name));
    	}
    }
    
    /******************************************************
	* Method Name	:  adminFlow
	* Description	:  Handle admin flows
	* Return Type	:  PageReference
	* Parameters	:  none
	*******************************************************/
	public PageReference adminFlow(){
		if (this.inAdminFlow){
			this.errorMessage = '';

			Rental_Application__c application = [Select id, Application_Status_BM__c, Application_Status_FM__c from Rental_Application__c where id = :this.recordId limit 1];
			
			// Handle approve/reject based on button selected
			if (this.buttonAction.equals('BM_Approve')){
				if (!application.Application_Status_BM__c.equals('Pending')){
					this.errorMessage = 'This application has already been reviewed';
				}
				else {
					application.Application_Status_BM__c = 'Approved';
				}
			}
			else if (this.buttonAction.equals('BM_Reject')){
				if (!application.Application_Status_BM__c.equals('Pending')){
					this.errorMessage = 'This application has already been reviewed';
				}
				else {
					application.Application_Status_BM__c = 'Rejected';
				}
			}
			else if (this.buttonAction.equals('FM_Approve')){
				if (!application.Application_Status_FM__c.equals('Pending')){
					this.errorMessage = 'This application has already been reviewed';
				}
				else {
					application.Application_Status_FM__c = 'Approved';
				}
			}
			else if (this.buttonAction.equals('FM_Reject')){
				if (!application.Application_Status_FM__c.equals('Pending')){
					this.errorMessage = 'This application has already been reviewed';
				}
				else {
					application.Application_Status_FM__c = 'Rejected';
				}
			}
			
			// Update the application record, or report error if problem occurs
			try {
				update application;
				return new PageReference('/' + this.recordId);
			}
			catch(exception e){
				this.errorMessage = 'There was an error updating the application: <br/>' + e;
				return null;
			}
		}
		else {
			return null;
		}
	}
    
    /******************************************************
	* Method Name	:  formDateChanged
	* Description	:  Make updates for new date selected
	* Return Type	:  void
	* Parameters	:  none
	*******************************************************/
    public void formDateChanged(){
    	// Recalculate number of days and total price from date input
    	if (this.app.Start_Date__c != null && this.app.End_Date__c != null){
			this.numDays = this.app.Start_Date__c.daysBetween(this.app.End_Date__c);
    		this.totalPrice = this.numDays * this.currentCar.Price_per_day__c;
			calculateValidCars();
	   		this.disableForm = false;
    	}
    	else {
    		this.disableForm = true;
    	}
    }
    
    /******************************************************
	* Method Name	:  formCarChanged
	* Description	:  Make updates for new car selected
	* Return Type	:  void
	* Parameters	:  none
	*******************************************************/
	public void formCarChanged(){
		// Set car based on picklist
    	this.currentCar = this.carMap.get(this.selectedCar);
    	
    	// Recalculate number of days and total price from date input
    	if (this.app.Start_Date__c != null && this.app.End_Date__c != null){
	    	this.numDays = this.app.Start_Date__c.daysBetween(this.app.End_Date__c);
	    	this.totalPrice = this.numDays * this.currentCar.Price_per_day__c;
    	}
    	
    	// Render line breaks in description field
    	this.currentCar.Description__c.replace('\n', '<br/>');
	}
    
    /******************************************************
	* Method Name	:  calculateValidCars
	* Description	:  Make updates for new car selected
	* Return Type	:  void
	* Parameters	:  none
	*******************************************************/
	public void calculateValidCars(){
		// Find cars that are booked within window
		set<String> carIds = new set<String>();
		for (Rental_Application__c apps : [Select id, Car__c from Rental_Application__c where ((Start_Date__c <= :this.app.End_Date__c and Start_Date__c >= :this.app.Start_Date__c) or (End_Date__c >= :this.app.Start_Date__c and End_Date__c <= :this.app.End_Date__c)) and Application_Status_BM__c = 'Approved' limit 10000]){
			carIds.add(apps.Car__c);
		}
		
		// Reset car storage
    	this.cars = new list<SelectOption>();
    	this.cars.add(new SelectOption('---', '---'));
    	this.carMap = new map<String, Car__c>();
		this.selectedCar = '---';
		// Reset current car
    	this.currentCar = new Car__c(
    		Name = '---',
    		Price_per_day__c = 0.0,
    		Description__c = '',
    		ImageUrl__c = ''
    	);
    	this.carMap.put('---', this.currentCar);
		
		// Generate new car list of only valid cars
		for (Car__c c : [Select Price_per_day__c, Name, ImageUrl__c, Description__c From Car__c limit 500]){
    		if (!carIds.contains(c.id)){
    			this.carMap.put(c.Name, c);
    			this.cars.add(new SelectOption(c.Name, c.Name));
    		}
    	}
	}
    
    /******************************************************
	* Method Name	:  submit
	* Description	:  Process and submit form
	* Return Type	:  PageReference
	* Parameters	:  none
	*******************************************************/
	public PageReference submit(){
		this.errorMessage = '';
		
		// Validate the form
		Boolean validated = validateForm();
		
		if (validated){
			// Find contact, insert new if none found
			String customerId = '';
			Boolean customerFound = false;
			Contact customer;
			for (Contact c : [Select id, accountId, Phone, MailingStreet, MailingState, MailingPostalCode, MailingCity, LastName, FirstName, Email from Contact where Email = :this.emailAddress limit 1]){
				customer = c;
				customerFound = true;
				customerId = c.id;
			}
			
			if (customer == null){
				customer = new Contact();
			}
			
			// Update contact record
			customer.FirstName = this.firstName;
			customer.LastName = this.lastName;
			customer.Phone = this.phoneNumber;
			customer.Email = this.emailAddress;
			customer.MailingStreet = this.billingStreet;
			customer.MailingCity = this.billingCity;
			customer.MailingState = this.billingState;
			customer.MailingPostalCode = this.billingPostal;
			
			// If existing customer, update.  Else, create new records
			if (customerFound){
				try {
					update customer;
				}
				catch (exception e){
					// Handle failed update
					system.debug(e);
					this.errorMessage = 'There was an error processing your request.  Please contact support@analyticsfire.com for assistance. Error code 10001';
					return null;
				}
			}
			else {
				try {
					// Insert account
					Account a = new Account(
						Name = this.firstName + ' ' + this.lastName + '  Account',
						billingStreet = this.billingStreet,
						billingCity = this.billingCity,
						billingState = this.billingState,
						billingPostalCode = this.billingPostal,
						phone = this.phoneNumber,
						type = 'Prospect',
						AccountSource = 'Web',
						Active__c = 'Yes'
					);
					insert a;
					
					// Insert customer
					customer.accountId = a.id;
					insert customer;
					
					customerId = customer.id;
				}
				catch (exception e){
					// Handle failed insert
					system.debug(e);
					this.errorMessage = 'There was an error processing your request.  Please contact support@analyticsfire.com for assistance. Error code 10024';
					return null;
				}
			}
			
			// Ensure opportunity name length
			String opportunityId = '';
			String oppName = 'Car rental for ' + this.firstName + ' ' + this.lastName;
			if (oppName.length() > 120){
				oppName = oppName.substring(0,119);
			}
			
			// Create opportunity
			Opportunity newOpp = new Opportunity(
				Name = 'Car rental for ' + this.firstName + ' ' + this.lastName,
				StageName = 'Prospecting',
				Amount = this.totalPrice,
				accountId = customer.accountId,
				type = 'New Customer',
				CloseDate = this.app.Start_Date__c
			);
			
			try {
				insert newOpp;
				opportunityId = newOpp.id;
			}
			catch(exception e) {
				// Handle failed opp insertion
				system.debug(e);
				this.errorMessage = 'There was an error processing your request.  Please contact support@analyticsfire.com for assistance. Error code 10827';
				return null;
			}
			
			// Insert application form linked to parents
			this.app.Name = this.firstName + ' ' + this.lastName + ' ' + this.currentCar.Name;
			this.app.Phone_Number__c = this.phoneNumber; 
			this.app.Opportunity__c = opportunityId;
			this.app.Last_Name__c = this.lastName; 
			this.app.First_Name__c = this.firstName;
			this.app.Email_Address__c = this.emailAddress; 
			this.app.Contact__c = customerId;
			this.app.Car__c = this.currentCar.id;
			this.app.Billing_Street__c = this.billingStreet;
			this.app.Billing_State__c = this.billingState;
			this.app.Billing_Postal__c = this.billingPostal;
			this.app.Billing_City__c = this.billingCity;
			this.app.Amount__c = this.totalPrice;
			
			try {
				insert this.app;
			}
			catch(exception e){
				// Handle failed application insertion
				system.debug(e);
				this.errorMessage = 'There was an error processing your request.  Please contact support@analyticsfire.com for assistance. Error code 20181';
				return null;
			}
			
			this.success = true;
		}
		
		return null;
	}
	
	/******************************************************
	* Method Name	:  validateForm
	* Description	:  Validate form based on field requirements
	* Return Type	:  Boolean
	* Parameters	:  none
	*******************************************************/
	public Boolean validateForm(){
		Boolean valid = true;
		
		// Validate first name field
		if (this.firstName == null || this.firstName.equals('')){
			valid = false;
			this.errorMessage += 'Please enter a first name <br/>';
		}
		else {
			if (this.firstName.length() > 40){
				valid = false;
				this.errorMessage += 'First name must be no more than 40 characters <br/>';
			}
		}
		
		// Validate last name field
		if (this.lastName == null || this.lastName.equals('')){
			valid = false;
			this.errorMessage += 'Please enter a last name <br/>';
		}
		else {
			if (this.lastName.length() > 40){
				valid = false;
				this.errorMessage += 'Last name must be no more than 40 characters <br/>';
			}
		}
		
		// Validate phone number field
		if (this.phoneNumber == null || this.phoneNumber.equals('')){
			valid = false;
			this.errorMessage += 'Please enter a phone number <br/>';
		}
		else {
			this.phoneNumber = this.phoneNumber.replaceAll('\\D','');
			if (this.phoneNumber.length() > 11){
				valid = false;
				this.errorMessage += 'Phone number must be no more than 11 characters <br/>';
			}
		}
		
		// Validate email address field
		if (this.emailAddress == null || this.emailAddress.equals('')){
			valid = false;
			this.errorMessage += 'Please enter an email address <br/>';
		}
		else {
			if (this.emailAddress.length() > 80){
				valid = false;
				this.errorMessage += 'Email address must be no more than 80 characters <br/>';
			}
			else {
				String emailCheck = '^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}$';
				Pattern p = Pattern.compile(emailCheck);
			    Matcher m = p.matcher(this.emailAddress);
			    
			    if (!m.matches()){
			    	valid = false;
					this.errorMessage += 'Please enter a valid email address <br/>';
			    }
			}
		}
		
		// Validate billing street field
		if (this.billingStreet == null || this.billingStreet.equals('')){
			valid = false;
			this.errorMessage += 'Please enter a billing address <br/>';
		}
		else {
			if (this.billingStreet.length() > 255){
				valid = false;
				this.errorMessage += 'Billing address must be no more than 255 characters <br/>';
			}
		}
		
		// Validate billing city field
		if (this.billingCity== null || this.billingCity.equals('')){
			valid = false;
			this.errorMessage += 'Please enter a billing city <br/>';
		}
		else {
			if (this.billingStreet.length() > 255){
				valid = false;
				this.errorMessage += 'Billing city must be no more than 255 characters <br/>';
			}
		}
		
		// Validate billing state field
		if (this.billingState == null || this.billingState.equals('---')){
			valid = false;
			this.errorMessage += 'Please select a billing state <br/>';
		}
		else {
			if (this.billingState.length() > 255){
				valid = false;
				this.errorMessage += 'Billing state must be no more than 255 characters <br/>';
			}
		}
		
		// Validate billing postal field
		if (this.billingPostal == null || this.billingPostal.equals('')){
			valid = false;
			this.errorMessage += 'Please enter a billing postal code <br/>';
		}
		else {
			if (this.billingPostal.length() > 5){
				valid = false;
				this.errorMessage += 'Billing postal code must be no more than 5 characters <br/>';
			}
		}
		
		// Validate car selected
		if (this.selectedCar.equals('---')){
			valid = false;
			this.errorMessage += 'Please select a car model <br/>';
		}
		
		// Validate start and end dates
		Date todayDate = date.today();
		if (todayDate.daysBetween(this.app.Start_Date__c) < 0){
			valid = false;
			this.errorMessage += 'You must pick a start date that is today or later <br/>';
		}
		if (this.numDays < 1){
			valid = false;
			this.errorMessage += 'You must pick an end date that is at least one day after the start date <br/>';
		}
		
		return valid;
	}
}