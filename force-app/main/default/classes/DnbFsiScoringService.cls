public with sharing class DnbFsiScoringService {

    public static Decimal getScore(String financialStrength) {

        if (String.isBlank(financialStrength)) {
            return 0;
        }

        String strength = financialStrength.trim().toUpperCase();

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

            when '1R' { return 35; }
            when '2R' { return 20; }

            when else { return 0; }
        }
    }
}