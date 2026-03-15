@isTest
private class DnbServiceTest {

    // ─────────────────────────────────────────
    // Mock Classes
    // ─────────────────────────────────────────

    private class SuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"transactionDetail":{"transactionID":"test-001"},"organization":{"duns":"185520819"}}');
            return res;
        }
    }

    private class SuccessMockDE implements HttpCalloutMock {
        public String capturedEndpoint;
        public HttpResponse respond(HttpRequest req) {
            capturedEndpoint = req.getEndpoint();
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"transactionDetail":{"transactionID":"test-de-001"}}');
            return res;
        }
    }

    private class FailureMock implements HttpCalloutMock {
        private Integer statusCode;
        private String body;

        public FailureMock(Integer statusCode, String body) {
            this.statusCode = statusCode;
            this.body = body;
        }
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody(body);
            return res;
        }
    }

    // ─────────────────────────────────────────
    // DUNS Validation Tests
    // ─────────────────────────────────────────

    @isTest
    static void testBlankDuns_throwsIllegalArgumentException() {
        try {
            DnbService.fetchCompanyData('', 'Credit_Check_Phase_1_ON_DEMAND', 'US');
            System.assert(false, 'Expected IllegalArgumentException was not thrown');
        } catch (IllegalArgumentException e) {
            System.assertEquals(
                'DUNS number cannot be blank',
                e.getMessage(),
                'Exception message mismatch'
            );
        }
    }

    @isTest
    static void testNullDuns_throwsIllegalArgumentException() {
        try {
            DnbService.fetchCompanyData(null, 'Credit_Check_Phase_1_ON_DEMAND', 'US');
            System.assert(false, 'Expected IllegalArgumentException was not thrown');
        } catch (IllegalArgumentException e) {
            System.assertEquals(
                'DUNS number cannot be blank',
                e.getMessage(),
                'Exception message mismatch'
            );
        }
    }

    @isTest
    static void testWhitespaceDuns_throwsIllegalArgumentException() {
        try {
            DnbService.fetchCompanyData('   ', 'Credit_Check_Phase_1_ON_DEMAND', 'US');
            System.assert(false, 'Expected IllegalArgumentException was not thrown');
        } catch (IllegalArgumentException e) {
            System.assertEquals(
                'DUNS number cannot be blank',
                e.getMessage()
            );
        }
    }

    // ─────────────────────────────────────────
    // Custom Metadata Tests
    // ─────────────────────────────────────────

    @isTest
    static void testNullBlockGroup_throwsIllegalArgumentException() {
        try {
            DnbService.fetchCompanyData('185520819', 'NonExistentBlockGroup', 'US');
            System.assert(false, 'Expected IllegalArgumentException was not thrown');
        } catch (IllegalArgumentException e) {
            System.assert(
                e.getMessage().contains('Block group not found or inactive'),
                'Unexpected message: ' + e.getMessage()
            );
        }
    }

    @isTest
    static void testInactiveBlockGroup_throwsIllegalArgumentException() {
        try {
            DnbService.fetchCompanyData('185520819', 'NonExistentBlockGroup', 'US');
            System.assert(false, 'Expected IllegalArgumentException was not thrown');
        } catch (IllegalArgumentException e) {
            System.assert(
                e.getMessage().contains('Block group not found or inactive'),
                'Unexpected message: ' + e.getMessage()
            );
        }
    }

    // ─────────────────────────────────────────
    // HTTP Response Tests
    // ─────────────────────────────────────────

    @isTest
    static void testSuccessfulCallout_returnsBody() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        String result = DnbService.fetchCompanyData(
            '185520819',
            'Credit_Check_Phase_1_ON_DEMAND',
            'US'
        );
        Test.stopTest();

        System.assertNotEquals(null, result, 'Response body should not be null');
        System.assert(
            result.contains('transactionID'),
            'Response body missing expected transactionID field'
        );
        System.assert(
            result.contains('185520819'),
            'Response body should contain the DUNS number'
        );
    }

    @isTest
    static void testUnauthorizedResponse_throwsCalloutException() {
        Test.setMock(HttpCalloutMock.class, new FailureMock(401, '{"error":"Unauthorized"}'));

        try {
            Test.startTest();
            DnbService.fetchCompanyData(
                '185520819',
                'Credit_Check_Phase_1_ON_DEMAND',
                'US'
            );
            Test.stopTest();
            System.assert(false, 'Expected CalloutException was not thrown');
        } catch (CalloutException e) {
            System.assert(
                e.getMessage().contains('401'),
                'Exception should contain status code 401'
            );
            System.assert(
                e.getMessage().contains('DNB call failed'),
                'Exception should contain failure message'
            );
        }
    }

    @isTest
    static void testServerErrorResponse_throwsCalloutException() {
        Test.setMock(HttpCalloutMock.class, new FailureMock(500, '{"error":"Internal Server Error"}'));

        try {
            Test.startTest();
            DnbService.fetchCompanyData(
                '185520819',
                'Credit_Check_Phase_1_ON_DEMAND',
                'US'
            );
            Test.stopTest();
            System.assert(false, 'Expected CalloutException was not thrown');
        } catch (CalloutException e) {
            System.assert(
                e.getMessage().contains('500'),
                'Exception should contain status code 500'
            );
            System.assert(
                e.getMessage().contains('DNB call failed'),
                'Exception should contain failure message'
            );
        }
    }

    @isTest
    static void testNotFoundResponse_throwsCalloutException() {
        Test.setMock(HttpCalloutMock.class, new FailureMock(404, '{"error":"DUNS not found"}'));

        try {
            Test.startTest();
            DnbService.fetchCompanyData(
                '185520819',
                'Credit_Check_Phase_1_ON_DEMAND',
                'US'
            );
            Test.stopTest();
            System.assert(false, 'Expected CalloutException was not thrown');
        } catch (CalloutException e) {
            System.assert(
                e.getMessage().contains('404'),
                'Exception should contain status code 404'
            );
        }
    }

    // ─────────────────────────────────────────
    // Germany-Specific Parameter Tests
    // ─────────────────────────────────────────

    @isTest
    static void testGermanyCountryCode_endpointContainsDEParams() {
        SuccessMockDE mockDE = new SuccessMockDE();
        Test.setMock(HttpCalloutMock.class, mockDE);

        Test.startTest();
        String result = DnbService.fetchCompanyData(
            '185520819',
            'Credit_Check_Phase_1_ON_DEMAND',
            'DE'
        );
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null for DE callout');
        System.assert(
            mockDE.capturedEndpoint.contains('tradeUp=hq'),
            'DE endpoint should contain tradeUp=hq'
        );
        System.assert(
            mockDE.capturedEndpoint.contains('orderReason=6332'),
            'DE endpoint should contain orderReason=6332'
        );
        System.assert(
            mockDE.capturedEndpoint.contains('customerReference='),
            'DE endpoint should contain customerReference'
        );
        System.assert(
            mockDE.capturedEndpoint.contains('SF-185520819'),
            'customerReference should be SF- prefixed with the DUNS number'
        );
    }

    @isTest
    static void testNonGermanyCountryCode_endpointExcludesDEParams() {
        SuccessMockDE mockNonDE = new SuccessMockDE();
        Test.setMock(HttpCalloutMock.class, mockNonDE);

        Test.startTest();
        DnbService.fetchCompanyData(
            '185520819',
            'Credit_Check_Phase_1_ON_DEMAND',
            'US'
        );
        Test.stopTest();

        System.assert(
            !mockNonDE.capturedEndpoint.contains('tradeUp=hq'),
            'Non-DE endpoint should NOT contain tradeUp=hq'
        );
        System.assert(
            !mockNonDE.capturedEndpoint.contains('orderReason=6332'),
            'Non-DE endpoint should NOT contain orderReason=6332'
        );
        System.assert(
            !mockNonDE.capturedEndpoint.contains('customerReference='),
            'Non-DE endpoint should NOT contain customerReference'
        );
    }

    @isTest
    static void testNullCountryCode_noGermanyParams() {
        SuccessMockDE mockNull = new SuccessMockDE();
        Test.setMock(HttpCalloutMock.class, mockNull);

        Test.startTest();
        DnbService.fetchCompanyData(
            '185520819',
            'Credit_Check_Phase_1_ON_DEMAND',
            null
        );
        Test.stopTest();

        System.assert(
            !mockNull.capturedEndpoint.contains('tradeUp=hq'),
            'Null country code endpoint should NOT contain tradeUp=hq'
        );
        System.assert(
            !mockNull.capturedEndpoint.contains('orderReason=6332'),
            'Null country code endpoint should NOT contain orderReason=6332'
        );
    }
}