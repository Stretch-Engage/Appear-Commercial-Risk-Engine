public with sharing class DnbCreditFlowAction {

    @InvocableMethod(
        label='Run DNB Credit Engine'
        description='Runs DNB enrichment using Account Id and Scenario Key'
    )
    public static void run(List<DnbCreditFlowRequest> requests) {

        if (requests == null || requests.isEmpty()) {
            return;
        }

        for (DnbCreditFlowRequest req : requests) {

            if (req.accountId == null || String.isBlank(req.scenarioKey)) {
                continue;
            }

            DnbCreditEngine.run(
                req.accountId,
                req.scenarioKey
            );
        }
    }
}