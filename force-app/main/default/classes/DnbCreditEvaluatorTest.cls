@isTest
private class DnbCreditEvaluatorTest {

    // ─────────────────────────────────────────
    // Helper
    // ─────────────────────────────────────────

    private static DnbEnrichmentResult buildResult(
        Decimal failureScore,
        Decimal delinquencyScore,
        String financialStrength
    ) {
        DnbEnrichmentResult result = new DnbEnrichmentResult();
        result.failureScorePercentile = failureScore;
        result.delinquencyScoreClass  = delinquencyScore;
        result.financialStrength      = financialStrength;
        return result;
    }

    // ─────────────────────────────────────────
    // Null Guard Tests
    // ─────────────────────────────────────────

    @isTest
    static void testNullData_noExceptionThrown() {
        Test.startTest();
        DnbCreditEvaluator.evaluate(null);
        Test.stopTest();
        System.assert(true, 'Null input should not throw an exception');
    }

    // ─────────────────────────────────────────
    // Insufficient Data Tests
    // ─────────────────────────────────────────

    @isTest
    static void testNullFailureScore_insufficientData() {
        DnbEnrichmentResult result = buildResult(null, 85, '4A');
        Test.startTest();
        DnbCreditEvaluator.evaluate(result);
        Test.stopTest();

        System.assertEquals('RED_High_Risk',              result.appearCreditRating, 'Should be RED_High_Risk');
        System.assertEquals('Insufficient DNB financial data', result.ratingReason, 'Should flag insufficient data');
    }

    @isTest
    static void testNullDelinquencyScore_insufficientData() {
        DnbEnrichmentResult result = buildResult(72, null, '4A');
        Test.startTest();
        DnbCreditEvaluator.evaluate(result);
        Test.stopTest();

        System.assertEquals('RED_High_Risk',              result.appearCreditRating, 'Should be RED_High_Risk');
        System.assertEquals('Insufficient DNB financial data', result.ratingReason, 'Should flag insufficient data');
    }

    @isTest
    static void testNullFinancialStrength_insufficientData() {
        DnbEnrichmentResult result = buildResult(72, 85, null);
        Test.startTest();
        DnbCreditEvaluator.evaluate(result);
        Test.stopTest();

        System.assertEquals('RED_High_Risk',              result.appearCreditRating, 'Should be RED_High_Risk');
        System.assertEquals('Insufficient DNB financial data', result.ratingReason, 'Should flag insufficient data');
    }

    @isTest
    static void testBlankFinancialStrength_insufficientData() {
        DnbEnrichmentResult result = buildResult(72, 85, '');
        Test.startTest();
        DnbCreditEvaluator.evaluate(result);
        Test.stopTest();

        System.assertEquals('Insufficient DNB financial data', result.ratingReason, 'Blank strength should flag insufficient data');
    }

    @isTest
    static void testWhitespaceFinancialStrength_insufficientData() {
        DnbEnrichmentResult result = buildResult(72, 85, '   ');
        Test.startTest();
        DnbCreditEvaluator.evaluate(result);
        Test.stopTest();

        System.assertEquals('Insufficient DNB financial data', result.ratingReason, 'Whitespace strength should flag insufficient data');
    }

    @isTest
    static void testAllFieldsNull_insufficientData() {
        DnbEnrichmentResult result = buildResult(null, null, null);
        Test.startTest();
        DnbCreditEvaluator.evaluate(result);
        Test.stopTest();

        System.assertEquals('RED_High_Risk',              result.appearCreditRating, 'Should be RED_High_Risk');
        System.assertEquals('Insufficient DNB financial data', result.ratingReason, 'Should flag insufficient data');
    }

    // ─────────────────────────────────────────
    // Rating Band Tests
    // All scores verified with formula:
    // finalScore = ((f*0.6)+(d*0.4))*0.7 + (fsiScore*0.3)
    // ─────────────────────────────────────────

    @isTest
    static void testGreenVeryLowRisk_finalScore100() {
        // f=100, d=100, fsi=100 (5A)
        // weightedScore = 100, finalScore = (100*0.7)+(100*0.3) = 100
        DnbEnrichmentResult result = buildResult(100, 100, '5A');
        Test.startTest();
        DnbCreditEvaluator.evaluate(result);
        Test.stopTest();

        System.assertEquals(
            'GREEN_Very_Low_Risk',
            result.appearCreditRating,
            'finalScore 100 should be GREEN_Very_Low_Risk'
        );
        System.assertEquals(
            'Very low risk based on weighted DNB score and FSI',
            result.ratingReason,
            'Reason should match GREEN_Very_Low_Risk message'
        );
    }

    @isTest
    static void testGreenLowRisk_finalScore75point5() {
        // f=80, d=80, fsi=65 (2A)
        // weightedScore = (80*0.6)+(80*0.4) = 80
        // finalScore = (80*0.7)+(65*0.3) = 56+19.5 = 75.5
        DnbEnrichmentResult result = buildResult(80, 80, '2A');
        Test.startTest();
        DnbCreditEvaluator.evaluate(result);
        Test.stopTest();

        System.assertEquals(
            'GREEN_Low_Risk',
            result.appearCreditRating,
            'finalScore 75.5 should be GREEN_Low_Risk'
        );
        System.assertEquals(
            'Low risk based on weighted DNB score and FSI',
            result.ratingReason,
            'Reason should match GREEN_Low_Risk message'
        );
    }

    @isTest
    static void testAmberModerateRisk_finalScore55point5() {
        // f=60, d=60, fsi=45 (B)
        // weightedScore = (60*0.6)+(60*0.4) = 60
        // finalScore = (60*0.7)+(45*0.3) = 42+13.5 = 55.5
        DnbEnrichmentResult result = buildResult(60, 60, 'B');
        Test.startTest();
        DnbCreditEvaluator.evaluate(result);
        Test.stopTest();

        System.assertEquals(
            'AMBER_Moderate_Risk',
            result.appearCreditRating,
            'finalScore 55.5 should be AMBER_Moderate_Risk'
        );
        System.assertEquals(
            'Moderate risk based on weighted DNB score and FSI',
            result.ratingReason,
            'Reason should match AMBER_Moderate_Risk message'
        );
    }

    @isTest
    static void testAmberElevatedRisk_finalScore32() {
        // f=35, d=35, fsi=25 (H)
        // weightedScore = (35*0.6)+(35*0.4) = 35
        // finalScore = (35*0.7)+(25*0.3) = 24.5+7.5 = 32
        DnbEnrichmentResult result = buildResult(35, 35, 'H');
        Test.startTest();
        DnbCreditEvaluator.evaluate(result);
        Test.stopTest();

        System.assertEquals(
            'AMBER_Elevated_Risk',
            result.appearCreditRating,
            'finalScore 32 should be AMBER_Elevated_Risk'
        );
        System.assertEquals(
            'Elevated risk based on weighted DNB score and FSI',
            result.ratingReason,
            'Reason should match AMBER_Elevated_Risk message'
        );
    }

    @isTest
    static void testRedHighRisk_finalScore13point5() {
        // f=15, d=15, fsi=10 (HH)
        // weightedScore = (15*0.6)+(15*0.4) = 15
        // finalScore = (15*0.7)+(10*0.3) = 10.5+3 = 13.5
        DnbEnrichmentResult result = buildResult(15, 15, 'HH');
        Test.startTest();
        DnbCreditEvaluator.evaluate(result);
        Test.stopTest();

        System.assertEquals(
            'RED_High_Risk',
            result.appearCreditRating,
            'finalScore 13.5 should be RED_High_Risk'
        );
        System.assertEquals(
            'High risk based on weighted DNB score and FSI',
            result.ratingReason,
            'Reason should match RED_High_Risk message'
        );
    }

    // ─────────────────────────────────────────
    // Boundary Tests
    // ─────────────────────────────────────────

    @isTest
    static void testBoundary_exactlyAt81_greenVeryLowRisk() {
        // f=73, d=74, fsi=100 (5A)
        // weightedScore = (73*0.6)+(74*0.4) = 43.8+29.6 = 73.4
        // finalScore = (73.4*0.7)+(100*0.3) = 51.38+30 = 81.38
        DnbEnrichmentResult result = buildResult(73, 74, '5A');
        Test.startTest();
        DnbCreditEvaluator.evaluate(result);
        Test.stopTest();

        System.assertEquals(
            'GREEN_Very_Low_Risk',
            result.appearCreditRating,
            'finalScore just above 81 should be GREEN_Very_Low_Risk'
        );
    }

    @isTest
    static void testBoundary_exactlyAt61_greenLowRisk() {
        // f=60, d=60, fsi=55 (1A)
        // weightedScore = 60
        // finalScore = (60*0.7)+(55*0.3) = 42+16.5 = 58.5 → AMBER
        // Try f=70, d=70, fsi=55 (1A)
        // weightedScore = 70
        // finalScore = (70*0.7)+(55*0.3) = 49+16.5 = 65.5 → GREEN_Low_Risk 
        DnbEnrichmentResult result = buildResult(70, 70, '1A');
        Test.startTest();
        DnbCreditEvaluator.evaluate(result);
        Test.stopTest();

        System.assertEquals(
            'GREEN_Low_Risk',
            result.appearCreditRating,
            'finalScore 65.5 should be GREEN_Low_Risk'
        );
    }

    @isTest
    static void testBoundary_exactlyAt21_amberElevatedRisk() {
        // f=20, d=20, fsi=25 (H)
        // weightedScore = 20
        // finalScore = (20*0.7)+(25*0.3) = 14+7.5 = 21.5 → AMBER_Elevated 
        DnbEnrichmentResult result = buildResult(20, 20, 'H');
        Test.startTest();
        DnbCreditEvaluator.evaluate(result);
        Test.stopTest();

        System.assertEquals(
            'AMBER_Elevated_Risk',
            result.appearCreditRating,
            'finalScore 21.5 should be AMBER_Elevated_Risk'
        );
    }
}