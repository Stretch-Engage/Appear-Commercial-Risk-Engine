/**
 * DnbEnrichmentResult
 * Data container that holds everything parsed out of a D&B API response.
 * Gets populated by DnbParser, scored by DnbCreditEvaluator, then written
 * to the Account and Credit Assessment records by DnbCreditEngine.
 *
 * @author Sidharrth Nandhakumar
 * @date 23/03/2026
 */
public with sharing class DnbEnrichmentResult {

        public String duns;
        public String companyName;
        public String postalCode;

        // Credit scoring inputs
        public String financialStrength;
        public Decimal failureScorePercentile;
        public Decimal delinquencyScoreClass;
        public Decimal creditLimit;
        public String creditLimitCurrency;
        public String compositeScore;

        // Human-readable descriptions of the scores above
        public String failureScoreDescription;
        public String delinquencyScoreDescription;
        public String dnbRatingDescription;

        // Legal flags — any open filings that could affect creditworthiness
        public Boolean hasOpenLiens;
        public Boolean hasOpenJudgments;
        public Boolean hasOpenBankruptcy;

        // Final output set by DnbCreditEvaluator (GREEN, AMBER, RED)
        public String appearCreditRating;
        public String ratingReason;

        // D&B transaction reference for traceability
        public String transactionId;

        public DnbEnrichmentResult() {
            // Defaulting legal flags to false so null checks aren't needed downstream
            this.hasOpenLiens      = false;
            this.hasOpenJudgments  = false;
            this.hasOpenBankruptcy = false;
        }
}