public with sharing class DnbParser {

    public static DnbEnrichmentResult parse(String jsonString) {

        Map<String, Object> payload =
            (Map<String, Object>) JSON.deserializeUntyped(jsonString);

        Map<String, Object> organization =
            (Map<String, Object>) payload.get('organization');

        DnbEnrichmentResult result = new DnbEnrichmentResult();

        if (organization == null) {
            return result;
        }

        // Basic Info
        result.duns = (String) organization.get('duns');
        result.companyName = (String) organization.get('primaryName');
        result.postalCode = (String) organization.get('countryISOAlpha2Code');

        // dnbAssessment block
        Map<String, Object> assessment =
            (Map<String, Object>) organization.get('dnbAssessment');

        if (assessment != null) {

            // Failure Score
            Map<String, Object> failureScore =
                (Map<String, Object>) assessment.get('failureScore');

            if (failureScore != null) {
                result.failureScorePercentile =
                    (Decimal) failureScore.get('nationalPercentile');
            }

            // Delinquency Score
            Map<String, Object> delinquencyScore =
                (Map<String, Object>) assessment.get('delinquencyScore');

            if (delinquencyScore != null) {
                result.delinquencyScoreClass =
                    (Decimal) delinquencyScore.get('nationalPercentile');
            }
            
            // Standard Rating
            Map<String, Object> standardRating =
                (Map<String, Object>) assessment.get('standardRating');

            if (standardRating != null) {
                result.financialStrength =
                    (String) standardRating.get('financialStrength');
            }

            // Credit Limit
            Map<String, Object> creditLimit =
                (Map<String, Object>) assessment.get('creditLimitRecommendation');

            if (creditLimit != null) {
                Map<String, Object> maxLimit =
                    (Map<String, Object>) creditLimit.get('maximumRecommendedLimit');

                if (maxLimit != null) {
                    result.creditLimit =
                        (Decimal) maxLimit.get('value');
                }
            }
            // Transaction ID (root level)
            Map<String, Object> transactionDetail =
                (Map<String, Object>) payload.get('transactionDetail');

            if (transactionDetail != null) {
                result.transactionId =
                    (String) transactionDetail.get('transactionID');
            }

            result.hasOpenLiens = false;
            result.hasOpenJudgments = false;
            result.hasOpenBankruptcy = false;
        }

        return result;
    }
}