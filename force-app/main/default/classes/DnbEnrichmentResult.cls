/**
 * DnbEnrichmentResult
 * Data container that holds everything parsed out of a D&B API response.
 * Gets populated by DnbParser, scored by DnbCreditEvaluator, then written
 * to the Account and Credit Assessment records by DnbCreditEngine.
 *
 * Phase 2 additions:
 *  - companyinfo fields (SIC, website, telephone, LEI) → Account
 *  - entityresolution familyTreeRole → Account
 *  - financialstrengthinsight extensions (failureScoreClass, delinquency fix,
 *    riskSegment, ratingReasons 1-5, financialCondition, isHighRiskBusiness)
 *  - companyfinancials overview block (14 fields) → Credit Assessment
 *  - eventfilings additions (secured filings, insolvency, judgments, CEO change)
 *
 * BREAKING FIX: delinquencyScoreClass now holds classScore (Integer 0–5)
 *               delinquencyScorePercentile is the new field for nationalPercentile
 *
 * @author Sidharrth Nandhakumar
 * @date 23/03/2026 — Phase 2 updated 02/04/2026
 */
public with sharing class DnbEnrichmentResult {

    // ── Identity ──────────────────────────────────────────────────────────────
    public String  duns;
    public String  companyName;
    public String  countryCode;           // fixed from postalCode (was wrong path)

    // ── Company Info → Account ────────────────────────────────────────────────
    public String  sicCode;               // primaryIndustryCode.usSicV4
    public String  sicDescription;        // primaryIndustryCode.usSicV4Description
    public String  websiteUrl;            // websiteAddress[0].url
    public String  websiteDomain;         // websiteAddress[0].domainName
    public String  telephoneNumber;       // telephone[0].telephoneNumber
    public String  telephoneIsdCode;      // telephone[0].isdCode
    public String  legalEntityIdentifier; // organization.legalEntityIdentifier
    public String  familyTreeRole;        // corporateLinkage.familytreeRolesPlayed[0].description

    // ── Failure Score ─────────────────────────────────────────────────────────
    public Decimal failureScoreClass;       // failureScore.classScore (0–9 integer)
    public String  failureScoreDescription; // failureScore.classScoreDescription
    public Decimal failureScorePercentile;  // failureScore.nationalPercentile

    // ── Delinquency Score — FIXED naming ─────────────────────────────────────
    public Decimal delinquencyScoreClass;       // delinquencyScore.classScore (0–5)
    public Decimal delinquencyScorePercentile;  // delinquencyScore.nationalPercentile
    public String  delinquencyScoreDescription; // delinquencyScore.classScoreDescription
    public String  delinqOverrideReason1;       // scoreOverrideReasons[0].description
    public String  delinqOverrideReason2;       // scoreOverrideReasons[1].description
    public String  delinqOverrideReason3;       // scoreOverrideReasons[2].description

    // ── Standard Rating ───────────────────────────────────────────────────────
    public String  financialStrength;     // standardRating.financialStrength
    public String  compositeScore;        // standardRating.rating (e.g. "2A1")
    public String  riskSegment;           // standardRating.riskSegment
    public String  dnbRatingDescription;  // joined ratingReasons — kept for Account summary field
    public String  ratingReason1;         // standardRating.ratingReason[0].description
    public String  ratingReason2;         // standardRating.ratingReason[1].description
    public String  ratingReason3;         // standardRating.ratingReason[2].description
    public String  ratingReason4;         // standardRating.ratingReason[3].description
    public String  ratingReason5;         // standardRating.ratingReason[4].description

    // ── Financial Condition ───────────────────────────────────────────────────
    public Decimal financialConditionCode;        // financialCondition.dnbCode
    public String  financialConditionDescription; // financialCondition.description

    // ── Credit Limit ──────────────────────────────────────────────────────────
    public Decimal creditLimit;           // creditLimitRecommendation.maximumRecommendedLimit.value
    public String  creditLimitCurrency;   // creditLimitRecommendation.maximumRecommendedLimit.currency

    // ── High Risk ────────────────────────────────────────────────────────────
    public Boolean isHighRiskBusiness;    // organization.isHighRiskBusiness

    // ── Company Financials Overview → Credit Assessment ───────────────────────
    public Decimal totalAssets;
    public Decimal totalCurrentAssets;
    public Decimal totalCurrentLiabilities;
    public Decimal totalLiabilities;
    public Decimal totalLiabilitiesEquity;
    public Decimal tangibleNetWorth;
    public Decimal capitalStock;
    public Decimal workingCapital;
    public Decimal netCurrentAssets;
    public Decimal currentRatio;
    public Decimal currentLiabilitiesOverNetWorth;
    public String  financialsFilingDate;       // latestFiscalFinancials.filingDate
    public String  financialsReceivedTimestamp;// latestFiscalFinancials.receivedTimestamp
    public String  financialStatementUnits;    // latestFiscalFinancials.units

    // ── Legal Events (Phase 1 — existing) ────────────────────────────────────
    public Boolean hasOpenLiens;
    public Boolean hasOpenJudgments;
    public Boolean hasOpenBankruptcy;

    // ── Legal & Financing Events (Phase 2 — new) ─────────────────────────────
    public Boolean hasOpenSecuredFilings; // financingEvents.hasOpenSecuredFilings
    public Boolean hasSecuredFilings;     // financingEvents.hasSecuredFilings
    public Boolean hasInsolvency;         // legalEvents.hasInsolvency
    public Boolean hasJudgments;          // legalEvents.hasJudgments (historical)
    public Boolean hasCEOChange;          // significantEvents.hasCEOChange

    // ── Evaluator Output ──────────────────────────────────────────────────────
    public String  appearCreditRating;    // GREEN / AMBER / RED
    public String  ratingReason;          // Human-readable evaluator reason

    // ── Traceability ──────────────────────────────────────────────────────────
    public String  transactionId;         // transactionDetail.transactionID

    public DnbEnrichmentResult() {
        // Default all booleans to false — avoids null checks downstream
        this.hasOpenLiens         = false;
        this.hasOpenJudgments     = false;
        this.hasOpenBankruptcy    = false;
        this.hasOpenSecuredFilings = false;
        this.hasSecuredFilings    = false;
        this.hasInsolvency        = false;
        this.hasJudgments         = false;
        this.hasCEOChange         = false;
        this.isHighRiskBusiness   = false;
    }
}