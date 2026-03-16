@isTest
private class DnbMassUpdateBatchTest {

    // ─────────────────────────────────────────
    // Mock Classes
    // ─────────────────────────────────────────

    private class SuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(
                '{' +
                    '"transactionDetail": {"transactionID": "TXN-BATCH-001"},' +
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

    private class FailureMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"error": "Internal Server Error"}');
            return res;
        }
    }

    // ─────────────────────────────────────────
    // Helpers
    // ─────────────────────────────────────────

    private static void injectMockConfig() {
        DnbCreditEngine.mockConfig = new Dnb_Block_Group__mdt(
            DeveloperName = 'Credit_Check_Phase_1_ON_DEMAND',
            Active__c     = true
        );
    }

    private static Account createAccountWithDuns(String name, String duns) {
        Account acc             = new Account();
        acc.Name                = name;
        acc.DUNs_Number__c      = duns;
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

    private static Account createAccountWithoutDuns(String name) {
        Account acc             = new Account();
        acc.Name                = name;
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

    // ─────────────────────────────────────────
    // Stateful — Default Values
    // ─────────────────────────────────────────

    @isTest
    static void testStateful_allCountersDefaultToZero() {
        DnbMassUpdateBatch batch = new DnbMassUpdateBatch();

        System.assertEquals(0, batch.successCount,
            'successCount should default to 0');
        System.assertEquals(0, batch.failureCount,
            'failureCount should default to 0');
        System.assertEquals(0, batch.failedAccountIds.size(),
            'failedAccountIds should default to empty list');
    }

    // ─────────────────────────────────────────
    // start() — Query Locator Tests
    // ─────────────────────────────────────────

    @isTest
    static void testStart_accountWithDunsNoRefreshDate_includedInScope() {
        Account acc = createAccountWithDuns('Never Refreshed', '185520819');

        Test.startTest();
        DnbMassUpdateBatch batch = new DnbMassUpdateBatch();
        Database.QueryLocator ql = batch.start(null);
        Database.QueryLocatorIterator it = ql.iterator();
        Test.stopTest();

        Boolean found = false;
        while (it.hasNext()) {
            Account a = (Account) it.next();
            if (a.Id == acc.Id) { found = true; }
        }
        System.assert(found,
            'Account with DUNS and no refresh date should be in scope');
    }

    @isTest
    static void testStart_accountWithoutDuns_excludedFromScope() {
        Account acc = createAccountWithoutDuns('No DUNS Account');

        Test.startTest();
        DnbMassUpdateBatch batch = new DnbMassUpdateBatch();
        Database.QueryLocator ql = batch.start(null);
        Database.QueryLocatorIterator it = ql.iterator();
        Test.stopTest();

        Boolean found = false;
        while (it.hasNext()) {
            Account a = (Account) it.next();
            if (a.Id == acc.Id) { found = true; }
        }
        System.assert(!found,
            'Account without DUNS should be excluded from scope');
    }

    @isTest
    static void testStart_accountRefreshedToday_excludedFromScope() {
        Account acc = createAccountWithDuns('Fresh Account', '185520819');
        acc.DnB_Last_Refresh_Date__c = System.now();
        update acc;

        Test.startTest();
        DnbMassUpdateBatch batch = new DnbMassUpdateBatch();
        Database.QueryLocator ql = batch.start(null);
        Database.QueryLocatorIterator it = ql.iterator();
        Test.stopTest();

        Boolean found = false;
        while (it.hasNext()) {
            Account a = (Account) it.next();
            if (a.Id == acc.Id) { found = true; }
        }
        System.assert(!found,
            'Account refreshed today should be excluded — within 30 day window');
    }

    @isTest
    static void testStart_accountRefreshed31DaysAgo_includedInScope() {
        Account acc = createAccountWithDuns('Stale Account', '185520819');
        acc.DnB_Last_Refresh_Date__c = System.now().addDays(-31);
        update acc;

        Test.startTest();
        DnbMassUpdateBatch batch = new DnbMassUpdateBatch();
        Database.QueryLocator ql = batch.start(null);
        Database.QueryLocatorIterator it = ql.iterator();
        Test.stopTest();

        Boolean found = false;
        while (it.hasNext()) {
            Account a = (Account) it.next();
            if (a.Id == acc.Id) { found = true; }
        }
        System.assert(found,
            'Account refreshed 31 days ago should be included in scope');
    }

    // ─────────────────────────────────────────
    // execute() — Success Path
    // ─────────────────────────────────────────

 @isTest
static void testExecute_success_incrementsSuccessCount() {
    injectMockConfig();
    Test.setMock(HttpCalloutMock.class, new SuccessMock());
    Account acc = createAccountWithDuns('Success Account', '185520819');

    DnbMassUpdateBatch batch = new DnbMassUpdateBatch();

    Test.startTest();
    batch.execute(null, new List<Account>{ acc });
    Test.stopTest();

    System.assertEquals(1, batch.successCount,
        'successCount should be 1 after successful run');
    System.assertEquals(0, batch.failureCount,
        'failureCount should be 0 after successful run');
    System.assertEquals(0, batch.failedAccountIds.size(),
        'failedAccountIds should be empty after successful run');
}

    @isTest
    static void testExecute_success_accountFieldsUpdated() {
        injectMockConfig();
        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        Account acc = createAccountWithDuns('Fields Account', '185520819');

        Test.startTest();
        Database.executeBatch(new DnbMassUpdateBatch(), 1);
        Test.stopTest();

        Account updated = [
            SELECT  Appear_Credit_Rating__c,
                    DnB_Last_Refresh_Date__c,
                    DnB_Last_Transaction_ID__c,
                    DnB_Financial_Strength__c
            FROM Account WHERE Id = :acc.Id
        ];

        System.assertEquals('GREEN_Very_Low_Risk',
            updated.Appear_Credit_Rating__c,
            'Rating should be GREEN_Very_Low_Risk from mock response');
        System.assertNotEquals(null,
            updated.DnB_Last_Refresh_Date__c,
            'Last refresh date should be stamped after batch run');
        System.assertEquals('TXN-BATCH-001',
            updated.DnB_Last_Transaction_ID__c,
            'Transaction ID should match mock response');
        System.assertEquals('5A',
            updated.DnB_Financial_Strength__c,
            'Financial strength should match mock response');
    }

    @isTest
    static void testExecute_success_assessmentSnapshotCreated() {
        injectMockConfig();
        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        Account acc = createAccountWithDuns('Snapshot Account', '185520819');

        Test.startTest();
        Database.executeBatch(new DnbMassUpdateBatch(), 1);
        Test.stopTest();

        List<Credit_Assessment__c> assessments = [
            SELECT Id, Assesment_Type__c
            FROM Credit_Assessment__c
            WHERE Account__c = :acc.Id
        ];
        System.assertEquals(1, assessments.size(),
            'One assessment snapshot should be created per batch run');
        System.assertEquals('Initial', assessments[0].Assesment_Type__c,
            'Assessment type should be Initial');
    }

    // ─────────────────────────────────────────
    // execute() — Failure Path
    // ─────────────────────────────────────────

@isTest
static void testExecute_failure_incrementsFailureCount() {
    injectMockConfig();
    Test.setMock(HttpCalloutMock.class, new FailureMock());
    Account acc = createAccountWithDuns('Failure Account', '185520819');

    DnbMassUpdateBatch batch = new DnbMassUpdateBatch();

    Test.startTest();
    // Call execute() directly so stateful properties
    // are updated on the same batch instance we inspect
    batch.execute(null, new List<Account>{ acc });
    Test.stopTest();

    System.assertEquals(0, batch.successCount,
        'successCount should be 0 after failure');
    System.assertEquals(1, batch.failureCount,
        'failureCount should be 1 after callout failure');
}

@isTest
static void testExecute_failure_accountIdTrackedInFailedList() {
    injectMockConfig();
    Test.setMock(HttpCalloutMock.class, new FailureMock());
    Account acc = createAccountWithDuns('Tracked Failure', '185520819');

    DnbMassUpdateBatch batch = new DnbMassUpdateBatch();

    Test.startTest();
    // Call execute() directly — same reason as above
    batch.execute(null, new List<Account>{ acc });
    Test.stopTest();

    System.assertEquals(1, batch.failedAccountIds.size(),
        'One failed account ID should be tracked');
    System.assertEquals(acc.Id, batch.failedAccountIds[0],
        'Tracked ID should match the failed account');
}

    @isTest
    static void testExecute_failure_accountNotUpdated() {
        injectMockConfig();
        Test.setMock(HttpCalloutMock.class, new FailureMock());
        Account acc = createAccountWithDuns('Unchanged Account', '185520819');

        Test.startTest();
        Database.executeBatch(new DnbMassUpdateBatch(), 1);
        Test.stopTest();

        Account unchanged = [
            SELECT Appear_Credit_Rating__c, DnB_Last_Refresh_Date__c
            FROM Account WHERE Id = :acc.Id
        ];
        System.assertEquals(null, unchanged.Appear_Credit_Rating__c,
            'Rating should not be set when callout fails');
        System.assertEquals(null, unchanged.DnB_Last_Refresh_Date__c,
            'Refresh date should not be stamped when callout fails');
    }

    @isTest
    static void testExecute_failure_noAssessmentCreated() {
        injectMockConfig();
        Test.setMock(HttpCalloutMock.class, new FailureMock());
        Account acc = createAccountWithDuns('No Assessment', '185520819');

        Test.startTest();
        Database.executeBatch(new DnbMassUpdateBatch(), 1);
        Test.stopTest();

        List<Credit_Assessment__c> assessments = [
            SELECT Id FROM Credit_Assessment__c WHERE Account__c = :acc.Id
        ];
        System.assertEquals(0, assessments.size(),
            'No assessment should be created when callout fails');
    }

    @isTest
    static void testExecute_failure_batchDoesNotThrow() {
        injectMockConfig();
        Test.setMock(HttpCalloutMock.class, new FailureMock());
        createAccountWithDuns('Exception Account', '185520819');

        Test.startTest();
        Boolean threw = false;
        try {
            Database.executeBatch(new DnbMassUpdateBatch(), 1);
        } catch (Exception e) {
            threw = true;
        }
        Test.stopTest();

        System.assert(!threw,
            'Batch should never throw — exceptions are caught internally in execute()');
    }

    // ─────────────────────────────────────────
    // finish() Tests
    // ─────────────────────────────────────────

    @isTest
    static void testFinish_success_completesWithoutException() {
        injectMockConfig();
        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        createAccountWithDuns('Finish Success', '185520819');

        Test.startTest();
        Boolean threw = false;
        try {
            Database.executeBatch(new DnbMassUpdateBatch(), 1);
        } catch (Exception e) {
            threw = true;
        }
        Test.stopTest();

        System.assert(!threw,
            'finish() should complete without exception on success path');
    }

    @isTest
    static void testFinish_withFailures_completesWithoutException() {
        injectMockConfig();
        Test.setMock(HttpCalloutMock.class, new FailureMock());
        createAccountWithDuns('Finish Failure', '185520819');

        Test.startTest();
        Boolean threw = false;
        try {
            Database.executeBatch(new DnbMassUpdateBatch(), 1);
        } catch (Exception e) {
            threw = true;
        }
        Test.stopTest();

        System.assert(!threw,
            'finish() should complete without exception even when failures exist');
    }
}