trigger RegistrationTrigger on Registration__c (before insert) {
    // TODO: Call the service method that applies the required registration defaults.
    RegistrationService.validateCapacity(Trigger.new);
}

