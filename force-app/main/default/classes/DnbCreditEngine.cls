/**
 * DnbCreditEngine
 * Main entry point for running a D&B credit assessment on an Account.
 * Pulls company data from D&B, evaluates it, and writes the results back
 * to the Account along with a Credit Assessment snapshot.
 *
 * @author Sidharrth Nandhakumar
 * @date 23/03/2026
 */
public with sharing class DnbCreditEngine {
    @TestVisible private static Dnb_Block_Group__mdt mockConfig = null;

    /**
     * Runs a full credit assessment for the given account under the specified scenario.
     * The scenarioKey determines which D&B block group (data blocks) to request.
     */
    public static void run(
        Id accountId,
        String scenarioKey
    ) {

        if (accountId == null) {
            throw new IllegalArgumentException('AccountId cannot be null');
        }

        if (String.isBlank(scenarioKey)) {
            throw new IllegalArgumentException('Scenario key cannot be blank');
        }

        // Resolve Block Group from Scenario
        Dnb_Block_Group__mdt config = mockConfig != null
            ? mockConfig
            : queryBlockGroup(scenarioKey);

        if (config == null ){
            throw new IllegalArgumentException(
                'No active block group found for scenario: ' + scenarioKey
            );
        }
        if (config.Active__c == false) {
            throw new IllegalArgumentException(
                'Block group for scenario is not active: ' + scenarioKey
            );
        }

        String blockGroupName = config.DeveloperName;

        // Query Account
        Account acc = [
            SELECT Id, Name, DUNs_Number__c, BillingCountryCode
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];

        if (String.isBlank(acc.DUNs_Number__c)) {
            throw new IllegalArgumentException('Account does not have a DUNS number');
        }

        // Hit the D&B API and get back the raw JSON payload
        String json = DnbService.fetchCompanyData(
            acc.DUNs_Number__c,
            blockGroupName,
            acc.BillingCountryCode
        );

        // Parse the raw JSON into a structured result object
        DnbEnrichmentResult result =
            DnbParser.parse(json);

        // Run scoring logic to determine the Appear credit rating
        DnbCreditEvaluator.evaluate(result);

        // Write all D&B scores and ratings back onto the Account
        acc.Appear_Credit_Rating__c = result.appearCreditRating;
        acc.DnB_Rating_Reason__c = result.ratingReason != null ? result.ratingReason : 'No rating reason provided';
        acc.DnB_Last_Refresh_Date__c = System.now();
        acc.DnB_Financial_Strength__c = result.financialStrength != null ? result.financialStrength : 'No financial strength data';
        acc.DnB_Last_Transaction_ID__c = result.transactionId != null ? result.transactionId : 'No transaction ID';
        acc.DnB_Recommended_Maximum_Credit__c = result.creditLimit != null ? String.valueOf(result.creditLimit) + ' ' + (result.creditLimitCurrency != null ? result.creditLimitCurrency : 'USD'): 'Not available';
        acc.Appear_Rating_Reason__c = result.ratingReason;
        acc.CCA__c = result.compositeScore != null ? result.compositeScore : 'No composite score';
        acc.Failure_Score_Percentile__c = result.failureScorePercentile != null ? result.failureScorePercentile : 0;
        acc.Delinquency_Score__c = result.delinquencyScoreClass != null ? result.delinquencyScoreClass : 0;
        acc.Recommended_Credit_Currency__c = result.creditLimitCurrency != null ? result.creditLimitCurrency : ' USD Set by default';
        acc.DnB_Failure_Score_Description__c = result.failureScoreDescription != null ? result.failureScoreDescription : 'No data available';
        acc.DnB_Delinquency_Score_Description__c = result.delinquencyScoreDescription != null ? result.delinquencyScoreDescription : 'No data available';
        acc.DnB_Rating_Description__c = result.dnbRatingDescription != null ? result.dnbRatingDescription : 'No data available';

        update acc;

        // Snapshot the assessment so we have a history of every time this ran
        Credit_Assessment__c assessment = new Credit_Assessment__c();
        assessment.Account__c = acc.Id ;
        assessment.DUNS__c = acc.DUNs_Number__c;
        assessment.Assesment_Type__c = 'Initial';
        assessment.Assessment_Date__c = System.now();
        assessment.Failure_Score_Percentile__c = result.failureScorePercentile != null ? result.failureScorePercentile : 0;
        assessment.Deliquency_Score__c = result.delinquencyScoreClass != null ? result.delinquencyScoreClass : 0;
        assessment.Financial_Strength__c = result.financialStrength != null ? result.financialStrength : 'No financial strength data';
        assessment.Appear_Credit_Rating__c = result.appearCreditRating;
        assessment.Rating_Reason__c = result.ratingReason;
        assessment.DnB_Transaction_Id__c = result.transactionId != null ? result.transactionId : 'No transaction ID';
        assessment.DnB_Failure_Score_Description__c = result.failureScoreDescription != null ? result.failureScoreDescription : 'No data available';
        assessment.DnB_Delinquency_Score_Description__c = result.delinquencyScoreDescription != null ? result.delinquencyScoreDescription : 'No data available';
        assessment.DnB_Rating_Description__c = result.dnbRatingDescription != null ? result.dnbRatingDescription : 'No data available';

        insert assessment;
    }

    // Looks up the block group metadata for a given scenario key.
    // Throws if nothing is found rather than returning null silently.
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