public with sharing class DnbMassUpdateScheduler implements Schedulable {
     @TestVisible
    private static Boolean mockJobAlreadyRunning = false;

    public void execute(SchedulableContext sc) {

        List<AsyncApexJob> runningJobs = [
            SELECT Id
            FROM AsyncApexJob
            WHERE JobType = 'BatchApex'
            AND Status IN ('Queued', 'Processing', 'Preparing')
            AND ApexClass.Name = 'DnbMassUpdateBatch'
            LIMIT 1
        ];

        if (!runningJobs.isEmpty()) {
            System.debug(
                'DnbMassUpdateBatch already running. Scheduler skipped new launch.'
            );
            return;
        }

        try {
            Database.executeBatch(new DnbMassUpdateBatch(), 10);

            System.debug(
                'DnbMassUpdateBatch scheduled successfully.'
            );

        } catch (Exception e) {

            System.debug(
                'Scheduler failed to launch DnbMassUpdateBatch | Error: ' +
                e.getMessage() +
                ' | Stack: ' +
                e.getStackTraceString()
            );
        }
    }
}