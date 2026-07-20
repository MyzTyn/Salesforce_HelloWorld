Savepoint practiceSavepoint = Database.setSavepoint();

try {
  Language_Course__c course = new Language_Course__c(
    Name = 'Anonymous Apex Capacity Check',
    Capacity__c = 2,
    Status__c = 'Open',
    Start_Date__c = Date.today()
  );

  insert course;

  Date suppliedDate = Date.today().addDays(-1);

  List<Registration__c> registrations = new List<Registration__c>{
    new Registration__c(
      Language_Course__c = course.Id,
      Participant_Name__c = 'First Participant'
    ),
    new Registration__c(
      Language_Course__c = course.Id,
      Participant_Name__c = 'Second Participant',
      Status__c = 'Confirmed',
      Registered_On__c = suppliedDate
    ),
    new Registration__c(
      Language_Course__c = course.Id,
      Participant_Name__c = 'Overflow Participant'
    )
  };

  Database.SaveResult[] results = Database.insert(registrations, false);

  // Two registrations should fill the course exactly.
  System.assertEquals(true, results[0].isSuccess());
  System.assertEquals(true, results[1].isSuccess());

  // The additional registration should be rejected.
  System.assertEquals(false, results[2].isSuccess());
  System.assert(
    results[2].getErrors()[0].getMessage().contains('no available seats')
  );

  // Blank fields should receive defaults.
  Set<Id> successfulRegistrationIds = new Set<Id>{
    results[0].getId(),
    results[1].getId()
  };

  Map<Id, Registration__c> savedRegistrations = new Map<Id, Registration__c>(
    [
      SELECT Status__c, Registered_On__c
      FROM Registration__c
      WHERE Id IN :successfulRegistrationIds
    ]
  );

  Registration__c savedFirstRegistration = savedRegistrations.get(
    results[0].getId()
  );

  Registration__c savedSecondRegistration = savedRegistrations.get(
    results[1].getId()
  );

  // Verify persisted defaults.
  System.assertEquals('Pending', savedFirstRegistration.Status__c);
  System.assertEquals(Date.today(), savedFirstRegistration.Registered_On__c);

  // Verify caller-supplied values were preserved.
  System.assertEquals('Confirmed', savedSecondRegistration.Status__c);
  System.assertEquals(suppliedDate, savedSecondRegistration.Registered_On__c);

  // A cancelled registration should not consume another seat.
  Registration__c cancelledRegistration = new Registration__c(
    Language_Course__c = course.Id,
    Participant_Name__c = 'Cancelled Participant',
    Status__c = 'Cancelled'
  );

  Database.SaveResult cancelledResult = Database.insert(
    cancelledRegistration,
    false
  );

  System.assertEquals(true, cancelledResult.isSuccess());

  System.debug('Registration behavior verified successfully.');
} finally {
  Database.rollback(practiceSavepoint);
}
