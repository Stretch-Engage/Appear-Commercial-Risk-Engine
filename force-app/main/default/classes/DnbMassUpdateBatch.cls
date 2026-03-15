public with sharing class DnbMassUpdateBatch
implements Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful {

    public Integer successCount = 0;
    public Integer failureCount = 0;
    public List<String> failedAccountIds = new List<String>();

    public Database.QueryLocator start(Database.BatchableContext bc) {

        return Database.getQueryLocator([
            SELECT Id, DUNs_Number__c
            FROM Account
            WHERE DUNs_Number__c != null
            AND (
                DnB_Last_Refresh_Date__c = null
                OR DnB_Last_Refresh_Date__c < LAST_N_DAYS:30
            )
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {

        Account acc = scope[0];

        try {
            System.debug('Running MASS_UPDATE for Account: ' + acc.Id);

            DnbCreditEngine.run(acc.Id, 'MASS_UPDATE');

            successCount++;

        } catch (Exception e) {

            failureCount++;
            failedAccountIds.add(acc.Id);

            System.debug(
                'Mass update failed for Account ' + acc.Id +
                ' | Error: ' + e.getMessage() +
                ' | Stack: ' + e.getStackTraceString()
            );
        }
    }

    public void finish(Database.BatchableContext bc) {

        System.debug(
            'DNB mass update batch completed | JobId: ' + bc.getJobId() +
            ' | Success: ' + successCount +
            ' | Failures: ' + failureCount
        );

        if (failureCount > 0) {
            System.debug('Failed Account IDs: ' + failedAccountIds);
        }
    }
}