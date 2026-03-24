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
                        '"legalEvents": {' +
                            '"hasOpenLiens": false,' +
                            '"hasOpenJudgments": false,' +
                            '"hasOpenBankruptcy": false' +
                        '},' +
                        '"dnbAssessment": {' +
                            '"failureScore": {"nationalPercentile": 100, "classScoreDescription": "Very low risk of financial stress"},' +
                            '"delinquencyScore": {"nationalPercentile": 100, "classScoreDescription": "Very low risk of payment delinquency"},' +
                            '"standardRating": {' +
                                '"financialStrength": "5A",' +
                                '"rating": "1",' +
                                '"ratingReason": [' +
                                    '{"description": "Strong financial profile"},' +
                                    '{"description": "Active trading record"}' +
                                ']' +
                            '},' +
                            '"creditLimitRecommendation": {' +
                                '"maximumRecommendedLimit": {"value": 250000, "currency": "USD"}' +
                            '}' +
                        '}' +
                    '}' +
                '}'
            );
            return res;
        }
    }

    // German company — no credit limit, ratingOverrideReasons instead of ratingReason
    private class GermanCompanyMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(
                '{' +
                    '"transactionDetail": {"transactionID": "TXN-332716757-001"},' +
                    '"organization": {' +
                        '"duns": "332716757",' +
                        '"primaryName": "DEV Systemtechnik GmbH",' +
                        '"countryISOAlpha2Code": "DE",' +
                        '"legalEvents": {' +
                            '"hasOpenLiens": false,' +
                            '"hasOpenJudgments": false,' +
                            '"hasOpenBankruptcy": false' +
                        '},' +
                        '"dnbAssessment": {' +
                            '"failureScore": {' +
                                '"nationalPercentile": 0,' +
                                '"classScoreDescription": null,' +
                                '"scoreModel": {"description": "DE35744"}' +
                            '},' +
                            '"delinquencyScore": {},' +
                            '"standardRating": {' +
                                '"financialStrength": "BB",' +
                                '"rating": "BB4",' +
                                '"ratingReason": [],' +
                                '"ratingOverrideReasons": [' +
                                    '{"description": "Events - Serious legal events or criminal proceedings"}' +
                                ']' +
                            '},' +
                            '"nordicAAARating": {},' +
                            '"creditLimitRecommendation": {}' +
                        '}' +
                    '}' +
                '}'
            );
            return res;
        }
    }

    // Nordic company — no credit limit, nordicAAARating, empty delinquency
    private class NordicCompanyMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(
                '{' +
                    '"transactionDetail": {"transactionID": "TXN-345146201-001"},' +
                    '"organization": {' +
                        '"duns": "345146201",' +
                        '"primaryName": "Lyse Tele AS",' +
                        '"countryISOAlpha2Code": "NO",' +
                        '"legalEvents": {' +
                            '"hasOpenLiens": false,' +
                            '"hasOpenJudgments": true,' +
                            '"hasOpenBankruptcy": false' +
                        '},' +
                        '"dnbAssessment": {' +
                            '"failureScore": {' +
                                '"nationalPercentile": 70,' +
                                '"classScoreDescription": null,' +
                                '"scoreModel": {"description": "NO36021"}' +
                            '},' +
                            '"delinquencyScore": {},' +
                            '"standardRating": {' +
                                '"financialStrength": "N",' +
                                '"rating": "N2",' +
                                '"ratingReason": []' +
                            '},' +
                            '"nordicAAARating": {' +
                                '"rating": "A2",' +
                                '"financialStrength": {"description": "A"},' +
                                '"riskSegment": {"description": "2"}' +
                            '},' +
                            '"creditLimitRecommendation": {' +
                                '"maximumRecommendedLimit": {"value": 202700000, "currency": "NOK"}' +
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
        Account acc             = new Account();
        acc.Name                = 'Test Account - DnB Credit Engine';
        acc.DUNs_Number__c      = dunsNumber;
        acc.BillingCountryCode  = 'US';
        acc.BillingStateCode    = 'NY';
        acc.BillingStreet       = '123 Test Street';
        acc.BillingCity         = 'New York';
        acc.BillingPostalCode   = '10001';
        acc.ShippingCountryCode = 'US';
        acc.ShippingStateCode   = 'NY';
        acc.ShippingStreet      = '123 Test Street';
        acc.ShippingCity        = 'New York';
        acc.ShippingPostalCode  = '10001';
        insert acc;
        return acc;
    }

    private static Account createTestAccount(String dunsNumber, String countryCode) {
        Account acc             = new Account();
        acc.Name                = 'Test Account - DnB Credit Engine';
        acc.DUNs_Number__c      = dunsNumber;
        acc.BillingCountryCode  = countryCode;
        acc.BillingStreet       = '123 Test Street';
        acc.BillingCity         = 'Test City';
        acc.BillingPostalCode   = '10001';
        acc.ShippingCountryCode = countryCode;
        acc.ShippingStreet      = '123 Test Street';
        acc.ShippingCity        = 'Test City';
        acc.ShippingPostalCode  = '10001';
        insert acc;
        return acc;
    }

    // ─────────────────────────────────────────
    // Diagnostic
    // ─────────────────────────────────────────

    @isTest
    static void testDiagnostic_accountInsert() {
        try {
            Account acc            = new Account();
            acc.Name               = 'Test Account - DnB Credit Engine';
            acc.DUNs_Number__c     = DUNS;
            acc.BillingCountryCode = 'US';
            acc.BillingStateCode   = 'NY';
            acc.BillingStreet      = '123 Test Street';
            acc.BillingCity        = 'New York';
            acc.BillingPostalCode  = '10001';
            acc.ShippingCountryCode = 'US';
            acc.ShippingStateCode  = 'NY';
            acc.ShippingStreet     = '123 Test Street';
            acc.ShippingCity       = 'New York';
            acc.ShippingPostalCode = '10001';
            insert acc;
            System.assertNotEquals(null, acc.Id, 'Account Id should be populated after insert');
        } catch (Exception e) {
            System.assert(false, 'Account insert failed — add missing required fields: ' + e.getMessage());
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
            System.assertEquals('AccountId cannot be null', e.getMessage(), 'STEP 1: wrong exception message');
        }
        Test.stopTest();
    }

    // ─────────────────────────────────────────
    // STEP 2 — Blank / null / whitespace scenarioKey
    // ─────────────────────────────────────────

    @isTest
    static void testStep2_blankScenarioKey_throwsIllegalArgumentException() {
        Account acc = createTestAccount(DUNS);
        Test.startTest();
        try {
            DnbCreditEngine.run(acc.Id, '');
            System.assert(false, 'Expected exception not thrown');
        } catch (IllegalArgumentException e) {
            System.assertEquals('Scenario key cannot be blank', e.getMessage(), 'STEP 2: blank key');
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
            System.assertEquals('Scenario key cannot be blank', e.getMessage(), 'STEP 2: null key');
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
            System.assertEquals('Scenario key cannot be blank', e.getMessage(), 'STEP 2: whitespace key');
        }
        Test.stopTest();
    }

    // ─────────────────────────────────────────
    // STEP 3 — CMT resolution
    // ─────────────────────────────────────────

    @isTest
    static void testStep3_invalidScenarioKey_throwsIllegalArgumentException() {
        Account acc = createTestAccount(DUNS);
        Test.startTest();
        try {
            DnbCreditEngine.run(acc.Id, 'INVALID_SCENARIO_XYZ');
            System.assert(false, 'Expected exception not thrown');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('No active block group found'), 'STEP 3: wrong message');
        }
        Test.stopTest();
    }

    @isTest
    static void testStep3_mockConfigInjected_executionReachesStep7() {
        injectMockConfig();
        Account acc = createTestAccount(null);
        Test.startTest();
        try {
            DnbCreditEngine.run(acc.Id, SCENARIO_KEY);
            System.assert(false, 'Expected exception not thrown');
        } catch (IllegalArgumentException e) {
            System.assertEquals('Account does not have a DUNS number', e.getMessage(), 'STEP 3 passed');
        }
        Test.stopTest();
    }

    // ─────────────────────────────────────────
    // STEP 6 — Account SOQL
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
            System.assertEquals('Account does not have a DUNS number', e.getMessage(), 'STEP 6 passed');
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
            System.assertEquals('Account does not have a DUNS number', e.getMessage(), 'STEP 7: blank DUNS');
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
            System.assertEquals('Account does not have a DUNS number', e.getMessage(), 'STEP 7: null DUNS');
        }
        Test.stopTest();
    }

    // ─────────────────────────────────────────
    // STEP 8 — Callout
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
            System.assert(e.getMessage().contains('DNB call failed'), 'STEP 8: wrong message');
            System.assert(e.getMessage().contains('500'), 'STEP 8: missing status code');
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

        Account unchanged = [SELECT Appear_Credit_Rating__c FROM Account WHERE Id = :acc.Id];
        List<Credit_Assessment__c> assessments = [SELECT Id FROM Credit_Assessment__c WHERE Account__c = :acc.Id];
        System.assertEquals(null, unchanged.Appear_Credit_Rating__c, 'STEP 8: account should not update');
        System.assertEquals(0, assessments.size(), 'STEP 8: no assessment should be created');
    }

    // ─────────────────────────────────────────
    // STEP 9 + 10 — Parse + Evaluate
    // ─────────────────────────────────────────

    @isTest
    static void testStep9and10_insufficientDnbData_redRatingApplied() {
        injectMockConfig();
        Test.setMock(HttpCalloutMock.class, new InsufficientDataMock());
        Account acc = createTestAccount(DUNS);
        Test.startTest();
        DnbCreditEngine.run(acc.Id, SCENARIO_KEY);
        Test.stopTest();

        Account updated = [SELECT Appear_Credit_Rating__c, DnB_Rating_Reason__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals('RED_High_Risk', updated.Appear_Credit_Rating__c, 'STEP 9+10: should yield RED_High_Risk');
        System.assertEquals('Insufficient DNB financial data', updated.DnB_Rating_Reason__c, 'STEP 9+10: wrong reason');
    }

    // ─────────────────────────────────────────
    // STEP 11 — Account DML — Global company
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
            SELECT  Appear_Credit_Rating__c, DnB_Rating_Reason__c,
                    DnB_Last_Refresh_Date__c, DnB_Financial_Strength__c,
                    DnB_Last_Transaction_ID__c, DnB_Recommended_Maximum_Credit__c,
                    Appear_Rating_Reason__c, CCA__c, Failure_Score_Percentile__c,
                    Delinquency_Score__c, Recommended_Credit_Currency__c,
                    DnB_Failure_Score_Description__c, DnB_Delinquency_Score_Description__c,
                    DnB_Rating_Description__c
            FROM Account WHERE Id = :acc.Id
        ];

        System.assertEquals('GREEN_Very_Low_Risk',        updated.Appear_Credit_Rating__c,           'STEP 11: rating');
        System.assertEquals('Very low risk based on weighted DNB score and FSI', updated.DnB_Rating_Reason__c, 'STEP 11: reason');
        System.assertEquals('5A',                         updated.DnB_Financial_Strength__c,          'STEP 11: financial strength');
        System.assertEquals('TXN-185520819-001',          updated.DnB_Last_Transaction_ID__c,         'STEP 11: transaction ID');
        System.assertEquals('250000 USD',                 updated.DnB_Recommended_Maximum_Credit__c,  'STEP 11: credit limit');
        System.assertEquals('1',                          updated.CCA__c,                             'STEP 11: CCA');
        System.assertNotEquals(null,                      updated.DnB_Last_Refresh_Date__c,            'STEP 11: refresh date');
        System.assertEquals(updated.DnB_Rating_Reason__c, updated.Appear_Rating_Reason__c,            'STEP 11: rating reason mirror');
        System.assertEquals(100,                          updated.Failure_Score_Percentile__c,         'STEP 11: failure score');
        System.assertEquals(100,                          updated.Delinquency_Score__c,                'STEP 11: delinquency score');
        System.assertEquals('USD',                        updated.Recommended_Credit_Currency__c,      'STEP 11: currency');
        System.assertEquals('Very low risk of financial stress',      updated.DnB_Failure_Score_Description__c,      'STEP 11: failure desc');
        System.assertEquals('Very low risk of payment delinquency',   updated.DnB_Delinquency_Score_Description__c,  'STEP 11: delinquency desc');
        System.assertEquals('Strong financial profile; Active trading record', updated.DnB_Rating_Description__c,    'STEP 11: rating desc');
    }

    // ─────────────────────────────────────────
    // STEP 11 — German company
    // No credit limit → Not available
    // ratingOverrideReasons → DnB_Rating_Description__c
    // ─────────────────────────────────────────

    @isTest
    static void testStep11_germanCompany_noCreditLimit_showsNotAvailable() {
        injectMockConfig();
        Test.setMock(HttpCalloutMock.class, new GermanCompanyMock());
        Account acc = createTestAccount(DUNS, 'DE');
        Test.startTest();
        DnbCreditEngine.run(acc.Id, SCENARIO_KEY);
        Test.stopTest();

        Account updated = [
            SELECT  DnB_Recommended_Maximum_Credit__c,
                    DnB_Rating_Description__c,
                    DnB_Financial_Strength__c,
                    DnB_Failure_Score_Description__c,
                    DnB_Delinquency_Score_Description__c
            FROM Account WHERE Id = :acc.Id
        ];

        System.assertEquals('Not available',
            updated.DnB_Recommended_Maximum_Credit__c,
            'DE: no credit limit should show Not available');
        System.assertEquals('Events - Serious legal events or criminal proceedings',
            updated.DnB_Rating_Description__c,
            'DE: ratingOverrideReasons should populate DnB_Rating_Description__c');
        System.assertEquals('BB',
            updated.DnB_Financial_Strength__c,
            'DE: financial strength should be BB');
        System.assertEquals('DE35744',
            updated.DnB_Failure_Score_Description__c,
            'DE: failure desc should fall back to scoreModel');
        System.assertEquals('Delinquency score not available for this country',
            updated.DnB_Delinquency_Score_Description__c,
            'DE: delinquency desc should reflect unavailability');
    }

    // ─────────────────────────────────────────
    // STEP 11 — Nordic company
    // nordicAAARating fallback
    // ─────────────────────────────────────────

    @isTest
    static void testStep11_nordicCompany_fallbackFieldsPopulated() {
        injectMockConfig();
        Test.setMock(HttpCalloutMock.class, new NordicCompanyMock());
        Account acc = createTestAccount(DUNS, 'NO');
        Test.startTest();
        DnbCreditEngine.run(acc.Id, SCENARIO_KEY);
        Test.stopTest();

        Account updated = [
            SELECT  DnB_Financial_Strength__c,
                    DnB_Recommended_Maximum_Credit__c,
                    Recommended_Credit_Currency__c,
                    DnB_Failure_Score_Description__c,
                    DnB_Delinquency_Score_Description__c
            FROM Account WHERE Id = :acc.Id
        ];

        System.assertEquals('A',
            updated.DnB_Financial_Strength__c,
            'NO: financial strength should fall back to nordicAAARating');
        System.assertEquals('202700000 NOK',
            updated.DnB_Recommended_Maximum_Credit__c,
            'NO: credit limit should be populated');
        System.assertEquals('NOK',
            updated.Recommended_Credit_Currency__c,
            'NO: currency should be NOK');
        System.assertEquals('NO36021',
            updated.DnB_Failure_Score_Description__c,
            'NO: failure desc should fall back to scoreModel');
        System.assertEquals('Delinquency score not available for this country',
            updated.DnB_Delinquency_Score_Description__c,
            'NO: delinquency desc should reflect unavailability');
    }

    // ─────────────────────────────────────────
    // STEP 11 — Insufficient data
    // Credit limit not available
    // ─────────────────────────────────────────

    @isTest
    static void testStep11_insufficientData_creditLimitShowsNotAvailable() {
        injectMockConfig();
        Test.setMock(HttpCalloutMock.class, new InsufficientDataMock());
        Account acc = createTestAccount(DUNS);
        Test.startTest();
        DnbCreditEngine.run(acc.Id, SCENARIO_KEY);
        Test.stopTest();

        Account updated = [
            SELECT DnB_Recommended_Maximum_Credit__c
            FROM Account WHERE Id = :acc.Id
        ];

        System.assertEquals('Not available',
            updated.DnB_Recommended_Maximum_Credit__c,
            'Insufficient data: credit limit should show Not available not null USD');
    }

    // ─────────────────────────────────────────
    // STEP 12 — Credit Assessment DML
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
            SELECT  Account__c, DUNS__c, Assesment_Type__c, Assessment_Date__c,
                    Failure_Score_Percentile__c, Deliquency_Score__c, Financial_Strength__c,
                    Appear_Credit_Rating__c, Rating_Reason__c, DnB_Transaction_Id__c,
                    DnB_Failure_Score_Description__c, DnB_Delinquency_Score_Description__c,
                    DnB_Rating_Description__c
            FROM Credit_Assessment__c
            WHERE Account__c = :acc.Id
        ];

        System.assertEquals(1,                    assessments.size(),                        'STEP 12: one assessment');
        System.assertEquals(acc.Id,               assessments[0].Account__c,                 'STEP 12: account link');
        System.assertEquals(DUNS,                 assessments[0].DUNS__c,                    'STEP 12: DUNS');
        System.assertEquals('Initial',            assessments[0].Assesment_Type__c,           'STEP 12: type');
        System.assertEquals(100,                  assessments[0].Failure_Score_Percentile__c, 'STEP 12: failure score');
        System.assertEquals(100,                  assessments[0].Deliquency_Score__c,         'STEP 12: delinquency score');
        System.assertEquals('5A',                 assessments[0].Financial_Strength__c,       'STEP 12: financial strength');
        System.assertEquals('GREEN_Very_Low_Risk', assessments[0].Appear_Credit_Rating__c,    'STEP 12: rating');
        System.assertEquals('TXN-185520819-001',  assessments[0].DnB_Transaction_Id__c,       'STEP 12: transaction ID');
        System.assertNotEquals(null,              assessments[0].Assessment_Date__c,           'STEP 12: date stamped');
        System.assertEquals('Very low risk of financial stress',     assessments[0].DnB_Failure_Score_Description__c,     'STEP 12: failure desc');
        System.assertEquals('Very low risk of payment delinquency',  assessments[0].DnB_Delinquency_Score_Description__c, 'STEP 12: delinquency desc');
        System.assertEquals('Strong financial profile; Active trading record', assessments[0].DnB_Rating_Description__c,  'STEP 12: rating desc');
    }

    @isTest
    static void testStep12_germanCompany_ratingOverrideReasonsOnSnapshot() {
        injectMockConfig();
        Test.setMock(HttpCalloutMock.class, new GermanCompanyMock());
        Account acc = createTestAccount(DUNS, 'DE');
        Test.startTest();
        DnbCreditEngine.run(acc.Id, SCENARIO_KEY);
        Test.stopTest();

        List<Credit_Assessment__c> assessments = [
            SELECT DnB_Rating_Description__c, Financial_Strength__c
            FROM Credit_Assessment__c
            WHERE Account__c = :acc.Id
        ];

        System.assertEquals(1, assessments.size(), 'DE: one assessment should be created');
        System.assertEquals('Events - Serious legal events or criminal proceedings',
            assessments[0].DnB_Rating_Description__c,
            'DE: ratingOverrideReasons should be on snapshot');
        System.assertEquals('BB',
            assessments[0].Financial_Strength__c,
            'DE: financial strength on snapshot');
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

        System.assertEquals(1, assessments.size(), 'STEP 12: snapshot created even with insufficient data');
        System.assertEquals('RED_High_Risk', assessments[0].Appear_Credit_Rating__c, 'STEP 12: RED rating on snapshot');
    }

    @isTest
    static void testStep12_eachRunCreatesNewSnapshot_notOverwrite() {
        injectMockConfig();
        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        Account acc = createTestAccount(DUNS);

        Credit_Assessment__c priorSnap = new Credit_Assessment__c(
            Account__c              = acc.Id,
            DUNS__c                 = DUNS,
            Assesment_Type__c       = 'Initial',
            Assessment_Date__c      = System.now(),
            Appear_Credit_Rating__c = 'GREEN_Very_Low_Risk'
        );
        insert priorSnap;

        Test.startTest();
        DnbCreditEngine.run(acc.Id, SCENARIO_KEY);
        Test.stopTest();

        List<Credit_Assessment__c> assessments = [SELECT Id FROM Credit_Assessment__c WHERE Account__c = :acc.Id];
        System.assertEquals(2, assessments.size(), 'Each run should append not overwrite');
    }

    // ─────────────────────────────────────────
    // Full Run — MASS_UPDATE scenario key
    // ─────────────────────────────────────────

    @isTest
    static void testFullRun_massUpdateScenarioKey_completesSuccessfully() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        Account acc = createTestAccount(DUNS);
        Test.startTest();
        try {
            DnbCreditEngine.run(acc.Id, 'MASS_UPDATE');
            Account updated = [SELECT Appear_Credit_Rating__c FROM Account WHERE Id = :acc.Id];
            System.assertNotEquals(null, updated.Appear_Credit_Rating__c, 'MASS_UPDATE: rating should be set');
        } catch (IllegalArgumentException e) {
            System.assert(false, 'MASS_UPDATE CMT missing or inactive: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ─────────────────────────────────────────
    // Full Run — Germany country code
    // ─────────────────────────────────────────

    @isTest
    static void testFullRun_germanyAccount_completesAllSteps() {
        injectMockConfig();
        Test.setMock(HttpCalloutMock.class, new GermanCompanyMock());
        Account acc = createTestAccount(DUNS, 'DE');                                                                                                                                                                                                                                                                                                                                                                                                                                                      
        Test.startTest();                                                              
        DnbCreditEngine.run(acc.Id, SCENARIO_KEY);                                                                                                                          
        Test.stopTest();

        Account updated = [
            SELECT Appear_Credit_Rating__c, DnB_Last_Transaction_ID__c,
                   DnB_Recommended_Maximum_Credit__c
            FROM Account WHERE Id = :acc.Id                                                                                                            
        ];                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      

        System.assertNotEquals(null, updated.Appear_Credit_Rating__c,  'DE: rating should be set');
        System.assertEquals('TXN-332716757-001', updated.DnB_Last_Transaction_ID__c, 'DE: transaction ID');
        System.assertEquals('Not available', updated.DnB_Recommended_Maximum_Credit__c, 'DE: no credit limit');
    }
}                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               