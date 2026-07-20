trigger RegistrationTrigger on Registration__c(before insert) {
  RegistrationService.handleIncomingRegistrations(Trigger.new);
  RegistrationService.validateCapacity(Trigger.new);
}
