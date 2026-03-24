/**
 * DnbCreditEvaluator
 * Takes a parsed D&B result and works out the Appear credit rating.
 * The final score is a weighted blend of three signals:
 *   - Failure Score Percentile  (45%)
 *   - Delinquency Score Class   (30%)
 *   - Financial Strength Index  (25%)
 *
 * @author Sidharrth Nandhakumar
 * @date 23/03/2026
 */
public with sharing class DnbCreditEvaluator {

    /**
     * Evaluates the enrichment result and sets appearCreditRating + ratingReason.
     * Defaults to RED_High_Risk if data is missing or scores are too low.
     */
    public static void evaluate(DnbEnrichmentResult data) {

        if (data == null) {
            return;
        }

        // Default to high risk — gets overwritten below if scores are good enough
        data.appearCreditRating = 'RED_High_Risk';
        data.ratingReason = 'Defaulted to RED - No evaluation performed';

        if (data.failureScorePercentile == null ||
            String.isBlank(data.financialStrength)) {

            data.ratingReason = 'Insufficient DNB financial data';
            return;
        }

        Decimal failureScore = data.failureScorePercentile;
        Decimal delinquencyScore = data.delinquencyScoreClass;
        Decimal fsiScore = DnbFsiScoringService.getScore(data.financialStrength);

        // Weighted composite score across the three D&B signals
        Decimal finalScore =
            (failureScore * 0.45) +
            (delinquencyScore * 0.30) +
            (fsiScore * 0.25);

        // Safety floor — if FSI is very weak we cap at AMBER regardless of the composite score
        if (fsiScore <= 15 && finalScore >= 61) {
            data.appearCreditRating = 'AMBER_Moderate_Risk';
            data.ratingReason = 'Weak financial strength limits rating despite score';
            return;
        }

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
            data.appearCreditRating = 'RED_Elevated_Risk';
            data.ratingReason = 'Elevated risk based on weighted DNB score and FSI';
            return;
        }

        data.appearCreditRating = 'RED_High_Risk';
        data.ratingReason = 'High risk based on weighted DNB score and FSI';
    }
}