public with sharing class DnbCreditEngine {

    public static void run(
        Id accountId,
        String blockGroupName
    ) {

        if (accountId == null) {
            throw new IllegalArgumentException('AccountId cannot be null');
        }

        // Query Account
        Account acc = [
            SELECT Id, Name, DUNs_Number__c
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
            blockGroupName
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

        insert assessment;
        System.debug('DNB JSON: ' + json);
        System.debug('Result before evaluate: ' + result);
    }
}