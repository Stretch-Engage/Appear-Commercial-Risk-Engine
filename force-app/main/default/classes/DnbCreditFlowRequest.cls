public class DnbCreditFlowRequest {

    @InvocableVariable(required=true)
    public Id accountId;

    @InvocableVariable(required=true)
    public String scenarioKey;
}