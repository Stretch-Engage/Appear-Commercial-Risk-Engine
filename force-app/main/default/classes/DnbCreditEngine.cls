public with sharing class DnbCreditEngine {

    public static DnbEnrichmentResult run(
        String duns,
        String blockGroupName
    ) {

        String json = DnbService.fetchCompanyData(
            duns,
            blockGroupName
        );

        DnbEnrichmentResult result =
            DnbParser.parse(json);

        DnbCreditEvaluator.evaluate(result);

        return result;
    }
}