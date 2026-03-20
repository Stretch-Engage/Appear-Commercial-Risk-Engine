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
    static void testNullFailureScore_setsInsufficientDataReason() {
        DnbEnrichmentResult result = buildResult(null, 85, '4A');
        Test.startTest();
        DnbCreditEvaluator.evaluate(result);
        Test.stopTest();

        System.assertEquals('Insufficient DNB financial data',
            result.ratingReason,
            'Should flag insufficient data when failureScore is null');
        System.assertEquals('RED_High_Risk',
            result.appearCreditRating,
            'Should default to RED_High_Risk when data is insufficient');
    }

    @isTest
    static void testNullDelinquencyScore_setsInsufficientDataReason() {
        DnbEnrichmentResult result = buildResult(72, null, '4A');
        Test.startTest();
        DnbCreditEvaluator.evaluate(result);
        Test.stopTest();

        System.assertEquals('Insufficient DNB financial data',
            result.ratingReason);
    }

    @isTest
    static void testNullFinancialStrength_setsInsufficientDataReason() {
        DnbEnrichmentResult result = buildResult(72, 85, null);
        Test.startTest();
        DnbCreditEvaluator.evaluate(result);
        Test.stopTest();

        System.assertEquals('Insufficient DNB financial data',
            result.ratingReason);
    }

    @isTest
    static void testBlankFinancialStrength_setsInsufficientDataReason() {
        DnbEnrichmentResult result = buildResult(72, 85, '');
        Test.startTest();
        DnbCreditEvaluator.evaluate(result);
        Test.stopTest();

        System.assertEquals('Insufficient DNB financial data',
            result.ratingReason);
    }

    @isTest
    static void testWhitespaceFinancialStrength_setsInsufficientDataReason() {
        DnbEnrichmentResult result = buildResult(72, 85, '   ');
        Test.startTest();
        DnbCreditEvaluator.evaluate(result);
        Test.stopTest();

        System.assertEquals('Insufficient DNB financial data',
            result.ratingReason);
    }

    @isTest
    static void testAllScoresNull_setsInsufficientDataReason() {
        DnbEnrichmentResult result = buildResult(null, null, null);
        Test.startTest();
        DnbCreditEvaluator.evaluate(result);
        Test.stopTest();

        System.assertEquals('Insufficient DNB financial data',
            result.ratingReason);
        System.assertEquals('RED_High_Risk',
            result.appearCreditRating);
    }

    // ─────────────────────────────────────────
    // Rating Band Tests
    // Formula: (f*0.45) + (d*0.30) + (fsi*0.25)
    // ─────────────────────────────────────────

    @isTest
    static void testGreenVeryLowRisk_finalScore100() {
        // f=100, d=100, fsi=100 (5A)
        // (100*0.45)+(100*0.30)+(100*0.25) = 45+30+25 = 100
        DnbEnrichmentResult result = buildResult(100, 100, '5A');
        Test.startTest();
        DnbCreditEvaluator.evaluate(result);
        Test.stopTest();

        System.assertEquals('GREEN_Very_Low_Risk',
            result.appearCreditRating,
            'finalScore 100 should be GREEN_Very_Low_Risk');
        System.assertEquals('Very low risk based on weighted DNB score and FSI',
            result.ratingReason);
    }

    @isTest
    static void testGreenLowRisk_finalScore76point25() {
        // f=80, d=80, fsi=65 (2A)
        // (80*0.45)+(80*0.30)+(65*0.25) = 36+24+16.25 = 76.25
        DnbEnrichmentResult result = buildResult(80, 80, '2A');
        Test.startTest();
        DnbCreditEvaluator.evaluate(result);
        Test.stopTest();

        System.assertEquals('GREEN_Low_Risk',
            result.appearCreditRating,
            'finalScore 76.25 should be GREEN_Low_Risk');
        System.assertEquals('Low risk based on weighted DNB score and FSI',
            result.ratingReason);
    }

    @isTest
    static void testAmberModerateRisk_finalScore56point25() {
        // f=60, d=60, fsi=45 (B)
        // (60*0.45)+(60*0.30)+(45*0.25) = 27+18+11.25 = 56.25
        DnbEnrichmentResult result = buildResult(60, 60, 'B');
        Test.startTest();
        DnbCreditEvaluator.evaluate(result);
        Test.stopTest();

        System.assertEquals('AMBER_Moderate_Risk',
            result.appearCreditRating,
            'finalScore 56.25 should be AMBER_Moderate_Risk');
        System.assertEquals('Moderate risk based on weighted DNB score and FSI',
            result.ratingReason);
    }

    @isTest
    static void testAmberElevatedRisk_finalScore32point5() {
        // f=35, d=35, fsi=25 (H)
        // (35*0.45)+(35*0.30)+(25*0.25) = 15.75+10.5+6.25 = 32.5
        DnbEnrichmentResult result = buildResult(35, 35, 'H');
        Test.startTest();
        DnbCreditEvaluator.evaluate(result);
        Test.stopTest();

        System.assertEquals('AMBER_Elevated_Risk',
            result.appearCreditRating,
            'finalScore 32.5 should be AMBER_Elevated_Risk');
        System.assertEquals('Elevated risk based on weighted DNB score and FSI',
            result.ratingReason);
    }

    @isTest
    static void testRedHighRisk_finalScore13point75() {
        // f=15, d=15, fsi=10 (HH)
        // (15*0.45)+(15*0.30)+(10*0.25) = 6.75+4.5+2.5 = 13.75
        DnbEnrichmentResult result = buildResult(15, 15, 'HH');
        Test.startTest();
        DnbCreditEvaluator.evaluate(result);
        Test.stopTest();

        System.assertEquals('RED_High_Risk',
            result.appearCreditRating,
            'finalScore 13.75 should be RED_High_Risk');
        System.assertEquals('High risk based on weighted DNB score and FSI',
            result.ratingReason);
    }

    // ─────────────────────────────────────────
    // Boundary Tests
    // ─────────────────────────────────────────

    @isTest
    static void testBoundary_exactlyAt81_greenVeryLowRisk() {
        // f=90, d=90, fsi=55 (1A)
        // (90*0.45)+(90*0.30)+(55*0.25) = 40.5+27+13.75 = 81.25
        DnbEnrichmentResult result = buildResult(90, 90, '1A');
        Test.startTest();
        DnbCreditEvaluator.evaluate(result);
        Test.stopTest();

        System.assertEquals('GREEN_Very_Low_Risk',
            result.appearCreditRating,
            'finalScore 81.25 should be GREEN_Very_Low_Risk');
    }

    @isTest
    static void testBoundary_justBelow81_greenLowRisk() {
        // f=80, d=80, fsi=55 (1A)
        // (80*0.45)+(80*0.30)+(55*0.25) = 36+24+13.75 = 73.75
        DnbEnrichmentResult result = buildResult(80, 80, '1A');
        Test.startTest();
        DnbCreditEvaluator.evaluate(result);
        Test.stopTest();

        System.assertEquals('GREEN_Low_Risk',
            result.appearCreditRating,
            'finalScore 73.75 should be GREEN_Low_Risk');
    }

    @isTest
    static void testBoundary_exactlyAt21_amberElevatedRisk() {
        // f=20, d=20, fsi=25 (H)
        // (20*0.45)+(20*0.30)+(25*0.25) = 9+6+6.25 = 21.25
        DnbEnrichmentResult result = buildResult(20, 20, 'H');
        Test.startTest();
        DnbCreditEvaluator.evaluate(result);
        Test.stopTest();

        System.assertEquals('AMBER_Elevated_Risk',
            result.appearCreditRating,
            'finalScore 21.25 should be AMBER_Elevated_Risk');
    }

    @isTest
    static void testBoundary_justBelow21_redHighRisk() {
        // f=10, d=10, fsi=10 (HH)
        // (10*0.45)+(10*0.30)+(10*0.25) = 4.5+3+2.5 = 10
        DnbEnrichmentResult result = buildResult(10, 10, 'HH');
        Test.startTest();
        DnbCreditEvaluator.evaluate(result);
        Test.stopTest();

        System.assertEquals('RED_High_Risk',
            result.appearCreditRating,
            'finalScore 10 should be RED_High_Risk');
    }
}