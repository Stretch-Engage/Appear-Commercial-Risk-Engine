public with sharing class DnbCreditEngine {
    @TestVisible private static Dnb_Block_Group__mdt mockConfig = null;

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

        // Fetch DNB Data
        String json = DnbService.fetchCompanyData(
            acc.DUNs_Number__c,
            blockGroupName,
            acc.BillingCountryCode
        );

        // Parse
        DnbEnrichmentResult result =
            DnbParser.parse(json);

        // Evaluate
        DnbCreditEvaluator.evaluate(result);

        // Update Account
        acc.Appear_Credit_Rating__c = result.appearCreditRating;
        acc.DnB_Rating_Reason__c = result.ratingReason;
        acc.DnB_Last_Refresh_Date__c = System.now();
        acc.DnB_Financial_Strength__c = result.financialStrength;
        acc.DnB_Last_Transaction_ID__c = result.transactionId;
        acc.DnB_Recommended_Maximum_Credit__c = String.valueOf(result.creditLimit);
        acc.Appear_Rating_Reason__c = result.ratingReason;
        acc.CCA__c = result.compositeScore;
        acc.Failure_Score_Percentile__c = result.failureScorePercentile;
        acc.Delinquency_Score__c = result.delinquencyScoreClass;
        acc.Recommended_Credit_Currency__c = result.creditLimitCurrency;
        acc.DnB_Failure_Score_Description__c = result.failureScoreDescription;
        acc.DnB_Delinquency_Score_Description__c = result.delinquencyScoreDescription;
        acc.DnB_Rating_Description__c = result.dnbRatingDescription;

        update acc;

        // Insert Credit Assessment Snapshot
        Credit_Assessment__c assessment = new Credit_Assessment__c();
        assessment.Account__c = acc.Id;
        assessment.DUNS__c = acc.DUNs_Number__c;
        assessment.Assesment_Type__c = 'Initial';
        assessment.Assessment_Date__c = System.now();
        assessment.Failure_Score_Percentile__c = result.failureScorePercentile;
        assessment.Deliquency_Score__c = result.delinquencyScoreClass;
        assessment.Financial_Strength__c = result.financialStrength;
        assessment.Appear_Credit_Rating__c = result.appearCreditRating;
        assessment.Rating_Reason__c = result.ratingReason;
        assessment.DnB_Transaction_Id__c = result.transactionId;
        assessment.DnB_Failure_Score_Description__c = result.failureScoreDescription;
        assessment.DnB_Delinquency_Score_Description__c = result.delinquencyScoreDescription;
        assessment.DnB_Rating_Description__c = result.dnbRatingDescription;

        insert assessment;
    }

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