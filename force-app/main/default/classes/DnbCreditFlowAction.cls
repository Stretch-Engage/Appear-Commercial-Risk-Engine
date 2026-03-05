public with sharing class DnbCreditFlowAction {

    public class Result {
        @InvocableVariable
        public String message;

        @InvocableVariable
        public Boolean success;
    }

    @InvocableMethod(
        label='Run DNB Credit Engine'
        description='Runs DNB enrichment using Account Id and Scenario Key'
    )
    public static List<Result> run(List<DnbCreditFlowRequest> requests) {

        List<Result> results = new List<Result>();

        for (DnbCreditFlowRequest req : requests) {

            Result r = new Result();

            try {
                if (req.accountId == null || String.isBlank(req.scenarioKey)) {
                    r.success = false;
                    r.message = 'Missing accountId or scenarioKey';
                } else {
                    DnbCreditEngine.run(
                        req.accountId,
                        req.scenarioKey
                    );

                    r.success = true;
                    r.message = 'Credit check completed successfully';
                }

            } catch (Exception e) {
                r.success = false;
                r.message = e.getMessage();
            }

            results.add(r);
        }

        return results;
    }
}