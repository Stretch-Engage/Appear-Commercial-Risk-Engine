public with sharing class DnbMassUpdateLauncher {

        public class Request {
        @InvocableVariable
        public String runFlag;
    }
    
    @InvocableMethod(label='Launch DNB Mass Update Batch')
    public static void runBatch(List<Request> requests) {

        Database.executeBatch(
            new DnbMassUpdateBatch(),
            1
        );
    }
}