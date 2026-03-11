public with sharing class DnbCreditEvaluator {

    public static void evaluate(DnbEnrichmentResult data) {

        if (data == null) {
            return;
        }

        // Conservative default
        data.appearCreditRating = 'RED';
        data.ratingReason = 'Defaulted to RED - No evaluation performed';

        // Required fields check
        if (data.failureScorePercentile == null ||
            data.delinquencyScoreClass == null ||
            String.isBlank(data.financialStrength)) {

            data.ratingReason = 'Insufficient DNB financial data';
            return;
        }

        Decimal failureScore = data.failureScorePercentile;
        Decimal delinquencyScore = data.delinquencyScoreClass;
        String strength = data.financialStrength.trim().toUpperCase();

        // GREEN
        if ((strength == '4A' || strength == '5A') &&
            failureScore >= 80 &&
            delinquencyScore <= 2) {

            data.appearCreditRating = 'GREEN';
            data.ratingReason = 'High financial strength with low risk indicators';
            return;
        }

        // AMBER
        if ((strength == '2A' || strength == '3A') &&
            failureScore >= 50 &&
            failureScore < 80 &&
            delinquencyScore <= 4) {

            data.appearCreditRating = 'AMBER';
            data.ratingReason = 'Moderate financial strength with acceptable risk profile';
            return;
        }

        // RED (explicit reasoning)
        data.ratingReason = 'Financial strength or risk indicators below policy thresholds';

  
    }
}