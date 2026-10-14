trigger ContactHelloWorldTrigger on Contact(before insert) {
  if (Trigger.isBefore && Trigger.isInsert) {
    for (Contact item : Trigger.new) {
      item.Welcome__c = 'Hello World';
    }
  }

}
