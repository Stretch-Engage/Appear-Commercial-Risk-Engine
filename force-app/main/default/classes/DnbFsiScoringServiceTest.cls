@isTest
private class DnbFsiScoringServiceTest {

    // ─────────────────────────────────────────
    // Known Rating Tests
    // ─────────────────────────────────────────

    @isTest
    static void test5A_returns100() {
        Test.startTest();
        Decimal score = DnbFsiScoringService.getScore('5A');
        Test.stopTest();
        System.assertEquals(100, score, '5A should return 100');
    }

    @isTest
    static void test4A_returns90() {
        Test.startTest();
        Decimal score = DnbFsiScoringService.getScore('4A');
        Test.stopTest();
        System.assertEquals(90, score, '4A should return 90');
    }

    @isTest
    static void test3A_returns80() {
        Test.startTest();
        Decimal score = DnbFsiScoringService.getScore('3A');
        Test.stopTest();
        System.assertEquals(80, score, '3A should return 80');
    }

    @isTest
    static void test2A_returns65() {
        Test.startTest();
        Decimal score = DnbFsiScoringService.getScore('2A');
        Test.stopTest();
        System.assertEquals(65, score, '2A should return 65');
    }

    @isTest
    static void test1A_returns55() {
        Test.startTest();
        Decimal score = DnbFsiScoringService.getScore('1A');
        Test.stopTest();
        System.assertEquals(55, score, '1A should return 55');
    }

    @isTest
    static void testB_returns45() {
        Test.startTest();
        Decimal score = DnbFsiScoringService.getScore('B');
        Test.stopTest();
        System.assertEquals(45, score, 'B should return 45');
    }

    @isTest
    static void testH_returns25() {
        Test.startTest();
        Decimal score = DnbFsiScoringService.getScore('H');
        Test.stopTest();
        System.assertEquals(25, score, 'H should return 25');
    }

    @isTest
    static void testHH_returns10() {
        Test.startTest();
        Decimal score = DnbFsiScoringService.getScore('HH');
        Test.stopTest();
        System.assertEquals(10, score, 'HH should return 10');
    }

    // ─────────────────────────────────────────
    // Fallback / Unknown Rating Tests
    // ─────────────────────────────────────────

    @isTest
    static void testUnknownRating_returns0() {
        Test.startTest();
        Decimal score = DnbFsiScoringService.getScore('ZZZ');
        Test.stopTest();
        System.assertEquals(0, score, 'Unknown rating should return 0');
    }

    @isTest
    static void testBlankString_returns0() {
        Test.startTest();
        Decimal score = DnbFsiScoringService.getScore('');
        Test.stopTest();
        System.assertEquals(0, score, 'Blank string should return 0');
    }

    @isTest
    static void testNullString_returns0() {
        Test.startTest();
        Decimal score = DnbFsiScoringService.getScore(null);
        Test.stopTest();
        System.assertEquals(0, score, 'Null should return 0');
    }

    @isTest
    static void testWhitespaceString_returns0() {
        Test.startTest();
        Decimal score = DnbFsiScoringService.getScore('   ');
        Test.stopTest();
        System.assertEquals(0, score, 'Whitespace should return 0');
    }

    // ─────────────────────────────────────────
    // Case Insensitivity Tests
    // ─────────────────────────────────────────

    @isTest
    static void testLowercase5a_returns100() {
        Test.startTest();
        Decimal score = DnbFsiScoringService.getScore('5a');
        Test.stopTest();
        System.assertEquals(100, score, 'Lowercase 5a should match 5A and return 100');
    }

    @isTest
    static void testLowercase4a_returns90() {
        Test.startTest();
        Decimal score = DnbFsiScoringService.getScore('4a');
        Test.stopTest();
        System.assertEquals(90, score, 'Lowercase 4a should match 4A and return 90');
    }

    @isTest
    static void testLowercaseB_returns45() {
        Test.startTest();
        Decimal score = DnbFsiScoringService.getScore('b');
        Test.stopTest();
        System.assertEquals(45, score, 'Lowercase b should match B and return 45');
    }

    @isTest
    static void testLowercaseHh_returns10() {
        Test.startTest();
        Decimal score = DnbFsiScoringService.getScore('hh');
        Test.stopTest();
        System.assertEquals(10, score, 'Lowercase hh should match HH and return 10');
    }

    // ─────────────────────────────────────────
    // Trim Tests
    // ─────────────────────────────────────────

    @isTest
    static void testPaddedStrength_trimsAndReturnsCorrectScore() {
        Test.startTest();
        Decimal score = DnbFsiScoringService.getScore('  4A  ');
        Test.stopTest();
        System.assertEquals(90, score, 'Padded 4A should trim and return 90');
    }

    @isTest
    static void testPaddedLowercase_trimsAndReturnsCorrectScore() {
        Test.startTest();
        Decimal score = DnbFsiScoringService.getScore('  3a  ');
        Test.stopTest();
        System.assertEquals(80, score, 'Padded lowercase 3a should trim and return 80');
    }
}