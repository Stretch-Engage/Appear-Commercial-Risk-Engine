public with sharing class DnbEnrichmentResult {
    

        public String duns;
        public String companyName ;
        public String address;
        public String city;
        public String state;
        public String postalCode;
        public String country;
        

        // Credit Information 
        public String financialStrength;          
        public Decimal failureScorePercentile;    
        public Decimal delinquencyScoreClass;
        public Decimal creditLimit;

        // Legal Information
        public Boolean hasOpenLiens;
        public Boolean hasOpenJudgments;
        public Boolean hasOpenBankruptcy;

        // Result
        public string appearCreditRating; // AMBER, GREEN, RED  
        public String ratingReason;

        // Transaction details
        public String transactionId;

    
}