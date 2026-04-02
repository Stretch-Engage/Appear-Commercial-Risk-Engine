/**
 * DnbParser
 * Parses the raw JSON response from the D&B API into a DnbEnrichmentResult.
 * Uses fallback chaining for regional data structures (e.g. Nordic countries
 * use nordicAAARating instead of standardRating for some fields).
 *
 * Phase 2 changes:
 *  - NEW: failureScoreClass from failureScore.classScore
 *  - NEW: delinquencyScorePercentile from delinquencyScore.nationalPercentile
 *  - NEW: delinquency scoreOverrideReasons[0-2]
 *  - NEW: riskSegment from standardRating.riskSegment
 *  - NEW: ratingReason1-5 as individual fields (joined string kept for Account)
 *  - NEW: financialConditionCode + financialConditionDescription
 *  - NEW: isHighRiskBusiness
 *  - NEW: companyinfo block (SIC, website, telephone, LEI)
 *  - NEW: entityresolution familyTreeRole
 *  - NEW: companyfinancials overview block (14 fields)
 *  - NEW: eventfilings extensions (secured filings, insolvency, judgments, CEO change)
 *
 * @author Sidharrth Nandhakumar
 * @date 23/03/2026 — Phase 2 updated 02/04/2026
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

        // ── Identity ──────────────────────────────────────────────────────────
        result.duns        = (String) org.get('duns');
        result.companyName = (String) org.get('primaryName');
        result.countryCode = (String) org.get('countryISOAlpha2Code'); 

        // Transaction ID — root level, not inside organization
        Map<String, Object> txn = (Map<String, Object>) payload.get('transactionDetail');
        if (txn != null) {
            result.transactionId = (String) txn.get('transactionID');
        }

        // ── Company Info → Account ────────────────────────────────────────────
        // SIC Code
        Map<String, Object> industryCode =
            (Map<String, Object>) org.get('primaryIndustryCode');
        if (industryCode != null) {
            result.sicCode        = (String) industryCode.get('usSicV4');
            result.sicDescription = (String) industryCode.get('usSicV4Description');
        }

        // Website — array, take first entry
        List<Object> websites = (List<Object>) org.get('websiteAddress');
        if (websites != null && !websites.isEmpty()) {
            Map<String, Object> site = (Map<String, Object>) websites[0];
            result.websiteUrl    = (String) site.get('url');
            result.websiteDomain = (String) site.get('domainName');
        }

        // Telephone — array, take first entry
        List<Object> phones = (List<Object>) org.get('telephone');
        if (phones != null && !phones.isEmpty()) {
            Map<String, Object> phone = (Map<String, Object>) phones[0];
            result.telephoneNumber  = (String) phone.get('telephoneNumber');
            result.telephoneIsdCode = (String) phone.get('isdCode');
        }

        // Legal Entity Identifier
        result.legalEntityIdentifier = (String) org.get('legalEntityIdentifier');

        // ── Family Tree Role → Account (entityresolution block) ───────────────
        // Requires entityresolution block in Dnb_Block_Group__mdt config
        Map<String, Object> corporateLinkage =
            (Map<String, Object>) org.get('corporateLinkage');
        if (corporateLinkage != null) {
            List<Object> treeRoles =
                (List<Object>) corporateLinkage.get('familytreeRolesPlayed');
            if (treeRoles != null && !treeRoles.isEmpty()) {
                Map<String, Object> role = (Map<String, Object>) treeRoles[0];
                result.familyTreeRole = (String) role.get('description');
            }
        }

        // ── D&B Assessment ────────────────────────────────────────────────────
        Map<String, Object> assessment =
            (Map<String, Object>) org.get('dnbAssessment');

        if (assessment == null) {
            return result;
        }

        // ── Failure Score ─────────────────────────────────────────────────────
        Map<String, Object> failureScore =
            (Map<String, Object>) assessment.get('failureScore');

        if (failureScore != null && !failureScore.isEmpty()) {
            result.failureScoreClass      = decimalFrom(failureScore, 'classScore');
            result.failureScorePercentile = decimalFrom(failureScore, 'nationalPercentile');

            // classScoreDescription is null for Nordic — fall back to scoreModel.description
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
        // Norway returns empty {} — default so evaluator can still score
        // PHASE 2 FIX: classScore and nationalPercentile are now separate fields
        Map<String, Object> delinquencyScore =
            (Map<String, Object>) assessment.get('delinquencyScore');

        if (delinquencyScore != null && !delinquencyScore.isEmpty()) {
            result.delinquencyScoreClass      = decimalFrom(delinquencyScore, 'classScore');
            result.delinquencyScorePercentile = decimalFrom(delinquencyScore, 'nationalPercentile');
            result.delinquencyScoreDescription = (String) delinquencyScore.get('classScoreDescription');

            // Override reasons — array, extract up to 3
            List<Object> overrides =
                (List<Object>) delinquencyScore.get('scoreOverrideReasons');
            if (overrides != null) {
                if (overrides.size() > 0) {
                    result.delinqOverrideReason1 =
                        descriptionFrom(overrides[0]);
                }
                if (overrides.size() > 1) {
                    result.delinqOverrideReason2 =
                        descriptionFrom(overrides[1]);
                }
                if (overrides.size() > 2) {
                    result.delinqOverrideReason3 =
                        descriptionFrom(overrides[2]);
                }
            }
        } else {
            // Not available for this country — neutral defaults so evaluator still runs
            result.delinquencyScoreClass       = 0;
            result.delinquencyScorePercentile  = 0;
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

        // Risk Segment
        if (standardRating != null) {
            result.riskSegment = (String) standardRating.get('riskSegment');
        }

        // Rating Reasons — individual fields + joined string for Account summary
        if (standardRating != null) {
            List<Object> ratingReasons =
                (List<Object>) standardRating.get('ratingReason');

            if (ratingReasons != null && !ratingReasons.isEmpty()) {
                List<String> descriptions = new List<String>();

                for (Integer i = 0; i < ratingReasons.size(); i++) {
                    String txt = descriptionFrom(ratingReasons[i]);
                    if (String.isNotBlank(txt)) {
                        descriptions.add(txt);
                        if      (i == 0) result.ratingReason1 = txt;
                        else if (i == 1) result.ratingReason2 = txt;
                        else if (i == 2) result.ratingReason3 = txt;
                        else if (i == 3) result.ratingReason4 = txt;
                        else if (i == 4) result.ratingReason5 = txt;
                    }
                }

                if (!descriptions.isEmpty()) {
                    result.dnbRatingDescription = String.join(descriptions, '; ');
                }
            }
        }

        // Nordic fallback for rating description — riskSegment description
        if (String.isBlank(result.dnbRatingDescription) && nordicRating != null) {
            Map<String, Object> riskSeg =
                (Map<String, Object>) nordicRating.get('riskSegment');
            if (riskSeg != null) {
                result.dnbRatingDescription = (String) riskSeg.get('description');
            }
        }

        // Last fallback — ratingOverrideReasons (e.g. "Out of business")
        if (String.isBlank(result.dnbRatingDescription) && standardRating != null) {
            List<Object> overrideReasons =
                (List<Object>) standardRating.get('ratingOverrideReasons');
            if (overrideReasons != null && !overrideReasons.isEmpty()) {
                List<String> descriptions = new List<String>();
                for (Object item : overrideReasons) {
                    String txt = descriptionFrom(item);
                    if (String.isNotBlank(txt)) {
                        descriptions.add(txt);
                    }
                }
                if (!descriptions.isEmpty()) {
                    result.dnbRatingDescription = String.join(descriptions, '; ');
                }
            }
        }

        // ── Financial Condition ───────────────────────────────────────────────
        Map<String, Object> financialCondition =
            (Map<String, Object>) assessment.get('financialCondition');

        if (financialCondition != null && !financialCondition.isEmpty()) {
            result.financialConditionCode        = decimalFrom(financialCondition, 'dnbCode');
            result.financialConditionDescription = (String) financialCondition.get('description');
        }

        // ── Credit Limit ──────────────────────────────────────────────────────
        Map<String, Object> creditLimitRec =
            (Map<String, Object>) assessment.get('creditLimitRecommendation');

        if (creditLimitRec != null) {
            Map<String, Object> maxLimit =
                (Map<String, Object>) creditLimitRec.get('maximumRecommendedLimit');
            if (maxLimit != null) {
                result.creditLimit         = decimalFrom(maxLimit, 'value');
                result.creditLimitCurrency = (String) maxLimit.get('currency');
            }
        }

        // ── High Risk Indicator ───────────────────────────────────────────────
        if (org.get('isHighRiskBusiness') != null) {
            result.isHighRiskBusiness = (Boolean) org.get('isHighRiskBusiness');
        }

        // ── Company Financials Overview ───────────────────────────────────────
        Map<String, Object> latestFinancials =
            (Map<String, Object>) org.get('latestFiscalFinancials');

        if (latestFinancials != null && !latestFinancials.isEmpty()) {
            result.financialsFilingDate        = (String) latestFinancials.get('filingDate');
            result.financialsReceivedTimestamp = (String) latestFinancials.get('receivedTimestamp');
            result.financialStatementUnits     = (String) latestFinancials.get('units');

            Map<String, Object> overview =
                (Map<String, Object>) latestFinancials.get('overview');

            if (overview != null) {
                result.totalAssets                    = decimalFrom(overview, 'totalAssets');
                result.totalCurrentAssets             = decimalFrom(overview, 'totalCurrentAssets');
                result.totalCurrentLiabilities        = decimalFrom(overview, 'totalCurrentLiabilities');
                result.totalLiabilities               = decimalFrom(overview, 'totalLiabilities');
                result.totalLiabilitiesEquity         = decimalFrom(overview, 'totalLiabilitiesEquity');
                result.tangibleNetWorth               = decimalFrom(overview, 'tangibleNetWorth');
                result.capitalStock                   = decimalFrom(overview, 'capitalStock');
                result.workingCapital                 = decimalFrom(overview, 'workingCapital');
                result.netCurrentAssets               = decimalFrom(overview, 'netCurrentAssets');
                result.currentRatio                   = decimalFrom(overview, 'currentRatio');
                result.currentLiabilitiesOverNetWorth = decimalFrom(overview, 'currentLiabilitiesOverNetWorth');
            }
        }

        // ── Legal Events (Phase 1 — preserved) ───────────────────────────────
        Map<String, Object> legalEvents =
            (Map<String, Object>) org.get('legalEvents');

        if (legalEvents != null) {
            result.hasOpenLiens      = legalEvents.get('hasOpenLiens')      == true;
            result.hasOpenJudgments  = legalEvents.get('hasOpenJudgments')  == true;
            result.hasOpenBankruptcy = legalEvents.get('hasOpenBankruptcy') == true;

            // Phase 2 — additional legal flags
            result.hasInsolvency = legalEvents.get('hasInsolvency') == true;
            result.hasJudgments  = legalEvents.get('hasJudgments')  == true;
        }

        // ── Financing Events (Phase 2) ────────────────────────────────────────
        Map<String, Object> financingEvents =
            (Map<String, Object>) org.get('financingEvents');

        if (financingEvents != null) {
            result.hasOpenSecuredFilings = financingEvents.get('hasOpenSecuredFilings') == true;
            result.hasSecuredFilings     = financingEvents.get('hasSecuredFilings')     == true;
        }

        // ── Significant Events (Phase 2) ──────────────────────────────────────
        Map<String, Object> significantEvents =
            (Map<String, Object>) org.get('significantEvents');

        if (significantEvents != null) {
            result.hasCEOChange = significantEvents.get('hasCEOChange') == true;
        }

        return result;
    }

    // ── Private Helpers ───────────────────────────────────────────────────────

    /**
     * Safely reads a Decimal from a map regardless of whether D&B returned
     * the value as Integer or Double. JSON.deserializeUntyped gives us Long
     * for whole numbers and Double for decimals — Decimal.valueOf handles both.
     */
    private static Decimal decimalFrom(Map<String, Object> m, String key) {
        Object val = m.get(key);
        if (val == null) return null;
        return Decimal.valueOf(String.valueOf(val));
    }

    /**
     * Extracts the 'description' field from a reason/role object.
     * Used for ratingReasons, overrideReasons, and familyTreeRoles.
     */
    private static String descriptionFrom(Object item) {
        if (item == null) return null;
        Map<String, Object> m = (Map<String, Object>) item;
        return (String) m.get('description');
    }
}