public with sharing class DnbFsiScoringService {

    public static Decimal getScore(String financialStrength) {

        if (String.isBlank(financialStrength)) {
            return 0;
        }

        String strength = financialStrength.trim().toUpperCase();

        switch on strength {
            when '5A' {
                return 100;
            }
            when '4A' {
                return 90;
            }
            when '3A' {
                return 80;
            }
            when '2A' {
                return 65;
            }
            when '1A' {
                return 55;
            }
            when 'B' {
                return 45;
            }
            when 'H' {
                return 25;
            }
            when 'HH' {
                return 10;
            }
            when else {
                return 0;
            }
        }
    }
}