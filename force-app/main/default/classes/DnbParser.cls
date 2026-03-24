/**
 * DnbParser
 * Parses the raw JSON response from the D&B API into a DnbEnrichmentResult.
 * Uses fallback chaining for regional data structures (e.g. Nordic countries
 * use nordicAAARating instead of standardRating for some fields).
 *
 * @author Sidharrth Nandhakumar
 * @date 23/03/2026
 */
public with sharing class DnbParser {

    public static DnbEnrichmentResult parse(String jsonString) {

        Map<String, Object> payload =
            (Map<String, Object>) JSON.deserializeUntyped(jsonString);

        Map<String, Object> org =
            (Map<String, Object>) payload.get('organization');

        DnbEnrichmentResult result = new DnbEnrichmentResult();

        if (org == null) {
            return result;
        }

        result.duns        = (String) org.get('duns');
        result.companyName = (String) org.get('primaryName');
        result.postalCode  = (String) org.get('countryISOAlpha2Code');

        // Transaction ID — root level not inside organization
        Map<String, Object> txn = (Map<String, Object>) payload.get('transactionDetail');
        if (txn != null) {
            result.transactionId = (String) txn.get('transactionID');
        }

        Map<String, Object> assessment =
            (Map<String, Object>) org.get('dnbAssessment');

        if (assessment == null) {
            return result;
        }

        // ── Failure Score ─────────────────────────────────────────────────────
        Map<String, Object> failureScore =
            (Map<String, Object>) assessment.get('failureScore');

        if (failureScore != null) {
            result.failureScorePercentile =
                (Decimal) failureScore.get('nationalPercentile');

            // classScoreDescription is null for Nordic — fall back to scoreModel
            String failureDesc = (String) failureScore.get('classScoreDescription');
            if (String.isBlank(failureDesc)) {
                Map<String, Object> scoreModel =
                    (Map<String, Object>) failureScore.get('scoreModel');
                if (scoreModel != null) {
                    failureDesc = (String) scoreModel.get('description');
                }
            }
            result.failureScoreDescription = failureDesc;
        }

        // ── Delinquency Score ─────────────────────────────────────────────────
        // Norway returns empty {} — default to 0 so evaluator can still score
        Map<String, Object> delinquencyScore =
            (Map<String, Object>) assessment.get('delinquencyScore');

        if (delinquencyScore != null && !delinquencyScore.isEmpty()) {
            result.delinquencyScoreClass =
                (Decimal) delinquencyScore.get('nationalPercentile');
            result.delinquencyScoreDescription =
                (String) delinquencyScore.get('classScoreDescription');
        } else {
            // Not available for this country — neutral value so scoring still runs
            result.delinquencyScoreClass       = 0;
            result.delinquencyScoreDescription = 'Delinquency score not available for this country';
        }

        // ── Standard Rating + Nordic Fallback ─────────────────────────────────
        Map<String, Object> standardRating =
            (Map<String, Object>) assessment.get('standardRating');

        Map<String, Object> nordicRating =
            (Map<String, Object>) assessment.get('nordicAAARating');

        // Financial Strength — prefer standardRating, fall back to nordicAAARating
        if (standardRating != null) {
            String fsGlobal = (String) standardRating.get('financialStrength');
            if (String.isNotBlank(fsGlobal) && fsGlobal != 'N') {
                result.financialStrength = fsGlobal;
            }
        }
        if (String.isBlank(result.financialStrength) && nordicRating != null) {
            Map<String, Object> nordicFS =
                (Map<String, Object>) nordicRating.get('financialStrength');
            if (nordicFS != null) {
                result.financialStrength = (String) nordicFS.get('description');
            }
        }

        // Composite Score — prefer standardRating.rating, fall back to nordicAAARating.rating
        String compositeGlobal = standardRating != null
            ? (String) standardRating.get('rating') : null;

        Boolean compositeIsValid = String.isNotBlank(compositeGlobal)
            && !compositeGlobal.startsWith('N');

        result.compositeScore = compositeIsValid
            ? compositeGlobal
            : (nordicRating != null ? (String) nordicRating.get('rating') : null);

        // Rating Description — join standardRating reasons, fall back to nordicAAARating riskSegment
        if (standardRating != null) {
            List<Object> ratingReasons =
                (List<Object>) standardRating.get('ratingReason');

            if (ratingReasons != null && !ratingReasons.isEmpty()) {
                List<String> descriptions = new List<String>();
                for (Object item : ratingReasons) {
                    Map<String, Object> reason = (Map<String, Object>) item;
                    String txt = (String) reason.get('description');
                    if (String.isNotBlank(txt)) {
                        descriptions.add(txt);
                    }
                }
                if (!descriptions.isEmpty()) {
                    result.dnbRatingDescription = String.join(descriptions, '; ');
                }
            }
        }
        if (String.isBlank(result.dnbRatingDescription) && nordicRating != null) {
            Map<String, Object> riskSegment =
                (Map<String, Object>) nordicRating.get('riskSegment');
            if (riskSegment != null) {
                result.dnbRatingDescription = (String) riskSegment.get('description');
            }
        }

        // ── Credit Limit ──────────────────────────────────────────────────────
        Map<String, Object> creditLimitRec =
            (Map<String, Object>) assessment.get('creditLimitRecommendation');

        if (creditLimitRec != null) {
            Map<String, Object> maxLimit =
                (Map<String, Object>) creditLimitRec.get('maximumRecommendedLimit');
            if (maxLimit != null) {
                result.creditLimit         = (Decimal) maxLimit.get('value');
                result.creditLimitCurrency = (String)  maxLimit.get('currency');
            }
        }

        // ── Legal Events ──────────────────────────────────────────────────────
        Map<String, Object> legalEvents =
            (Map<String, Object>) org.get('legalEvents');

        if (legalEvents != null) {
            result.hasOpenLiens =
                legalEvents.get('hasOpenLiens') == true;
            result.hasOpenJudgments =
                legalEvents.get('hasOpenJudgments') == true;
            result.hasOpenBankruptcy =
                legalEvents.get('hasOpenBankruptcy') == true;
        }

        return result;
    }
}