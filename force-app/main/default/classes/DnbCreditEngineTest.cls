@isTest
private class DnbCreditEngineTest {

    // ─────────────────────────────────────────
    // Constants
    // ─────────────────────────────────────────

    private static final String DUNS         = '185520819';
    private static final String SCENARIO_KEY = 'ON_DEMAND';
    private static final String BLOCK_GROUP  = 'Credit_Check_Phase_1_ON_DEMAND';

    // ─────────────────────────────────────────
    // CMT Injection Helper
    // Bypasses queryBlockGroup() SOQL in tests
    // In production mockConfig is always null
    // so queryBlockGroup() always runs normally
    // ─────────────────────────────────────────

    private static void injectMockConfig() {
        DnbCreditEngine.mockConfig = new Dnb_Block_Group__mdt(
            DeveloperName = BLOCK_GROUP,
            Active__c     = true
        );
    }

    // ─────────────────────────────────────────
    // Mock Classes
    // ─────────────────────────────────────────

    private class SuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(
                '{' +
                    '"transactionDetail": {"transactionID": "TXN-185520819-001"},' +
                    '"organization": {' +
                        '"duns": "185520819",' +
                        '"primaryName": "Acme Corporation",' +
                        '"countryISOAlpha2Code": "US",' +
                        '"dnbAssessment": {' +
                            '"failureScore":     {"nationalPercentile": 100},' +
                            '"delinquencyScore": {"nationalPercentile": 100},' +
                            '"standardRating":   {"financialStrength": "5A", "rating": "1"},' +
                            '"creditLimitRecommendation": {' +
                                '"maximumRecommendedLimit": {"value": 250000}' +
                            '}' +
                        '}' +
                    '}' +
                '}'
            );
            return res;
        }
    }

    private class InsufficientDataMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(
                '{' +
                    '"transactionDetail": {"transactionID": "TXN-185520819-002"},' +
                    '"organization": {' +
                        '"duns": "185520819",' +
                        '"primaryName": "Acme Corporation"' +
                    '}' +
                '}'
            );
            return res;
        }
    }

    private class FailureMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"error": "Internal Server Error"}');
            return res;
        }
    }

    // ─────────────────────────────────────────
    // Account Helper
    // ─────────────────────────────────────────

private static Account createTestAccount(String dunsNumber) {
  Account acc                = new Account();
    acc.Name                   = 'Test Account - DnB Credit Engine';
    acc.DUNs_Number__c         = dunsNumber;
    acc.BillingCountryCode     = 'US';
    acc.BillingStateCode       = 'NY';
    acc.BillingStreet          = '123 Test Street';
    acc.BillingCity            = 'New York';
    acc.BillingPostalCode      = '10001';
    acc.ShippingCountryCode    = 'US';
    acc.ShippingStateCode      = 'NY';
    acc.ShippingStreet         = '123 Test Street';
    acc.ShippingCity           = 'New York';
    acc.ShippingPostalCode     = '10001';
    insert acc;
    return acc;
}

    // ─────────────────────────────────────────
    // DIAGNOSTIC — Run this first in isolation
    // If this fails your org has required fields
    // on Account — share the error and I will
    // update createTestAccount accordingly
    // ─────────────────────────────────────────

    
    @isTest
static void testDiagnostic_accountInsert() {
    try {
        Account acc            = new Account();
        acc.Name               = 'Test Account - DnB Credit Engine';
        acc.DUNs_Number__c     = DUNS;
        acc.BillingCountryCode     = 'US';
        acc.BillingStateCode       = 'NY';
        acc.BillingStreet          = '123 Test Street';
        acc.BillingCity            = 'New York';
        acc.BillingPostalCode      = '10001';
        acc.ShippingCountryCode    = 'US';
        acc.ShippingStateCode      = 'NY';
        acc.ShippingStreet         = '123 Test Street';
        acc.ShippingCity           = 'New York';
        acc.ShippingPostalCode     = '10001';
        
        insert acc;
        System.assertNotEquals(null, acc.Id,
            'Account Id should be populated after insert');
    } catch (Exception e) {
        System.assert(false,
            'Account insert failed — add missing required fields ' +
            'to createTestAccount: ' + e.getMessage()
        );
    }
}

    // ─────────────────────────────────────────
    // STEP 1 — Null accountId guard
    // ─────────────────────────────────────────

    @isTest
    static void testStep1_nullAccountId_throwsIllegalArgumentException() {
        Test.startTest();
        try {
            DnbCreditEngine.run(null, SCENARIO_KEY);
            System.assert(false, 'Expected exception not thrown');
        } catch (IllegalArgumentException e) {
            System.assertEquals(
                'AccountId cannot be null',
                e.getMessage(),
                'STEP 1: wrong exception message'
            );
        }
        Test.stopTest();
    }

    // ─────────────────────────────────────────
    // STEP 2 — Blank / null / whitespace
    // scenarioKey guard
    // ─────────────────────────────────────────

    @isTest
    static void testStep2_blankScenarioKey_throwsIllegalArgumentException() {
        Account acc = createTestAccount(DUNS);
        Test.startTest();
        try {
            DnbCreditEngine.run(acc.Id, '');
            System.assert(false, 'Expected exception not thrown');
        } catch (IllegalArgumentException e) {
            System.assertEquals(
                'Scenario key cannot be blank',
                e.getMessage(),
                'STEP 2: wrong exception message for blank key'
            );
        }
        Test.stopTest();
    }

    @isTest
    static void testStep2_nullScenarioKey_throwsIllegalArgumentException() {
        Account acc = createTestAccount(DUNS);
        Test.startTest();
        try {
            DnbCreditEngine.run(acc.Id, null);
            System.assert(false, 'Expected exception not thrown');
        } catch (IllegalArgumentException e) {
            System.assertEquals(
                'Scenario key cannot be blank',
                e.getMessage(),
                'STEP 2: wrong exception message for null key'
            );
        }
        Test.stopTest();
    }

    @isTest
    static void testStep2_whitespaceScenarioKey_throwsIllegalArgumentException() {
        Account acc = createTestAccount(DUNS);
        Test.startTest();
        try {
            DnbCreditEngine.run(acc.Id, '   ');
            System.assert(false, 'Expected exception not thrown');
        } catch (IllegalArgumentException e) {
            System.assertEquals(
                'Scenario key cannot be blank',
                e.getMessage(),
                'STEP 2: wrong exception message for whitespace key'
            );
        }
        Test.stopTest();
    }

    // ─────────────────────────────────────────
    // STEP 3 — CMT resolution
    // Invalid key hits queryBlockGroup() and
    // throws IllegalArgumentException from
    // the catch block
    // ─────────────────────────────────────────

    @isTest
    static void testStep3_invalidScenarioKey_throwsIllegalArgumentException() {
        Account acc = createTestAccount(DUNS);
        Test.startTest();
        try {
            DnbCreditEngine.run(acc.Id, 'INVALID_SCENARIO_XYZ');
            System.assert(false, 'Expected exception not thrown');
        } catch (IllegalArgumentException e) {
            System.assert(
                e.getMessage().contains('No active block group found'),
                'STEP 3: should surface friendly error for invalid scenario key'
            );
        }
        Test.stopTest();
    }

    @isTest
    static void testStep3_mockConfigInjected_executionReachesStep7() {
        // Proves mockConfig bypasses SOQL and
        // execution continues past STEP 3
        // Null DUNS stops at STEP 7 as proof
        injectMockConfig();
        Account acc = createTestAccount(null);
        Test.startTest();
        try {
            DnbCreditEngine.run(acc.Id, SCENARIO_KEY);
            System.assert(false, 'Expected exception not thrown');
        } catch (IllegalArgumentException e) {
            System.assertEquals(
                'Account does not have a DUNS number',
                e.getMessage(),
                'STEP 3 passed — execution reached STEP 7 as expected'
            );
        }
        Test.stopTest();
    }

    // ─────────────────────────────────────────
    // STEP 6 — Account SOQL executes
    // Proved by reaching STEP 7
    // ─────────────────────────────────────────

    @isTest
    static void testStep6_accountQueriedSuccessfully() {
        injectMockConfig();
        Account acc = createTestAccount(null);
        Test.startTest();
        try {
            DnbCreditEngine.run(acc.Id, SCENARIO_KEY);
            System.assert(false, 'Expected exception not thrown');
        } catch (IllegalArgumentException e) {
            System.assertEquals(
                'Account does not have a DUNS number',
                e.getMessage(),
                'STEP 6 passed — account SOQL ran and returned record'
            );
        }
        Test.stopTest();
    }

    // ─────────────────────────────────────────
    // STEP 7 — Blank / null DUNS guard
    // ─────────────────────────────────────────

    @isTest
    static void testStep7_blankDuns_throwsIllegalArgumentException() {
        injectMockConfig();
        Account acc = createTestAccount('');
        Test.startTest();
        try {
            DnbCreditEngine.run(acc.Id, SCENARIO_KEY);
            System.assert(false, 'Expected exception not thrown');
        } catch (IllegalArgumentException e) {
            System.assertEquals(
                'Account does not have a DUNS number',
                e.getMessage(),
                'STEP 7: wrong exception message for blank DUNS'
            );
        }
        Test.stopTest();
    }

    @isTest
    static void testStep7_nullDuns_throwsIllegalArgumentException() {
        injectMockConfig();
        Account acc = createTestAccount(null);
        Test.startTest();
        try {
            DnbCreditEngine.run(acc.Id, SCENARIO_KEY);
            System.assert(false, 'Expected exception not thrown');
        } catch (IllegalArgumentException e) {
            System.assertEquals(
                'Account does not have a DUNS number',
                e.getMessage(),
                'STEP 7: wrong exception message for null DUNS'
            );
        }
        Test.stopTest();
    }

    // ─────────────────────────────────────────
    // STEP 8 — DNB callout executes
    // ─────────────────────────────────────────

    @isTest
    static void testStep8_calloutFailure_throwsCalloutException() {
        injectMockConfig();
        Test.setMock(HttpCalloutMock.class, new FailureMock());
        Account acc = createTestAccount(DUNS);
        Test.startTest();
        try {
            DnbCreditEngine.run(acc.Id, SCENARIO_KEY);
            System.assert(false, 'Expected CalloutException not thrown');
        } catch (CalloutException e) {
            System.assert(
                e.getMessage().contains('DNB call failed'),
                'STEP 8: should surface DNB callout failure message'
            );
            System.assert(
                e.getMessage().contains('500'),
                'STEP 8: should include HTTP 500 status code'
            );
        }
        Test.stopTest();
    }

    @isTest
    static void testStep8_calloutFailure_noDmlCommitted() {
        injectMockConfig();
        Test.setMock(HttpCalloutMock.class, new FailureMock());
        Account acc = createTestAccount(DUNS);
        Test.startTest();
        try {
            DnbCreditEngine.run(acc.Id, SCENARIO_KEY);
        } catch (CalloutException e) { }
        Test.stopTest();

        Account unchanged = [
            SELECT Appear_Credit_Rating__c FROM Account WHERE Id = :acc.Id
        ];
        List<Credit_Assessment__c> assessments = [
            SELECT Id FROM Credit_Assessment__c WHERE Account__c = :acc.Id
        ];

        System.assertEquals(null, unchanged.Appear_Credit_Rating__c,
            'STEP 8: account should not be updated when callout fails');
        System.assertEquals(0, assessments.size(),
            'STEP 8: no assessment should be created when callout fails');
    }

    // ─────────────────────────────────────────
    // STEP 9 + 10 — Parse + Evaluate
    // Insufficient D&B data triggers RED rating
    // ─────────────────────────────────────────

    @isTest
    static void testStep9and10_insufficientDnbData_redRatingApplied() {
        injectMockConfig();
        Test.setMock(HttpCalloutMock.class, new InsufficientDataMock());
        Account acc = createTestAccount(DUNS);
        Test.startTest();
        DnbCreditEngine.run(acc.Id, SCENARIO_KEY);
        Test.stopTest();

        Account updated = [
            SELECT Appear_Credit_Rating__c, DnB_Rating_Reason__c
            FROM Account WHERE Id = :acc.Id
        ];

        System.assertEquals('RED_High_Risk',
            updated.Appear_Credit_Rating__c,
            'STEP 9+10: insufficient data should yield RED_High_Risk'
        );
        System.assertEquals('Insufficient DNB financial data',
            updated.DnB_Rating_Reason__c,
            'STEP 9+10: reason should reflect missing assessment block'
        );
    }

    // ─────────────────────────────────────────
    // STEP 11 — Account DML update
    // All 8 fields verified
    // ─────────────────────────────────────────

    @isTest
    static void testStep11_allAccountFieldsUpdated() {
        injectMockConfig();
        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        Account acc = createTestAccount(DUNS);
        Test.startTest();
        DnbCreditEngine.run(acc.Id, SCENARIO_KEY);
        Test.stopTest();

        Account updated = [
            SELECT  Appear_Credit_Rating__c,
                    DnB_Rating_Reason__c,
                    DnB_Last_Refresh_Date__c,
                    DnB_Financial_Strength__c,
                    DnB_Last_Transaction_ID__c,
                    DnB_Recommended_Maximum_Credit__c,
                    Appear_Rating_Reason__c,
                    CCA__c
            FROM Account
            WHERE Id = :acc.Id
        ];

        System.assertEquals('GREEN_Very_Low_Risk',
            updated.Appear_Credit_Rating__c,
            'STEP 11: credit rating should be GREEN_Very_Low_Risk'
        );
        System.assertEquals('Very low risk based on weighted DNB score and FSI',
            updated.DnB_Rating_Reason__c,
            'STEP 11: rating reason should match evaluator output'
        );
        System.assertEquals('5A',
            updated.DnB_Financial_Strength__c,
            'STEP 11: financial strength should match mock'
        );
        System.assertEquals('TXN-185520819-001',
            updated.DnB_Last_Transaction_ID__c,
            'STEP 11: transaction ID should match mock'
        );
        System.assertEquals('250000',
            updated.DnB_Recommended_Maximum_Credit__c,
            'STEP 11: credit limit should match mock'
        );
        System.assertEquals('1',
            updated.CCA__c,
            'STEP 11: CCA should match composite score from mock'
        );
        System.assertNotEquals(null,
            updated.DnB_Last_Refresh_Date__c,
            'STEP 11: last refresh date should be stamped'
        );
        System.assertEquals(
            updated.DnB_Rating_Reason__c,
            updated.Appear_Rating_Reason__c,
            'STEP 11: Appear_Rating_Reason__c should mirror DnB_Rating_Reason__c'
        );
    }

    // ─────────────────────────────────────────
    // STEP 12 — Credit Assessment DML insert
    // All fields verified
    // ─────────────────────────────────────────

    @isTest
    static void testStep12_assessmentSnapshotAllFieldsPopulated() {
        injectMockConfig();
        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        Account acc = createTestAccount(DUNS);
        Test.startTest();
        DnbCreditEngine.run(acc.Id, SCENARIO_KEY);
        Test.stopTest();

        List<Credit_Assessment__c> assessments = [
            SELECT  Account__c,
                    DUNS__c,
                    Assesment_Type__c,
                    Assessment_Date__c,
                    Failure_Score_Percentile__c,
                    Deliquency_Score__c,
                    Financial_Strength__c,
                    Appear_Credit_Rating__c,
                    Rating_Reason__c,
                    DnB_Transaction_Id__c
            FROM Credit_Assessment__c
            WHERE Account__c = :acc.Id
        ];

        System.assertEquals(1,         assessments.size(),
            'STEP 12: exactly one assessment should be created');
        System.assertEquals(acc.Id,    assessments[0].Account__c,
            'STEP 12: should link to correct account');
        System.assertEquals(DUNS,      assessments[0].DUNS__c,
            'STEP 12: DUNS should match account value');
        System.assertEquals('Initial', assessments[0].Assesment_Type__c,
            'STEP 12: type should be Initial');
        System.assertEquals(100,       assessments[0].Failure_Score_Percentile__c,
            'STEP 12: failure score should match mock');
        System.assertEquals(100,       assessments[0].Deliquency_Score__c,
            'STEP 12: delinquency score should match mock');
        System.assertEquals('5A',      assessments[0].Financial_Strength__c,
            'STEP 12: financial strength should match mock');
        System.assertEquals('GREEN_Very_Low_Risk',
            assessments[0].Appear_Credit_Rating__c,
            'STEP 12: rating should match evaluator output');
        System.assertEquals('TXN-185520819-001',
            assessments[0].DnB_Transaction_Id__c,
            'STEP 12: transaction ID should match mock');
        System.assertNotEquals(null,   assessments[0].Assessment_Date__c,
            'STEP 12: assessment date should be stamped');
    }

    @isTest
    static void testStep12_insufficientData_snapshotStillCreated() {
        injectMockConfig();
        Test.setMock(HttpCalloutMock.class, new InsufficientDataMock());
        Account acc = createTestAccount(DUNS);
        Test.startTest();
        DnbCreditEngine.run(acc.Id, SCENARIO_KEY);
        Test.stopTest();

        List<Credit_Assessment__c> assessments = [
            SELECT Appear_Credit_Rating__c, Rating_Reason__c
            FROM Credit_Assessment__c
            WHERE Account__c = :acc.Id
        ];

        System.assertEquals(1, assessments.size(),
            'STEP 12: snapshot should be created even with insufficient D&B data');
        System.assertEquals('RED_High_Risk',
            assessments[0].Appear_Credit_Rating__c,
            'STEP 12: snapshot should reflect RED rating');
    }

    @isTest
static void testStep12_eachRunCreatesNewSnapshot_notOverwrite() {
    // Proves assessments are inserted not upserted
    // Two separate transactions simulate two runs
    injectMockConfig();
    Test.setMock(HttpCalloutMock.class, new SuccessMock());
    Account acc = createTestAccount(DUNS);

    // First run — own transaction
    Test.startTest();
    DnbCreditEngine.run(acc.Id, SCENARIO_KEY);
    Test.stopTest();

    // Inject again as mockConfig resets between test boundaries
    injectMockConfig();
    Test.setMock(HttpCalloutMock.class, new SuccessMock());

    // Second run — own transaction
    Test.startTest();
    DnbCreditEngine.run(acc.Id, SCENARIO_KEY);
    Test.stopTest();

    List<Credit_Assessment__c> assessments = [
        SELECT Id FROM Credit_Assessment__c
        WHERE Account__c = :acc.Id
    ];
    System.assertEquals(2, assessments.size(),
        'Each run should append a new snapshot independently');
}

    // ─────────────────────────────────────────
    // Full Run — MASS_UPDATE scenario key
    // ─────────────────────────────────────────

    @isTest
    static void testFullRun_massUpdateScenarioKey_completesSuccessfully() {
        // Uses real CMT query — verifies MASS_UPDATE
        // record exists and is active in your org
        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        Account acc = createTestAccount(DUNS);
        Test.startTest();
        try {
            DnbCreditEngine.run(acc.Id, 'MASS_UPDATE');
            Account updated = [
                SELECT Appear_Credit_Rating__c FROM Account WHERE Id = :acc.Id
            ];
            System.assertNotEquals(null, updated.Appear_Credit_Rating__c,
                'MASS_UPDATE: full run should complete and set rating');
        } catch (IllegalArgumentException e) {
            System.assert(false,
                'MASS_UPDATE CMT record missing or inactive: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ─────────────────────────────────────────
    // Full Run — Germany country code
    // ─────────────────────────────────────────

    @isTest
    static void testFullRun_germanyAccount_completesAllSteps() {
        injectMockConfig();
        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Account acc                = new Account();
        acc.Name                   = 'DE Test Account - DnB Credit Engine';
        acc.DUNs_Number__c         = DUNS;
        acc.BillingCountryCode     = 'DE';
        acc.BillingStreet          = '123 Test Strasse';
        acc.BillingCity            = 'Berlin';
        acc.BillingPostalCode      = '10115';
        acc.ShippingCountryCode    = 'DE';
        acc.ShippingStreet         = '123 Test Strasse';
        acc.ShippingCity           = 'Berlin';
        acc.ShippingPostalCode     = '10115';
        
        insert acc;

        Test.startTest();
        DnbCreditEngine.run(acc.Id, SCENARIO_KEY);
        Test.stopTest();

        Account updated = [
            SELECT Appear_Credit_Rating__c, DnB_Last_Transaction_ID__c
            FROM Account WHERE Id = :acc.Id
        ];
        System.assertEquals('GREEN_Very_Low_Risk',
            updated.Appear_Credit_Rating__c,
            'DE account: full run should complete with GREEN rating'
        );
        System.assertEquals('TXN-185520819-001',
            updated.DnB_Last_Transaction_ID__c,
            'DE account: transaction ID should be set'
        );
    }
}