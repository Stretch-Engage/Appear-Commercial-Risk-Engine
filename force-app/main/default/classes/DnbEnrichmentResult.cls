public with sharing class DnbEnrichmentResult {
    

        public String duns;
        public String companyName ;
        public String postalCode;
       
        

        // Credit Information 
        public String financialStrength;          
        public Decimal failureScorePercentile;    
        public Decimal delinquencyScoreClass;
        public Decimal creditLimit;
        public String compositeScore;

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