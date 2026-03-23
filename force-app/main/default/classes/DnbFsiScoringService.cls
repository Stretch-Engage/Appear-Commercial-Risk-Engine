/**
 * DnbFsiScoringService
 * Converts a D&B Financial Strength Indicator (FSI) code into a numeric
 * score (0-100) so it can be plugged into the weighted composite calculation
 * in DnbCreditEvaluator. Higher score = stronger financial position.
 *
 * @author Sidharrth Nandhakumar
 * @date 23/03/2026
 */
public with sharing class DnbFsiScoringService {

    /**
     * Maps a D&B FSI code to a numeric score.
     * Returns 0 for blank or unrecognised codes — treated as no data.
     */
    public static Decimal getScore(String financialStrength) {

        if (String.isBlank(financialStrength)) {
            return 0;
        }

        String strength = financialStrength.trim().toUpperCase();

        // 5A-1A: largest companies by net worth, scored highest
        switch on strength {

            when '5A' { return 100; }
            when '4A' { return 95; }
            when '3A' { return 85; }
            when '2A' { return 75; }
            when '1A' { return 65; }

            when 'BA' { return 55; }
            when 'BB' { return 50; }

            when 'CB' { return 45; }
            when 'CC' { return 40; }
            when 'CD' { return 35; }

            when 'DC' { return 30; }
            when 'DD' { return 25; }

            when 'EE' { return 20; }
            when 'FF' { return 15; }
            when 'GG' { return 10; }
            when 'HH' { return 5; }

            // R-codes indicate an interim/unaudited balance sheet
            when '1R' { return 35; }
            when '2R' { return 20; }

            when else { return 0; }
        }
    }
}