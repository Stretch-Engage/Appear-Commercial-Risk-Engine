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
                '"legalEvents": {' +
                    '"hasOpenLiens": false,' +
                    '"hasOpenJudgments": false,' +
                    '"hasOpenBankruptcy": false' +
                '},' +
                '"dnbAssessment": {' +
                    '"failureScore": {' +
                        '"nationalPercentile": 72,' +
                        '"classScoreDescription": "Low to moderate risk of financial stress"' +
                    '},' +
                    '"delinquencyScore": {' +
                        '"nationalPercentile": 85,' +
                        '"classScoreDescription": "Low risk of severe payment delinquency"' +
                    '},' +
                    '"standardRating": {' +
                        '"financialStrength": "4A",' +
                        '"rating": "2",' +
                        '"ratingReason": [' +
                            '{"description": "Strong financial profile"},' +
                            '{"description": "Active trading record"}' +
                        ']' +
                    '},' +
                    '"creditLimitRecommendation": {' +
                        '"maximumRecommendedLimit": {' +
                            '"value": 150000,' +
                            '"currency": "USD"' +
                        '}' +
                    '}' +
                '}' +
            '}' +
        '}';
    }

    private static String buildNordicPayload() {
        return '{' +
            '"transactionDetail": {' +
                '"transactionID": "TXN-345146201-001"' +
            '},' +
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
                        '"maximumRecommendedLimit": {' +
                            '"value": 202700000,' +
                            '"currency": "NOK"' +
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

    private static String buildPayloadWithLegalEvents() {
        return '{' +
            '"transactionDetail": {"transactionID": "TXN-LEGAL-001"},' +
            '"organization": {' +
                '"duns": "185520819",' +
                '"primaryName": "Acme Corporation",' +
                '"countryISOAlpha2Code": "US",' +
                '"legalEvents": {' +
                    '"hasOpenLiens": true,' +
                    '"hasOpenJudgments": true,' +
                    '"hasOpenBankruptcy": true' +
                '},' +
                '"dnbAssessment": {}' +
            '}' +
        '}';
    }

    // ─────────────────────────────────────────
    // Happy Path — Full Payload (Global)
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
        System.assertEquals('Low to moderate risk of financial stress', result.failureScoreDescription, 'Failure score description mismatch');
        System.assertEquals('Low risk of severe payment delinquency', result.delinquencyScoreDescription, 'Delinquency score description mismatch');
        System.assertEquals('Strong financial profile; Active trading record', result.dnbRatingDescription, 'D&B rating description mismatch');
        System.assertEquals('USD', result.creditLimitCurrency, 'Credit limit currency mismatch');
    }

    @isTest
    static void testFullPayload_defaultFlagsAreFalse() {
        Test.startTest();
        DnbEnrichmentResult result = DnbParser.parse(buildFullPayload());
        Test.stopTest();

        System.assertEquals(false, result.hasOpenLiens, 'hasOpenLiens should be false');
        System.assertEquals(false, result.hasOpenJudgments, 'hasOpenJudgments should be false');
        System.assertEquals(false, result.hasOpenBankruptcy, 'hasOpenBankruptcy should be false');
    }

    // ─────────────────────────────────────────
    // Nordic Payload Tests
    // ─────────────────────────────────────────

    @isTest
    static void testNordicPayload_financialStrengthFallsBackToNordicAAA() {
        Test.startTest();
        DnbEnrichmentResult result = DnbParser.parse(buildNordicPayload());
        Test.stopTest();

        System.assertEquals('A', result.financialStrength,
            'Nordic: financialStrength should fall back to nordicAAARating.financialStrength.description');
    }

    @isTest
    static void testNordicPayload_compositeScoreFallsBackToNordicAAA() {
        Test.startTest();
        DnbEnrichmentResult result = DnbParser.parse(buildNordicPayload());
        Test.stopTest();

        System.assertEquals('A2', result.compositeScore,
            'Nordic: compositeScore should fall back to nordicAAARating.rating');
    }

    @isTest
    static void testNordicPayload_ratingDescriptionFallsBackToRiskSegment() {
        Test.startTest();
        DnbEnrichmentResult result = DnbParser.parse(buildNordicPayload());
        Test.stopTest();

        System.assertEquals('2', result.dnbRatingDescription,
            'Nordic: dnbRatingDescription should fall back to nordicAAARating.riskSegment.description');
    }

    @isTest
    static void testNordicPayload_failureScoreDescriptionFallsBackToScoreModel() {
        Test.startTest();
        DnbEnrichmentResult result = DnbParser.parse(buildNordicPayload());
        Test.stopTest();

        System.assertEquals('NO36021', result.failureScoreDescription,
            'Nordic: failureScoreDescription should fall back to scoreModel.description when classScoreDescription is null');
    }

    @isTest
    static void testNordicPayload_emptyDelinquencyDefaultsToZero() {
        Test.startTest();
        DnbEnrichmentResult result = DnbParser.parse(buildNordicPayload());
        Test.stopTest();

        System.assertEquals(0, result.delinquencyScoreClass,
            'Nordic: delinquencyScoreClass should default to 0 when delinquencyScore block is empty');
        System.assertEquals('Delinquency score not available for this country',
            result.delinquencyScoreDescription,
            'Nordic: delinquencyScoreDescription should reflect unavailability');
    }

    @isTest
    static void testNordicPayload_failureScorePercentileMapped() {
        Test.startTest();
        DnbEnrichmentResult result = DnbParser.parse(buildNordicPayload());
        Test.stopTest();

        System.assertEquals(70, result.failureScorePercentile,
            'Nordic: failureScorePercentile should map correctly');
    }

    @isTest
    static void testNordicPayload_creditLimitInNOK() {
        Test.startTest();
        DnbEnrichmentResult result = DnbParser.parse(buildNordicPayload());
        Test.stopTest();

        System.assertEquals(202700000, result.creditLimit,
            'Nordic: credit limit should map correctly');
        System.assertEquals('NOK', result.creditLimitCurrency,
            'Nordic: credit limit currency should be NOK');
    }

    @isTest
    static void testNordicPayload_legalEventsMappedCorrectly() {
        Test.startTest();
        DnbEnrichmentResult result = DnbParser.parse(buildNordicPayload());
        Test.stopTest();

        System.assertEquals(false, result.hasOpenLiens,
            'Nordic: hasOpenLiens should be false');
        System.assertEquals(true, result.hasOpenJudgments,
            'Nordic: hasOpenJudgments should be true');
        System.assertEquals(false, result.hasOpenBankruptcy,
            'Nordic: hasOpenBankruptcy should be false');
    }

    @isTest
    static void testNordicPayload_transactionIdMapped() {
        Test.startTest();
        DnbEnrichmentResult result = DnbParser.parse(buildNordicPayload());
        Test.stopTest();

        System.assertEquals('TXN-345146201-001', result.transactionId,
            'Nordic: transactionId should be mapped correctly');
    }

    // ─────────────────────────────────────────
    // Legal Events Tests
    // ─────────────────────────────────────────

    @isTest
    static void testLegalEvents_allTrueMappedCorrectly() {
        Test.startTest();
        DnbEnrichmentResult result = DnbParser.parse(buildPayloadWithLegalEvents());
        Test.stopTest();

        System.assertEquals(true, result.hasOpenLiens,
            'hasOpenLiens should be true from legalEvents');
        System.assertEquals(true, result.hasOpenJudgments,
            'hasOpenJudgments should be true from legalEvents');
        System.assertEquals(true, result.hasOpenBankruptcy,
            'hasOpenBankruptcy should be true from legalEvents');
    }

    @isTest
    static void testLegalEvents_missingBlock_defaultsToFalse() {
        // Payload has no legalEvents block — defaults from constructor should hold
        Test.startTest();
        DnbEnrichmentResult result = DnbParser.parse(buildPayloadWithNullScores());
        Test.stopTest();

        System.assertEquals(false, result.hasOpenLiens,
            'hasOpenLiens should default false when legalEvents missing');
        System.assertEquals(false, result.hasOpenJudgments,
            'hasOpenJudgments should default false when legalEvents missing');
        System.assertEquals(false, result.hasOpenBankruptcy,
            'hasOpenBankruptcy should default false when legalEvents missing');
    }

    // ─────────────────────────────────────────
    // Field Mapping Tests
    // ─────────────────────────────────────────

    @isTest
    static void testPostalCode_mappedFromCountryISOCode() {
        Test.startTest();
        DnbEnrichmentResult result = DnbParser.parse(buildFullPayload());
        Test.stopTest();

        System.assertEquals('US', result.postalCode,
            'postalCode is currently mapped from countryISOAlpha2Code — verify this is intentional');
    }

    @isTest
    static void testCompositeScore_mappedFromStandardRatingRating() {
        Test.startTest();
        DnbEnrichmentResult result = DnbParser.parse(buildFullPayload());
        Test.stopTest();

        System.assertEquals('2', result.compositeScore,
            'compositeScore should be mapped from standardRating.rating');
        System.assertEquals('4A', result.financialStrength,
            'financialStrength should be mapped from standardRating.financialStrength');
    }

    // ─────────────────────────────────────────
    // Missing Organization Tests
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
    static void testMissingAssessment_transactionIdStillMapped() {
        // Transaction ID is now parsed outside the assessment block
        // so it should be populated even when assessment is missing
        Test.startTest();
        DnbEnrichmentResult result = DnbParser.parse(buildPayloadWithoutAssessment());
        Test.stopTest();

        System.assertEquals('TXN-185520819-002', result.transactionId,
            'transactionId should be mapped even when assessment block is missing');
    }

    // ─────────────────────────────────────────
    // Empty Assessment Block Tests
    // ─────────────────────────────────────────

    @isTest
    static void testEmptyAssessmentBlock_noNullPointerExceptions() {
        Test.startTest();
        DnbEnrichmentResult result = DnbParser.parse(buildPayloadWithNullScores());
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null with empty assessment');
        System.assertEquals(null, result.failureScorePercentile, 'Failure score should be null');
        System.assertEquals(null, result.financialStrength, 'Financial strength should be null');
        System.assertEquals(null, result.creditLimit, 'Credit limit should be null');
        System.assertEquals(null, result.compositeScore, 'Composite score should be null');
    }

    @isTest
    static void testEmptyAssessmentBlock_delinquencyDefaultsToZero() {
        // Empty assessment block has no delinquencyScore key at all
        // Parser defaults to 0 when block is missing or empty
        Test.startTest();
        DnbEnrichmentResult result = DnbParser.parse(buildPayloadWithNullScores());
        Test.stopTest();

        System.assertEquals(0, result.delinquencyScoreClass,
            'delinquencyScoreClass should default to 0 when block is missing');
        System.assertEquals('Delinquency score not available for this country',
            result.delinquencyScoreDescription,
            'delinquencyScoreDescription should reflect unavailability');
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

    // ─────────────────────────────────────────
    // Description Field Tests
    // ─────────────────────────────────────────

    @isTest
    static void testEmptyRatingReason_dnbRatingDescriptionIsNull() {
        String json =
            '{"organization":{"duns":"185520819","dnbAssessment":{' +
                '"standardRating":{"financialStrength":"4A","rating":"2","ratingReason":[]}' +
            '}}}';

        Test.startTest();
        DnbEnrichmentResult result = DnbParser.parse(json);
        Test.stopTest();

        System.assertEquals(null, result.dnbRatingDescription,
            'dnbRatingDescription should be null when ratingReason array is empty and no nordicAAARating');
    }

    @isTest
    static void testNullClassScoreDescription_fallsBackToScoreModel() {
        String json =
            '{"organization":{"duns":"185520819","dnbAssessment":{' +
                '"failureScore":{' +
                    '"nationalPercentile":50,' +
                    '"classScoreDescription":null,' +
                    '"scoreModel":{"description":"MODEL-001"}' +
                '},' +
                '"delinquencyScore":{"nationalPercentile":60,"classScoreDescription":null}' +
            '}}}';

        Test.startTest();
        DnbEnrichmentResult result = DnbParser.parse(json);
        Test.stopTest();

        System.assertEquals('MODEL-001', result.failureScoreDescription,
            'failureScoreDescription should fall back to scoreModel.description when classScoreDescription is null');
        System.assertEquals(null, result.delinquencyScoreDescription,
            'delinquencyScoreDescription should be null when classScoreDescription is null');
    }

    @isTest
    static void testSingleRatingReason_noTrailingSemicolon() {
        String json =
            '{"organization":{"duns":"185520819","dnbAssessment":{' +
                '"standardRating":{"financialStrength":"4A","rating":"2",' +
                    '"ratingReason":[{"description":"Strong financial profile"}]}' +
            '}}}';

        Test.startTest();
        DnbEnrichmentResult result = DnbParser.parse(json);
        Test.stopTest();

        System.assertEquals('Strong financial profile', result.dnbRatingDescription,
            'Single ratingReason should not have trailing semicolon');
    }

    // ─────────────────────────────────────────
    // Nordic Fallback Edge Cases
    // ─────────────────────────────────────────

    @isTest
    static void testNordicFallback_noNordicRating_financialStrengthRemainsNull() {
        // standardRating has 'N' but no nordicAAARating present
        String json =
            '{"organization":{"duns":"185520819","dnbAssessment":{' +
                '"standardRating":{"financialStrength":"N","rating":"N2","ratingReason":[]}' +
            '}}}';

        Test.startTest();
        DnbEnrichmentResult result = DnbParser.parse(json);
        Test.stopTest();

        System.assertEquals(null, result.financialStrength,
            'financialStrength should be null when standardRating is N and no nordicAAARating exists');
    }

    @isTest
    static void testNordicFallback_compositeScorePrefersStandardRating() {
        // standardRating has a valid rating — should prefer it over nordicAAARating
        String json =
            '{"organization":{"duns":"185520819","dnbAssessment":{' +
                '"standardRating":{"financialStrength":"4A","rating":"2","ratingReason":[]},' +
                '"nordicAAARating":{"rating":"A1","financialStrength":{"description":"A"}}' +
            '}}}';

        Test.startTest();
        DnbEnrichmentResult result = DnbParser.parse(json);
        Test.stopTest();

        System.assertEquals('2', result.compositeScore,
            'compositeScore should prefer standardRating.rating over nordicAAARating.rating');
        System.assertEquals('4A', result.financialStrength,
            'financialStrength should prefer standardRating when not N');
    }
}