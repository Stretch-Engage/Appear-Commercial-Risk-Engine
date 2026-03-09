public with sharing class DnbMassUpdateLauncher {

    @InvocableMethod(label='Launch DNB Mass Update Batch')
    public static void runBatch(List<String> requests) {

        Database.executeBatch(
            new DnbMassUpdateBatch(),
            1
        );
    }
}