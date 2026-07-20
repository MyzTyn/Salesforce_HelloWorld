public with sharing class RegistrationService {
  public static void validateCapacity(List<Registration__c> registrations) {
    Map<Id, List<Registration__c>> activeRegistrationsByCourse = new Map<Id, List<Registration__c>>();

    for (Registration__c registration : registrations) {
      if (
        registration.Language_Course__c == null ||
        registration.Status__c == 'Cancelled'
      ) {
        continue;
      }

      if (
        !activeRegistrationsByCourse.containsKey(
          registration.Language_Course__c
        )
      ) {
        activeRegistrationsByCourse.put(
          registration.Language_Course__c,
          new List<Registration__c>()
        );
      }
      activeRegistrationsByCourse.get(registration.Language_Course__c)
        .add(registration);
    }

    if (activeRegistrationsByCourse.isEmpty()) {
      return;
    }

    Map<Id, Integer> existingCountByCourse = new Map<Id, Integer>();
    for (AggregateResult result : [
      SELECT Language_Course__c courseId, COUNT(Id) registrationCount
      FROM Registration__c
      WHERE
        Language_Course__c IN :activeRegistrationsByCourse.keySet()
        AND Status__c != 'Cancelled'
      GROUP BY Language_Course__c
    ]) {
      existingCountByCourse.put(
        (Id) result.get('courseId'),
        (Integer) result.get('registrationCount')
      );
    }

    for (Language_Course__c course : [
      SELECT Capacity__c
      FROM Language_Course__c
      WHERE Id IN :activeRegistrationsByCourse.keySet()
    ]) {
      Integer existingCount = existingCountByCourse.containsKey(course.Id)
        ? existingCountByCourse.get(course.Id)
        : 0;
      List<Registration__c> incomingRegistrations = activeRegistrationsByCourse.get(
        course.Id
      );

      for (Integer i = 0; i < incomingRegistrations.size(); i++) {
        if (existingCount + i >= course.Capacity__c) {
          incomingRegistrations[i]
            .addError('This language course has no available seats.');
        }
      }
    }
  }

  public static void handleIncomingRegistrations(
    List<Registration__c> registrations
  ) {
    for (Registration__c registration : registrations) {
      if (String.isBlank(registration.Status__c)) {
        registration.Status__c = 'Pending';
      }

      if (registration.Registered_On__c == null) {
        registration.Registered_On__c = Date.today();
      }
    }
  }
}
