public with sharing class DnbMassUpdateBatch 
implements Database.Batchable<SObject>, Database.AllowsCallouts {
    public Integer successCount = 0;
    public Integer failureCount = 0;

    public Database.QueryLocator start(Database.BatchableContext bc) {

        return Database.getQueryLocator([
            SELECT Id, DUNs_Number__c
            FROM Account
            WHERE DUNs_Number__c != null
            AND DnB_Last_Refresh_Date__c <= LAST_N_DAYS:30]);
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {

        for (Account acc : scope) {

            try {
                System.debug('Running MASS_UPDATE for Account: ' + acc.Id);

                DnbCreditEngine.run(
                    acc.Id,
                    'MASS_UPDATE'
                );

            } catch (Exception e) {

                System.debug(
                    'Mass update failed for Account ' +
                    acc.Id +
                    ' | Scenario MASS_UPDATE | Error: ' +
                    e.getMessage()
                );
            }
        }
    }

    public void finish(Database.BatchableContext bc) {

        System.debug('DNB mass update batch completed | Success: ' + successCount + ' | Failures: ' + failureCount);
    }
}