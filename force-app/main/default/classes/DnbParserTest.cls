@isTest
private class DnbParserTest {

    // ─────────────────────────────────────────
    // Test Data Builders
    // ─────────────────────────────────────────

    private static String buildFullPayload() {
        return '{' +
            '"transactionDetail": {' +
                '"transactionID": "TXN-185520819-001"' +
            '},' +
            '"organization": {' +
                '"duns": "185520819",' +
                '"primaryName": "Acme Corporation",' +
                '"countryISOAlpha2Code": "US",' +
                '"dnbAssessment": {' +
                    '"failureScore": {' +
                        '"nationalPercentile": 72' +
                    '},' +
                    '"delinquencyScore": {' +
                        '"nationalPercentile": 85' +
                    '},' +
                    '"standardRating": {' +
                        '"financialStrength": "4A",' +
                        '"rating": "2"' +
                    '},' +
                    '"creditLimitRecommendation": {' +
                        '"maximumRecommendedLimit": {' +
                            '"value": 150000' +
                        '}' +
                    '}' +
                '}' +
            '}' +
        '}';
    }

    private static String buildPayloadWithoutAssessment() {
        return '{' +
            '"transactionDetail": {' +
                '"transactionID": "TXN-185520819-002"' +
            '},' +
            '"organization": {' +
                '"duns": "185520819",' +
                '"primaryName": "Acme Corporation",' +
                '"countryISOAlpha2Code": "US"' +
            '}' +
        '}';
    }

    private static String buildPayloadWithoutOrganization() {
        return '{' +
            '"transactionDetail": {' +
                '"transactionID": "TXN-185520819-003"' +
            '}' +
        '}';
    }

    private static String buildPayloadWithNullScores() {
        return '{' +
            '"transactionDetail": {' +
                '"transactionID": "TXN-185520819-004"' +
            '},' +
            '"organization": {' +
                '"duns": "185520819",' +
                '"primaryName": "Acme Corporation",' +
                '"countryISOAlpha2Code": "US",' +
                '"dnbAssessment": {' +
                '}' +
            '}' +
        '}';
    }

    private static String buildPayloadWithoutCreditLimit() {
        return '{' +
            '"transactionDetail": {' +
                '"transactionID": "TXN-185520819-005"' +
            '},' +
            '"organization": {' +
                '"duns": "185520819",' +
                '"primaryName": "Acme Corporation",' +
                '"countryISOAlpha2Code": "DE",' +
                '"dnbAssessment": {' +
                    '"failureScore": {' +
                        '"nationalPercentile": 60' +
                    '},' +
                    '"standardRating": {' +
                        '"financialStrength": "2A",' +
                        '"rating": "3"' +
                    '}' +
                '}' +
            '}' +
        '}';
    }

    // ─────────────────────────────────────────
    // Happy Path — Full Payload
    // ─────────────────────────────────────────

    @isTest
    static void testFullPayload_allFieldsMappedCorrectly() {
        Test.startTest();
        DnbEnrichmentResult result = DnbParser.parse(buildFullPayload());
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals('185520819', result.duns, 'DUNS mismatch');
        System.assertEquals('Acme Corporation', result.companyName, 'Company name mismatch');
        System.assertEquals(72, result.failureScorePercentile, 'Failure score percentile mismatch');
        System.assertEquals(85, result.delinquencyScoreClass, 'Delinquency score class mismatch');
        System.assertEquals('4A', result.financialStrength, 'Financial strength mismatch');
        System.assertEquals(150000, result.creditLimit, 'Credit limit mismatch');
        System.assertEquals('2', result.compositeScore, 'Composite score mismatch');
        System.assertEquals('TXN-185520819-001', result.transactionId, 'Transaction ID mismatch');
    }

    @isTest
    static void testFullPayload_defaultFlagsAreFalse() {
        Test.startTest();
        DnbEnrichmentResult result = DnbParser.parse(buildFullPayload());
        Test.stopTest();

        System.assertEquals(false, result.hasOpenLiens, 'hasOpenLiens should default to false');
        System.assertEquals(false, result.hasOpenJudgments, 'hasOpenJudgments should default to false');
        System.assertEquals(false, result.hasOpenBankruptcy, 'hasOpenBankruptcy should default to false');
    }

    // ─────────────────────────────────────────
    // Field Mapping Tests
    // ─────────────────────────────────────────

    @isTest
    static void testPostalCode_mappedFromCountryISOCode() {
        // NOTE: postalCode field is currently mapped from countryISOAlpha2Code
        // This may be an intentional field reuse or a mapping bug worth reviewing
        Test.startTest();
        DnbEnrichmentResult result = DnbParser.parse(buildFullPayload());
        Test.stopTest();

        System.assertEquals(
            'US',
            result.postalCode,
            'postalCode is currently mapped from countryISOAlpha2Code — verify this is intentional'
        );
    }

    @isTest
    static void testCompositeScore_mappedFromStandardRatingRating() {
        // compositeScore reuses the standardRating block (same as financialStrength)
        Test.startTest();
        DnbEnrichmentResult result = DnbParser.parse(buildFullPayload());
        Test.stopTest();

        System.assertEquals(
            '2',
            result.compositeScore,
            'compositeScore should be mapped from standardRating.rating'
        );
        System.assertEquals(
            '4A',
            result.financialStrength,
            'financialStrength should be mapped from standardRating.financialStrength'
        );
    }

    // ─────────────────────────────────────────
    // Null / Missing Organization Tests
    // ─────────────────────────────────────────

    @isTest
    static void testMissingOrganization_returnsEmptyResult() {
        Test.startTest();
        DnbEnrichmentResult result = DnbParser.parse(buildPayloadWithoutOrganization());
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result object should never be null');
        System.assertEquals(null, result.duns, 'DUNS should be null when organization missing');
        System.assertEquals(null, result.companyName, 'Company name should be null when organization missing');
        System.assertEquals(null, result.transactionId, 'Transaction ID should be null when organization missing');
        System.assertEquals(null, result.creditLimit, 'Credit limit should be null when organization missing');
    }

    // ─────────────────────────────────────────
    // Missing Assessment Block Tests
    // ─────────────────────────────────────────

    @isTest
    static void testMissingAssessment_basicFieldsStillMapped() {
        Test.startTest();
        DnbEnrichmentResult result = DnbParser.parse(buildPayloadWithoutAssessment());
        Test.stopTest();

        System.assertEquals('185520819', result.duns, 'DUNS should still be mapped without assessment');
        System.assertEquals('Acme Corporation', result.companyName, 'Company name should still be mapped');
    }

    @isTest
    static void testMissingAssessment_scoreFieldsAreNull() {
        Test.startTest();
        DnbEnrichmentResult result = DnbParser.parse(buildPayloadWithoutAssessment());
        Test.stopTest();

        System.assertEquals(null, result.failureScorePercentile, 'Failure score should be null without assessment');
        System.assertEquals(null, result.delinquencyScoreClass, 'Delinquency score should be null without assessment');
        System.assertEquals(null, result.financialStrength, 'Financial strength should be null without assessment');
        System.assertEquals(null, result.creditLimit, 'Credit limit should be null without assessment');
        System.assertEquals(null, result.compositeScore, 'Composite score should be null without assessment');
    }

    @isTest
    static void testMissingAssessment_transactionIdNotSet() {
        // ⚠️ Known behaviour: transactionDetail parsing sits inside the
        // if (assessment != null) block, so transactionId will be null
        // even when transactionDetail exists at root level.
        // Consider moving transactionDetail parsing outside that block.
        Test.startTest();
        DnbEnrichmentResult result = DnbParser.parse(buildPayloadWithoutAssessment());
        Test.stopTest();

        System.assertEquals(
            null,
            result.transactionId,
            'transactionId will be null when assessment block is missing — this may be unintentional'
        );
    }

    // ─────────────────────────────────────────
    // Missing Nested Blocks Tests
    // ─────────────────────────────────────────

    @isTest
    static void testEmptyAssessmentBlock_noNullPointerExceptions() {
        Test.startTest();
        DnbEnrichmentResult result = DnbParser.parse(buildPayloadWithNullScores());
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null with empty assessment');
        System.assertEquals(null, result.failureScorePercentile, 'Failure score should be null');
        System.assertEquals(null, result.delinquencyScoreClass, 'Delinquency score should be null');
        System.assertEquals(null, result.financialStrength, 'Financial strength should be null');
        System.assertEquals(null, result.creditLimit, 'Credit limit should be null');
        System.assertEquals(null, result.compositeScore, 'Composite score should be null');
    }

    @isTest
    static void testMissingCreditLimit_creditLimitIsNull() {
        Test.startTest();
        DnbEnrichmentResult result = DnbParser.parse(buildPayloadWithoutCreditLimit());
        Test.stopTest();

        System.assertEquals(null, result.creditLimit, 'Credit limit should be null when not in payload');
        System.assertEquals('60', String.valueOf(result.failureScorePercentile.intValue()), 'Failure score should still parse');
        System.assertEquals('2A', result.financialStrength, 'Financial strength should still parse');
        System.assertEquals('3', result.compositeScore, 'Composite score should still parse');
    }

    // ─────────────────────────────────────────
    // Edge Case — Minimal Valid Payload
    // ─────────────────────────────────────────

    @isTest
    static void testMinimalPayload_organizationOnlyWithDuns() {
        String minimalJson = '{"organization":{"duns":"185520819"}}';

        Test.startTest();
        DnbEnrichmentResult result = DnbParser.parse(minimalJson);
        Test.stopTest();

        System.assertEquals('185520819', result.duns, 'DUNS should parse from minimal payload');
        System.assertEquals(null, result.companyName, 'Company name should be null');
        System.assertEquals(null, result.failureScorePercentile, 'Failure score should be null');
        System.assertEquals(null, result.creditLimit, 'Credit limit should be null');
    }

    @isTest
    static void testEmptyOrganizationBlock_noExceptions() {
        String emptyOrgJson = '{"organization":{}}';

        Test.startTest();
        DnbEnrichmentResult result = DnbParser.parse(emptyOrgJson);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(null, result.duns, 'DUNS should be null');
        System.assertEquals(null, result.companyName, 'Company name should be null');
    }
}