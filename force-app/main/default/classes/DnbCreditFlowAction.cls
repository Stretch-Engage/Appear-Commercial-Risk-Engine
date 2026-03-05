public with sharing class DnbCreditFlowAction {

    public class Request {

        @InvocableVariable(required=true)
        public Id accountId;

        @InvocableVariable(required=true)
        public String scenarioKey;
    }

    @InvocableMethod(
        label='Run DNB Credit Engine'
        description='Runs DNB enrichment using Account Id and Scenario Key'
    )
    public static void run(List<Request> requests) {

        if (requests == null || requests.isEmpty()) {
            return;
        }

        for (Request req : requests) {

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