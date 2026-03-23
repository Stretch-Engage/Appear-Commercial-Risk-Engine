/**
 * DnbCreditFlowActionTest
 * Covers the invocable flow action wrapper around DnbCreditEngine.
 * Uses the same mock + CMT injection pattern as DnbCreditEngineTest.
 *
 * @author Sidharrth Nandhakumar
 * @date 23/03/2026
 */
@isTest
private class DnbCreditFlowActionTest {

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
                        '"dnbAssessment": {' +
                            '"failureScore": {"nationalPercentile": 100, "classScoreDescription": "Very low risk of financial stress"},' +
                            '"delinquencyScore": {"nationalPercentile": 100, "classScoreDescription": "Very low risk of payment delinquency"},' +
                            '"standardRating": {' +
                                '"financialStrength": "5A",' +
                                '"rating": "1",' +
                                '"ratingReason": [{"description": "Strong financial profile"}]' +
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
        acc.Name                = 'Test Account - Flow Action';
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

    // ─────────────────────────────────────────
    // Helpers
    // ─────────────────────────────────────────

    private static DnbCreditFlowRequest buildRequest(Id accountId, String scenarioKey) {
        DnbCreditFlowRequest req = new DnbCreditFlowRequest();
        req.accountId   = accountId;
        req.scenarioKey = scenarioKey;
        return req;
    }

    // ─────────────────────────────────────────
    // Happy Path — valid inputs, successful callout
    // ─────────────────────────────────────────

    @isTest
    static void testRun_validRequest_returnsSuccess() {
        injectMockConfig();
        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        Account acc = createTestAccount(DUNS);

        List<DnbCreditFlowRequest> requests = new List<DnbCreditFlowRequest>{
            buildRequest(acc.Id, SCENARIO_KEY)
        };

        Test.startTest();
        List<DnbCreditFlowAction.Result> results = DnbCreditFlowAction.run(requests);
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].success, 'Should be successful');
        System.assertEquals('Credit check completed successfully', results[0].message,
            'Should return success message');
    }

    // ─────────────────────────────────────────
    // Null accountId — caught and returned as failure
    // ─────────────────────────────────────────

    @isTest
    static void testRun_nullAccountId_returnsFailure() {
        List<DnbCreditFlowRequest> requests = new List<DnbCreditFlowRequest>{
            buildRequest(null, SCENARIO_KEY)
        };

        Test.startTest();
        List<DnbCreditFlowAction.Result> results = DnbCreditFlowAction.run(requests);
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(false, results[0].success, 'Should be unsuccessful');
        System.assertEquals('Missing accountId or scenarioKey', results[0].message,
            'Should surface the missing input message');
    }

    // ─────────────────────────────────────────
    // Blank scenarioKey — caught and returned as failure
    // ─────────────────────────────────────────

    @isTest
    static void testRun_blankScenarioKey_returnsFailure() {
        Account acc = createTestAccount(DUNS);

        List<DnbCreditFlowRequest> requests = new List<DnbCreditFlowRequest>{
            buildRequest(acc.Id, '')
        };

        Test.startTest();
        List<DnbCreditFlowAction.Result> results = DnbCreditFlowAction.run(requests);
        Test.stopTest();

        System.assertEquals(false, results[0].success, 'Should be unsuccessful');
        System.assertEquals('Missing accountId or scenarioKey', results[0].message,
            'Should surface missing scenarioKey message');
    }

    // ─────────────────────────────────────────
    // Engine throws — exception surfaced as message, not fault
    // ─────────────────────────────────────────

    @isTest
    static void testRun_engineThrows_exceptionCaughtAndReturned() {
        injectMockConfig();
        Test.setMock(HttpCalloutMock.class, new FailureMock());
        Account acc = createTestAccount(DUNS);

        List<DnbCreditFlowRequest> requests = new List<DnbCreditFlowRequest>{
            buildRequest(acc.Id, SCENARIO_KEY)
        };

        Test.startTest();
        List<DnbCreditFlowAction.Result> results = DnbCreditFlowAction.run(requests);
        Test.stopTest();

        System.assertEquals(false, results[0].success, 'Should be unsuccessful');
        System.assert(
            results[0].message.contains('DNB call failed'),
            'Should surface the callout error message: ' + results[0].message
        );
    }

    // ─────────────────────────────────────────
    // Multiple requests in one invocation
    // ─────────────────────────────────────────

    @isTest
    static void testRun_multipleRequests_eachProcessedIndependently() {
        injectMockConfig();
        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        Account acc1 = createTestAccount(DUNS);

        List<DnbCreditFlowRequest> requests = new List<DnbCreditFlowRequest>{
            buildRequest(acc1.Id, SCENARIO_KEY),
            buildRequest(null, SCENARIO_KEY)   // second one should fail
        };

        Test.startTest();
        List<DnbCreditFlowAction.Result> results = DnbCreditFlowAction.run(requests);
        Test.stopTest();

        System.assertEquals(2, results.size(), 'Should return two results');
        System.assertEquals(true,  results[0].success, 'First request should succeed');
        System.assertEquals(false, results[1].success, 'Second request should fail');
    }
}
