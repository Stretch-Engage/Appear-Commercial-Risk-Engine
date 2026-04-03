/**
 * DnbCreditEngine
 * Main entry point for running a D&B credit assessment on an Account.
 * Pulls company data from D&B, evaluates it, and writes the results back
 * to the Account along with a Credit Assessment snapshot.
 *
 * Phase 2 changes:
 *  - Account SOQL expanded to include new companyinfo fields for blank-check
 *  - Account write block: 8 new companyinfo/entityresolution fields
 *    (written only if blank — avoids overwriting RingLead-managed values)
 *  - Credit Assessment insert: 35 new Phase 2 fields across all blocks
 *  - Credit limit now written as separate numeric + currency fields on assessment
 *    (Account retains the combined string for backward compatibility)
 *  - compositeScore now written to Credit Assessment (was Account only in Phase 1)
 *
 * SF field API names marked // ← NEW where added in Phase 2.
 * Confirm all new API names against your org schema before deploying.
 *
 * @author Sidharrth Nandhakumar
 * @date 23/03/2026 — Phase 2 updated 02/04/2026
 */
public with sharing class DnbCreditEngine {

    @TestVisible private static Dnb_Block_Group__mdt mockConfig = null;

    /**
     * Runs a full credit assessment for the given account under the specified scenario.
     * The scenarioKey determines which D&B block group (data blocks) to request.
     */
    public static void run(Id accountId, String scenarioKey) {

        if (accountId == null) {
            throw new IllegalArgumentException('AccountId cannot be null');
        }
        if (String.isBlank(scenarioKey)) {
            throw new IllegalArgumentException('Scenario key cannot be blank');
        }

        // ── Block Group resolution ────────────────────────────────────────────
        Dnb_Block_Group__mdt config = mockConfig != null
            ? mockConfig
            : queryBlockGroup(scenarioKey);

        if (config == null) {
            throw new IllegalArgumentException(
                'No active block group found for scenario: ' + scenarioKey
            );
        }
        if (config.Active__c == false) {
            throw new IllegalArgumentException(
                'Block group for scenario is not active: ' + scenarioKey
            );
        }

        // ── Query Account ─────────────────────────────────────────────────────
        // Phase 2: expanded to include new companyinfo fields so we can blank-check
        // before writing — avoids overwriting values managed by RingLead
        Account acc = [
            SELECT
                Id,
                Name,
                DUNs_Number__c,
                BillingCountryCode,
                DnB_SIC_Code__c,
                DnB_SIC_Description__c,
                DnB_Website_URL__c,
                DnB_Website_Domain__c,
                DnB_Telephone_Number__c,
                DnB_Telephone_ISD_Code__c,
                DnB_Legal_Entity_Identifier__c,
                DnB_Family_Tree_Role__c
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];

        if (String.isBlank(acc.DUNs_Number__c)) {
            throw new IllegalArgumentException('Account does not have a DUNS number');
        }

        // ── API call → parse → evaluate ───────────────────────────────────────
        String jsonBody = DnbService.fetchCompanyData(
            acc.DUNs_Number__c,
            config.DeveloperName,
            acc.BillingCountryCode
        );

        DnbEnrichmentResult result = DnbParser.parse(jsonBody);
        DnbCreditEvaluator.evaluate(result);

        // ── Write to Account ──────────────────────────────────────────────────

        // Phase 1 fields — always overwrite (scoring data should always be current)
        acc.Appear_Credit_Rating__c          = result.appearCreditRating;
        acc.Appear_Rating_Reason__c          = result.ratingReason;
        acc.DnB_Rating_Reason__c             = result.ratingReason            != null ? result.ratingReason            : 'No rating reason provided';
        acc.DnB_Financial_Strength__c        = result.financialStrength        != null ? result.financialStrength        : 'No financial strength data';
        acc.DnB_Rating_Description__c        = result.dnbRatingDescription     != null ? result.dnbRatingDescription     : 'No data available';
        acc.DnB_Failure_Score_Description__c = result.failureScoreDescription  != null ? result.failureScoreDescription  : 'No data available';
        acc.DnB_Delinquency_Score_Description__c = result.delinquencyScoreDescription != null ? result.delinquencyScoreDescription : 'No data available';
        acc.Failure_Score_Percentile__c      = result.failureScorePercentile   != null ? result.failureScorePercentile   : 0;
        acc.Delinquency_Score__c             = result.delinquencyScorePercentile != null ? result.delinquencyScorePercentile : 0;
        acc.CCA__c                           = result.compositeScore            != null ? result.compositeScore            : 'No composite score';
        acc.DnB_Recommended_Maximum_Credit__c = result.creditLimit != null
            ? result.creditLimit.toPlainString() + ' ' + (result.creditLimitCurrency != null ? result.creditLimitCurrency : 'USD')
            : 'Not available';
        acc.Recommended_Credit_Currency__c  = result.creditLimitCurrency != null ? result.creditLimitCurrency : 'USD';
        acc.DnB_Last_Transaction_ID__c      = result.transactionId        != null ? result.transactionId       : 'No transaction ID';
        acc.DnB_Last_Refresh_Date__c        = System.now();

        // Phase 2 — companyinfo fields
        // Written only if currently blank — protects values managed by RingLead.
        // Once Yanying confirms which fields RingLead owns, this logic can be
        // tightened to a per-field decision rather than a blanket blank-check.
        if (String.isBlank(acc.DnB_SIC_Code__c)) {
            acc.DnB_SIC_Code__c = result.sicCode; // ← NEW
        }
        if (String.isBlank(acc.DnB_SIC_Description__c)) {
            acc.DnB_SIC_Description__c = result.sicDescription; // ← NEW
        }
        if (String.isBlank(acc.DnB_Website_URL__c)) {
            acc.DnB_Website_URL__c = result.websiteUrl; // ← NEW
        }
        if (String.isBlank(acc.DnB_Website_Domain__c)) {
            acc.DnB_Website_Domain__c = result.websiteDomain; // ← NEW
        }
        if (String.isBlank(acc.DnB_Telephone_Number__c)) {
            acc.DnB_Telephone_Number__c = result.telephoneNumber; // ← NEW
        }
        if (String.isBlank(acc.DnB_Telephone_ISD_Code__c)) {
            acc.DnB_Telephone_ISD_Code__c = result.telephoneIsdCode; // ← NEW
        }
        if (String.isBlank(acc.DnB_Legal_Entity_Identifier__c)) {
            acc.DnB_Legal_Entity_Identifier__c = result.legalEntityIdentifier; // ← NEW
        }
        if (String.isBlank(acc.DnB_Family_Tree_Role__c)) {
            acc.DnB_Family_Tree_Role__c = result.familyTreeRole; // ← NEW
        }

        update acc;

        // ── Write to Credit Assessment ────────────────────────────────────────
        Credit_Assessment__c assessment = new Credit_Assessment__c();

        // Phase 1 — core fields
        assessment.Account__c                    = acc.Id;
        assessment.DUNS__c                       = acc.DUNs_Number__c;
        assessment.Assesment_Type__c             = 'Initial';
        assessment.Assessment_Date__c            = System.now();
        assessment.Appear_Credit_Rating__c       = result.appearCreditRating;
        assessment.Rating_Reason__c              = result.ratingReason;
        assessment.DnB_Transaction_Id__c         = result.transactionId             != null ? result.transactionId             : 'No transaction ID';
        assessment.Financial_Strength__c         = result.financialStrength         != null ? result.financialStrength         : 'No financial strength data';
        assessment.DnB_Rating_Description__c     = result.dnbRatingDescription      != null ? result.dnbRatingDescription      : 'No data available';
        assessment.DnB_Failure_Score_Description__c     = result.failureScoreDescription  != null ? result.failureScoreDescription  : 'No data available';
        assessment.DnB_Delinquency_Score_Description__c = result.delinquencyScoreDescription != null ? result.delinquencyScoreDescription : 'No data available';
        assessment.Failure_Score_Percentile__c   = result.failureScorePercentile    != null ? result.failureScorePercentile    : 0;
        assessment.Deliquency_Score__c           = result.delinquencyScorePercentile != null ? result.delinquencyScorePercentile : 0;
        assessment.Has_Open_Liens__c             = result.hasOpenLiens;
        assessment.Has_Open_Judgements__c        = result.hasOpenJudgments;
        assessment.Has_Open_Bankruptcy__c        = result.hasOpenBankruptcy;

        // Phase 2 — financialstrengthinsight extensions
        assessment.Failure_Score_Class__c              = result.failureScoreClass;              // ← NEW
        assessment.Delinquency_Score_Class__c          = result.delinquencyScoreClass;          // ← NEW (fixed — now classScore 0–5)
        assessment.Delinquency_Score_Percentile__c     = result.delinquencyScorePercentile;     // ← NEW (was incorrectly in Deliquency_Score__c)
        assessment.Delinquency_Override_Reason_1__c    = result.delinqOverrideReason1;          // ← NEW
        assessment.Delinquency_Override_Reason_2__c    = result.delinqOverrideReason2;          // ← NEW
        assessment.Delinquency_Override_Reason_3__c    = result.delinqOverrideReason3;          // ← NEW
        assessment.Composite_Score__c                  = result.compositeScore;                 // ← NEW on CA (was Account only)
        assessment.Risk_Segment__c                     = result.riskSegment;                    // ← NEW
        assessment.Rating_Reason_1__c                  = result.ratingReason1;                  // ← NEW
        assessment.Rating_Reason_2__c                  = result.ratingReason2;                  // ← NEW
        assessment.Rating_Reason_3__c                  = result.ratingReason3;                  // ← NEW
        assessment.Rating_Reason_4__c                  = result.ratingReason4;                  // ← NEW
        assessment.Rating_Reason_5__c                  = result.ratingReason5;                  // ← NEW
        assessment.Financial_Condition_Code__c         = result.financialConditionCode;         // ← NEW
        assessment.Financial_Condition_Description__c  = result.financialConditionDescription;  // ← NEW
        assessment.Is_High_Risk_Business__c            = result.isHighRiskBusiness;             // ← NEW
        assessment.Credit_Limit__c                     = result.creditLimit;                    // ← NEW on CA as numeric
        assessment.Credit_Limit_Currency__c            = result.creditLimitCurrency;            // ← NEW on CA as separate field

        // Phase 2 — companyfinancials overview
        assessment.Total_Assets__c                     = result.totalAssets;                    // ← NEW
        assessment.Total_Current_Assets__c             = result.totalCurrentAssets;             // ← NEW
        assessment.Total_Current_Liabilities__c        = result.totalCurrentLiabilities;        // ← NEW
        assessment.Total_Liabilities__c                = result.totalLiabilities;               // ← NEW
        assessment.Total_Liabilities_Equity__c         = result.totalLiabilitiesEquity;         // ← NEW
        assessment.Tangible_Net_Worth__c               = result.tangibleNetWorth;               // ← NEW
        assessment.Capital_Stock__c                    = result.capitalStock;                   // ← NEW
        assessment.Working_Capital__c                  = result.workingCapital;                 // ← NEW
        assessment.Net_Current_Assets__c               = result.netCurrentAssets;               // ← NEW
        assessment.Current_Ratio__c                    = result.currentRatio;                   // ← NEW
        assessment.Current_Liabilities_Over_Net_Worth__c = result.currentLiabilitiesOverNetWorth; // ← NEW
        assessment.Financials_Filing_Date__c           = result.financialsFilingDate != null
            ? Date.valueOf(result.financialsFilingDate) : null;                                 // ← NEW
        assessment.Financials_Received_Timestamp__c    = result.financialsReceivedTimestamp;    // ← NEW (String — ISO 8601)
        assessment.Financial_Statement_Units__c        = result.financialStatementUnits;        // ← NEW

        // Phase 2 — eventfilings extensions
        assessment.Has_Open_Secured_Filings__c         = result.hasOpenSecuredFilings;          // ← NEW
        assessment.Has_Secured_Filings__c              = result.hasSecuredFilings;              // ← NEW
        assessment.Has_Insolvency__c                   = result.hasInsolvency;                  // ← NEW
        assessment.Has_Judgments__c                    = result.hasJudgments;                   // ← NEW
        assessment.Has_CEO_Change__c                   = result.hasCEOChange;                   // ← NEW

        insert assessment;
    }

    // ── Private helpers ───────────────────────────────────────────────────────

    private static Dnb_Block_Group__mdt queryBlockGroup(String scenarioKey) {
        try {
            return [
                SELECT DeveloperName, Active__c
                FROM Dnb_Block_Group__mdt
                WHERE Scenario_Key__c = :scenarioKey
                AND Active__c = true
                LIMIT 1
            ];
        } catch (QueryException e) {
            throw new IllegalArgumentException(
                'No active block group found for scenario: ' + scenarioKey
            );
        }
    }
}