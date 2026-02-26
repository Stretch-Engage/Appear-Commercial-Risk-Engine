public with sharing class DnbCreditEvaluator {

    public static void evaluate(DnbEnrichmentResult data) {

        if (data == null) {
            return;
        }

        // Default conservative state
        data.appearCreditRating = 'RED';
        data.ratingReason = 'Defaulted to RED';

        if (data.failureScorePercentile == null ||
            data.delinquencyScoreClass == null ||
            String.isBlank(data.financialStrength)) {

            data.ratingReason = 'Insufficient DNB financial data';
            return;
        }

        Decimal failureScore = data.failureScorePercentile;
        Decimal delinquencyScore = data.delinquencyScoreClass;
        String strength = data.financialStrength.trim().toUpperCase();

        if ((strength == '4A' || strength == '5A') &&
            failureScore >= 80 &&
            delinquencyScore <= 2) {

            data.appearCreditRating = 'GREEN';
            data.ratingReason = 'Strong financial strength and low risk indicators';
            return;
        }
        if ((strength == '2A' || strength == '3A' || strength == '4A') &&
            failureScore >= 50 &&
            failureScore < 80 &&
            delinquencyScore <= 4) {

            data.appearCreditRating = 'AMBER';
            data.ratingReason = 'Moderate financial strength and acceptable risk indicators';
            return;
        }

        data.ratingReason = 'Financial indicators below acceptable thresholds';
    }
}