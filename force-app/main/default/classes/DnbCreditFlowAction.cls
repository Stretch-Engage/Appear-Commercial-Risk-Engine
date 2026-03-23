/**
 * DnbCreditFlowAction
 * Exposes DnbCreditEngine as an invocable action so it can be called
 * directly from a Salesforce Flow. Errors are caught and returned as
 * part of the result rather than bubbling up to the Flow as faults.
 *
 * @author Sidharrth Nandhakumar
 * @date 23/03/2026
 */
public with sharing class DnbCreditFlowAction {

    // What gets passed back to the Flow after each request is processed
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
                // Surface the error message back to the Flow instead of failing hard
                r.success = false;
                r.message = e.getMessage();
            }

            results.add(r);
        }

        return results;
    }
}