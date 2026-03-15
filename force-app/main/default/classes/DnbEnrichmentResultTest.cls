@isTest
private class DnbEnrichmentResultTest {

    // ─────────────────────────────────────────
    // Instantiation Tests
    // ─────────────────────────────────────────

    @isTest
    static void testInstantiation_objectCreatesSuccessfully() {
        Test.startTest();
        DnbEnrichmentResult result = new DnbEnrichmentResult();
        Test.stopTest();

        System.assertNotEquals(null, result, 'DnbEnrichmentResult instance should not be null');
    }

    @isTest
    static void testDefaultValues_allFieldsNullOnInstantiation() {
        DnbEnrichmentResult result = new DnbEnrichmentResult();

        // Identity fields
        System.assertEquals(null, result.duns,                   'duns should default to null');
        System.assertEquals(null, result.companyName,            'companyName should default to null');
        System.assertEquals(null, result.postalCode,             'postalCode should default to null');

        // Credit fields
        System.assertEquals(null, result.financialStrength,      'financialStrength should default to null');
        System.assertEquals(null, result.failureScorePercentile, 'failureScorePercentile should default to null');
        System.assertEquals(null, result.delinquencyScoreClass,  'delinquencyScoreClass should default to null');
        System.assertEquals(null, result.creditLimit,            'creditLimit should default to null');
        System.assertEquals(null, result.compositeScore,         'compositeScore should default to null');

        // Legal fields
        System.assertEquals(false, result.hasOpenLiens,           'hasOpenLiens should default to false');
        System.assertEquals(false, result.hasOpenJudgments,       'hasOpenJudgments should default to false');
        System.assertEquals(false, result.hasOpenBankruptcy,      'hasOpenBankruptcy should default to false');

        // Result fields
        System.assertEquals(null, result.appearCreditRating,     'appearCreditRating should default to null');
        System.assertEquals(null, result.ratingReason,           'ratingReason should default to null');

        // Transaction fields
        System.assertEquals(null, result.transactionId,          'transactionId should default to null');
    }

    // ─────────────────────────────────────────
    // Field Assignment Tests
    // ─────────────────────────────────────────

    @isTest
    static void testIdentityFields_assignAndRetrieveCorrectly() {
        DnbEnrichmentResult result = new DnbEnrichmentResult();
        result.duns        = '185520819';
        result.companyName = 'Acme Corporation';
        result.postalCode  = '10001';

        System.assertEquals('185520819',       result.duns,        'DUNS should match assigned value');
        System.assertEquals('Acme Corporation', result.companyName, 'Company name should match assigned value');
        System.assertEquals('10001',            result.postalCode,  'Postal code should match assigned value');
    }

    @isTest
    static void testCreditFields_assignAndRetrieveCorrectly() {
        DnbEnrichmentResult result = new DnbEnrichmentResult();
        result.financialStrength      = '4A';
        result.failureScorePercentile = 72;
        result.delinquencyScoreClass  = 85;
        result.creditLimit            = 150000;
        result.compositeScore         = '2';

        System.assertEquals('4A',   result.financialStrength,      'Financial strength should match');
        System.assertEquals(72,     result.failureScorePercentile, 'Failure score percentile should match');
        System.assertEquals(85,     result.delinquencyScoreClass,  'Delinquency score class should match');
        System.assertEquals(150000, result.creditLimit,            'Credit limit should match');
        System.assertEquals('2',    result.compositeScore,         'Composite score should match');
    }

    @isTest
    static void testLegalFields_assignAndRetrieveCorrectly() {
        DnbEnrichmentResult result = new DnbEnrichmentResult();
        result.hasOpenLiens      = true;
        result.hasOpenJudgments  = true;
        result.hasOpenBankruptcy = false;

        System.assertEquals(true,  result.hasOpenLiens,      'hasOpenLiens should match');
        System.assertEquals(true,  result.hasOpenJudgments,  'hasOpenJudgments should match');
        System.assertEquals(false, result.hasOpenBankruptcy, 'hasOpenBankruptcy should match');
    }

    @isTest
    static void testResultFields_assignAndRetrieveCorrectly() {
        DnbEnrichmentResult result = new DnbEnrichmentResult();
        result.appearCreditRating = 'GREEN';
        result.ratingReason       = 'Strong financial profile with no adverse findings';

        System.assertEquals('GREEN', result.appearCreditRating, 'Credit rating should match');
        System.assertNotEquals(null,  result.ratingReason,       'Rating reason should not be null');
    }

    @isTest
    static void testTransactionField_assignAndRetrieveCorrectly() {
        DnbEnrichmentResult result = new DnbEnrichmentResult();
        result.transactionId = 'TXN-185520819-001';

        System.assertEquals('TXN-185520819-001', result.transactionId, 'Transaction ID should match');
    }

    // ─────────────────────────────────────────
    // Credit Rating Enum Value Tests
    // ─────────────────────────────────────────

    @isTest
    static void testAppearCreditRating_greenValue() {
        DnbEnrichmentResult result = new DnbEnrichmentResult();
        result.appearCreditRating = 'GREEN';
        System.assertEquals('GREEN', result.appearCreditRating, 'GREEN rating should be valid');
    }

    @isTest
    static void testAppearCreditRating_amberValue() {
        DnbEnrichmentResult result = new DnbEnrichmentResult();
        result.appearCreditRating = 'AMBER';
        System.assertEquals('AMBER', result.appearCreditRating, 'AMBER rating should be valid');
    }

    @isTest
    static void testAppearCreditRating_redValue() {
        DnbEnrichmentResult result = new DnbEnrichmentResult();
        result.appearCreditRating = 'RED';
        System.assertEquals('RED', result.appearCreditRating, 'RED rating should be valid');
    }

    // ─────────────────────────────────────────
    // Reassignment Tests
    // ─────────────────────────────────────────

    @isTest
    static void testFieldReassignment_overwritesCorrectly() {
        DnbEnrichmentResult result = new DnbEnrichmentResult();
        result.appearCreditRating = 'GREEN';
        result.creditLimit        = 100000;

        result.appearCreditRating = 'RED';
        result.creditLimit        = 50000;

        System.assertEquals('RED', result.appearCreditRating, 'Rating should reflect reassigned value');
        System.assertEquals(50000, result.creditLimit,        'Credit limit should reflect reassigned value');
    }

    // ─────────────────────────────────────────
    // Multiple Instance Tests
    // ─────────────────────────────────────────

    @isTest
    static void testMultipleInstances_doNotShareState() {
        DnbEnrichmentResult result1 = new DnbEnrichmentResult();
        DnbEnrichmentResult result2 = new DnbEnrichmentResult();

        result1.duns              = '185520819';
        result1.appearCreditRating = 'GREEN';

        result2.duns              = '999999999';
        result2.appearCreditRating = 'RED';

        System.assertNotEquals(result1.duns, result2.duns,
            'Two instances should not share duns state');
        System.assertNotEquals(result1.appearCreditRating, result2.appearCreditRating,
            'Two instances should not share credit rating state');
    }

    // ─────────────────────────────────────────
    // Decimal Precision Tests
    // ─────────────────────────────────────────

    @isTest
    static void testDecimalFields_handlePrecisionCorrectly() {
        DnbEnrichmentResult result = new DnbEnrichmentResult();
        result.failureScorePercentile = 72.5;
        result.delinquencyScoreClass  = 85.75;
        result.creditLimit            = 150000.99;

        System.assertEquals(72.5,      result.failureScorePercentile, 'Decimal precision should be retained');
        System.assertEquals(85.75,     result.delinquencyScoreClass,  'Decimal precision should be retained');
        System.assertEquals(150000.99, result.creditLimit,            'Decimal precision should be retained');
    }
}