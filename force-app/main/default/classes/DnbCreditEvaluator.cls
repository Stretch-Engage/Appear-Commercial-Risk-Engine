public with sharing class DnbCreditEvaluator {

    public static void evaluate(DnbEnrichmentResult data) {

        if (data == null) {
            return;
        }

        data.appearCreditRating = 'RED_High_Risk';
        data.ratingReason = 'Defaulted to RED - No evaluation performed';

        if (data.failureScorePercentile == null ||
            data.delinquencyScoreClass == null ||
            String.isBlank(data.financialStrength)) {

            data.ratingReason = 'Insufficient DNB financial data';
            return;
        }

        Decimal failureScore = data.failureScorePercentile;
        Decimal delinquencyScore = data.delinquencyScoreClass;

        Decimal weightedScore = (failureScore * 0.6) + (delinquencyScore * 0.4);

        Decimal fsiScore = DnbFsiScoringService.getScore(data.financialStrength);

        Decimal finalScore = (weightedScore * 0.7) + (fsiScore * 0.3);

        if (finalScore >= 81) {
            data.appearCreditRating = 'GREEN_Very_Low_Risk';
            data.ratingReason = 'Very low risk based on weighted DNB score and FSI';
            return;
        }

        if (finalScore >= 61) {
            data.appearCreditRating = 'GREEN_Low_Risk';
            data.ratingReason = 'Low risk based on weighted DNB score and FSI';
            return;
        }

        if (finalScore >= 41) {
            data.appearCreditRating = 'AMBER_Moderate_Risk';
            data.ratingReason = 'Moderate risk based on weighted DNB score and FSI';
            return;
        }

        if (finalScore >= 21) {
            data.appearCreditRating = 'AMBER_Elevated_Risk';
            data.ratingReason = 'Elevated risk based on weighted DNB score and FSI';
            return;
        }

        data.appearCreditRating = 'RED_High_Risk';
        data.ratingReason = 'High risk based on weighted DNB score and FSI';
    }
}