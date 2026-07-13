// Public-source + synthetic POC seed data.
// Public facts: regulatory references and Deutsche Bank AG LEI.
// Synthetic facts: counterparties, trades, exposures, controls, assessments, and amounts.
// Do not use the synthetic values for regulatory reporting or legal conclusions.

// -----------------------------------------------------------------------------
// Countries, jurisdictions, and authorities
// -----------------------------------------------------------------------------

UNWIND [
  {code: 'DE', isoAlpha3: 'DEU', name: 'Germany'},
  {code: 'GB', isoAlpha3: 'GBR', name: 'United Kingdom'},
  {code: 'US', isoAlpha3: 'USA', name: 'United States'}
] AS row
MERGE (node:Country {code: row.code})
SET node.isoAlpha3 = row.isoAlpha3,
    node.name = row.name;

UNWIND [
  {jurisdictionId: 'GLOBAL_BASEL', name: 'Global Basel jurisdiction', jurisdictionType: 'Global standard-setting scope'},
  {jurisdictionId: 'EU', name: 'European Union', jurisdictionType: 'Supranational'},
  {jurisdictionId: 'DE', name: 'Germany', jurisdictionType: 'National'},
  {jurisdictionId: 'GB', name: 'United Kingdom', jurisdictionType: 'National'},
  {jurisdictionId: 'US', name: 'United States', jurisdictionType: 'National'}
] AS row
MERGE (node:Jurisdiction {jurisdictionId: row.jurisdictionId})
SET node.name = row.name,
    node.jurisdictionType = row.jurisdictionType;

MATCH (country:Country), (jurisdiction:Jurisdiction)
WHERE country.code = jurisdiction.jurisdictionId
MERGE (country)-[:IS_REPRESENTED_BY_JURISDICTION]->(jurisdiction);

MATCH (germany:Jurisdiction {jurisdictionId: 'DE'}),
      (europeanUnion:Jurisdiction {jurisdictionId: 'EU'})
MERGE (germany)-[:IS_SUBJURISDICTION_OF_JURISDICTION]->(europeanUnion);

UNWIND [
  {regulatoryAuthorityId: 'BCBS', name: 'Basel Committee on Banking Supervision', authorityType: 'Global standard setter'},
  {regulatoryAuthorityId: 'EU_LEGISLATURE', name: 'European Parliament and Council', authorityType: 'Legislature'},
  {regulatoryAuthorityId: 'ECB_SSM', name: 'European Central Bank - Banking Supervision', authorityType: 'Prudential supervisor'},
  {regulatoryAuthorityId: 'BAFIN', name: 'Federal Financial Supervisory Authority', authorityType: 'Prudential supervisor'},
  {regulatoryAuthorityId: 'UK_PRA', name: 'UK Prudential Regulation Authority', authorityType: 'Prudential supervisor'},
  {regulatoryAuthorityId: 'US_FED', name: 'Board of Governors of the Federal Reserve System', authorityType: 'Prudential supervisor'}
] AS row
MERGE (node:RegulatoryAuthority {regulatoryAuthorityId: row.regulatoryAuthorityId})
SET node.name = row.name,
    node.authorityType = row.authorityType;

UNWIND [
  {authorityId: 'BCBS', jurisdictionId: 'GLOBAL_BASEL'},
  {authorityId: 'EU_LEGISLATURE', jurisdictionId: 'EU'},
  {authorityId: 'ECB_SSM', jurisdictionId: 'EU'},
  {authorityId: 'BAFIN', jurisdictionId: 'DE'},
  {authorityId: 'UK_PRA', jurisdictionId: 'GB'},
  {authorityId: 'US_FED', jurisdictionId: 'US'}
] AS row
MATCH (authority:RegulatoryAuthority {regulatoryAuthorityId: row.authorityId}),
      (jurisdiction:Jurisdiction {jurisdictionId: row.jurisdictionId})
MERGE (authority)-[:HAS_AUTHORITY_IN_JURISDICTION]->(jurisdiction);

// -----------------------------------------------------------------------------
// Public regulatory instruments and source-aware requirements
// -----------------------------------------------------------------------------

UNWIND [
  {
    regulatoryInstrumentId: 'BIS_BASEL_CRE52_2023',
    name: 'Basel Framework CRE52 - Standardised approach to counterparty credit risk',
    instrumentType: 'Global standard',
    versionLabel: 'Effective 2023 version',
    status: 'Current public example',
    sourceUrl: 'https://www.bis.org/basel_framework/chapter/CRE/52.htm',
    effectiveFrom: date('2023-01-01')
  },
  {
    regulatoryInstrumentId: 'EU_CRR_575_2013_2019_01_01',
    name: 'EU Capital Requirements Regulation 575/2013',
    instrumentType: 'EU regulation',
    versionLabel: 'Consolidated 2019-01-01',
    status: 'Versioned historical public example',
    sourceUrl: 'https://eur-lex.europa.eu/eli/reg/2013/575/2019-01-01/eng',
    effectiveFrom: date('2019-01-01')
  },
  {
    regulatoryInstrumentId: 'UK_PRA_CRR_2027',
    name: 'PRA Counterparty Credit Risk rules - 2027 implementation',
    instrumentType: 'PRA rulebook instrument',
    versionLabel: 'PRA2026/2 published January 2026',
    status: 'Published future requirement',
    sourceUrl: 'https://www.bankofengland.co.uk/prudential-regulation/publication/2026/january/restatement-of-crr-requirements-final-policy-statement',
    effectiveFrom: date('2027-01-01')
  },
  {
    regulatoryInstrumentId: 'US_INTERAGENCY_CCR_GUIDANCE',
    name: 'Interagency Supervisory Guidance on Counterparty Credit Risk Management',
    instrumentType: 'Supervisory guidance',
    versionLabel: 'Public Federal Reserve guidance',
    status: 'Current public example',
    sourceUrl: 'https://www.federalreserve.gov/frrs/guidance/interagency-supervisory-guidance-on-counterparty-credit-risk-management.htm',
    effectiveFrom: date('2011-06-29')
  }
] AS row
MERGE (node:RegulatoryInstrument {regulatoryInstrumentId: row.regulatoryInstrumentId})
SET node.name = row.name,
    node.instrumentType = row.instrumentType,
    node.versionLabel = row.versionLabel,
    node.status = row.status,
    node.sourceUrl = row.sourceUrl,
    node.effectiveFrom = row.effectiveFrom,
    node.publicSource = true;

UNWIND [
  {instrumentId: 'BIS_BASEL_CRE52_2023', authorityId: 'BCBS', jurisdictionId: 'GLOBAL_BASEL'},
  {instrumentId: 'EU_CRR_575_2013_2019_01_01', authorityId: 'EU_LEGISLATURE', jurisdictionId: 'EU'},
  {instrumentId: 'UK_PRA_CRR_2027', authorityId: 'UK_PRA', jurisdictionId: 'GB'},
  {instrumentId: 'US_INTERAGENCY_CCR_GUIDANCE', authorityId: 'US_FED', jurisdictionId: 'US'}
] AS row
MATCH (instrument:RegulatoryInstrument {regulatoryInstrumentId: row.instrumentId}),
      (authority:RegulatoryAuthority {regulatoryAuthorityId: row.authorityId}),
      (jurisdiction:Jurisdiction {jurisdictionId: row.jurisdictionId})
MERGE (authority)-[:ISSUES_REGULATORY_INSTRUMENT]->(instrument)
MERGE (instrument)-[:APPLIES_IN_JURISDICTION]->(jurisdiction);

UNWIND [
  {localId: 'EU_CRR_575_2013_2019_01_01', globalId: 'BIS_BASEL_CRE52_2023', mappingStatus: 'Partial historical implementation example'},
  {localId: 'UK_PRA_CRR_2027', globalId: 'BIS_BASEL_CRE52_2023', mappingStatus: 'Local implementation'},
  {localId: 'US_INTERAGENCY_CCR_GUIDANCE', globalId: 'BIS_BASEL_CRE52_2023', mappingStatus: 'Supervisory-practice alignment'}
] AS row
MATCH (local:RegulatoryInstrument {regulatoryInstrumentId: row.localId}),
      (global:RegulatoryInstrument {regulatoryInstrumentId: row.globalId})
MERGE (local)-[relationship:LOCALLY_IMPLEMENTS_REGULATORY_INSTRUMENT]->(global)
SET relationship.mappingStatus = row.mappingStatus,
    relationship.reviewRequired = true;

MERGE (topic:RiskTopic {riskTopicId: 'COUNTERPARTY_CREDIT_RISK'})
SET topic.name = 'Counterparty credit risk',
    topic.description = 'Risk of counterparty default or deterioration before final settlement of transaction cash flows';

UNWIND [
  {
    regulatoryRequirementId: 'BASEL_CRE52_SA_CCR_SCOPE',
    instrumentId: 'BIS_BASEL_CRE52_2023',
    referenceCode: 'CRE52.1',
    title: 'Apply SA-CCR to in-scope transactions',
    requirementText: 'Apply SA-CCR to OTC derivatives, exchange-traded derivatives, and long settlement transactions when the internal models method is not approved.',
    requirementType: 'Measurement method',
    effectiveFrom: date('2023-01-01')
  },
  {
    regulatoryRequirementId: 'BASEL_CRE52_NETTING_LEGAL_REVIEW',
    instrumentId: 'BIS_BASEL_CRE52_2023',
    referenceCode: 'CRE52 netting recognition conditions',
    title: 'Support netting with reasoned legal review',
    requirementText: 'Maintain written and reasoned legal review supporting enforceability of netting in the relevant counterparty, branch, and agreement jurisdictions.',
    requirementType: 'Legal enforceability',
    effectiveFrom: date('2023-01-01')
  },
  {
    regulatoryRequirementId: 'EU_CRR_ARTICLE_271_EXPOSURE_VALUE',
    instrumentId: 'EU_CRR_575_2013_2019_01_01',
    referenceCode: 'Article 271',
    title: 'Determine counterparty credit risk exposure value',
    requirementText: 'Determine the exposure value of derivative instruments under the counterparty credit risk chapter.',
    requirementType: 'Measurement method',
    effectiveFrom: date('2019-01-01')
  },
  {
    regulatoryRequirementId: 'UK_PRA_2027_NETTING_LEGAL_OPINION',
    instrumentId: 'UK_PRA_CRR_2027',
    referenceCode: 'Counterparty Credit Risk Part - contractual netting',
    title: 'Obtain legal opinions for contractual netting',
    requirementText: 'Obtain written and reasoned legal opinions on the validity and enforceability of netting under each relevant jurisdiction and make them available to the PRA on request.',
    requirementType: 'Legal enforceability',
    effectiveFrom: date('2027-01-01')
  },
  {
    regulatoryRequirementId: 'US_CCR_AGGREGATE_EXPOSURE_METRICS',
    instrumentId: 'US_INTERAGENCY_CCR_GUIDANCE',
    referenceCode: 'Risk measurement - exposure metrics',
    title: 'Measure and aggregate counterparty exposure',
    requirementText: 'Measure current exposure, potential exposure, stressed exposure, CVA, risk-factor sensitivities, and concentrations at useful aggregation levels.',
    requirementType: 'Risk management practice',
    effectiveFrom: date('2011-06-29')
  },
  {
    regulatoryRequirementId: 'US_CCR_ANNUAL_LEGAL_ENFORCEABILITY_REVIEW',
    instrumentId: 'US_INTERAGENCY_CCR_GUIDANCE',
    referenceCode: 'Legal and operational risk management',
    title: 'Review netting enforceability at least annually',
    requirementText: 'Review the legal enforceability of collateral and netting agreements for relevant jurisdictions at least annually.',
    requirementType: 'Legal enforceability',
    effectiveFrom: date('2011-06-29')
  }
] AS row
MERGE (requirement:RegulatoryRequirement {regulatoryRequirementId: row.regulatoryRequirementId})
SET requirement.referenceCode = row.referenceCode,
    requirement.title = row.title,
    requirement.requirementText = row.requirementText,
    requirement.requirementType = row.requirementType,
    requirement.effectiveFrom = row.effectiveFrom,
    requirement.sourceValidationStatus = 'Public source paraphrase - legal review required'
WITH requirement, row
MATCH (instrument:RegulatoryInstrument {regulatoryInstrumentId: row.instrumentId}),
      (topic:RiskTopic {riskTopicId: 'COUNTERPARTY_CREDIT_RISK'})
MERGE (instrument)-[:CONTAINS_REGULATORY_REQUIREMENT]->(requirement)
MERGE (requirement)-[:ADDRESSES_RISK_TOPIC]->(topic);

UNWIND [
  {localId: 'EU_CRR_ARTICLE_271_EXPOSURE_VALUE', globalId: 'BASEL_CRE52_SA_CCR_SCOPE', mappingStatus: 'Partial', rationale: 'Both require counterparty exposure measurement for derivatives; validate against the current EU text before production.'},
  {localId: 'UK_PRA_2027_NETTING_LEGAL_OPINION', globalId: 'BASEL_CRE52_NETTING_LEGAL_REVIEW', mappingStatus: 'Mapped', rationale: 'Local rule operationalizes written legal-opinion expectations for contractual netting.'},
  {localId: 'US_CCR_AGGREGATE_EXPOSURE_METRICS', globalId: 'BASEL_CRE52_SA_CCR_SCOPE', mappingStatus: 'Related supervisory practice', rationale: 'The guidance requires a broader set of counterparty exposure measures rather than prescribing only SA-CCR.'},
  {localId: 'US_CCR_ANNUAL_LEGAL_ENFORCEABILITY_REVIEW', globalId: 'BASEL_CRE52_NETTING_LEGAL_REVIEW', mappingStatus: 'Mapped', rationale: 'The guidance adds an explicit review cadence.'}
] AS row
MATCH (local:RegulatoryRequirement {regulatoryRequirementId: row.localId}),
      (global:RegulatoryRequirement {regulatoryRequirementId: row.globalId})
MERGE (local)-[relationship:LOCALLY_IMPLEMENTS_REQUIREMENT]->(global)
SET relationship.mappingStatus = row.mappingStatus,
    relationship.mappingRationale = row.rationale,
    relationship.reviewedBy = 'POC seed only';

// -----------------------------------------------------------------------------
// Typical source systems and organizational ownership
// -----------------------------------------------------------------------------

UNWIND [
  {sourceSystemId: 'PARTY_MASTER', name: 'Enterprise Party Master', dataDomain: 'Counterparty and legal entity reference data'},
  {sourceSystemId: 'GLEIF_PUBLIC_DATA', name: 'GLEIF LEI Data', dataDomain: 'External legal entity identity'},
  {sourceSystemId: 'TRADE_CAPTURE', name: 'Treasury Trade Capture', dataDomain: 'Trades and portfolios'},
  {sourceSystemId: 'CREDIT_RISK_ENGINE', name: 'Counterparty Credit Risk Engine', dataDomain: 'RC, PFE, EAD, CVA, limits'},
  {sourceSystemId: 'MARKET_RISK_ENGINE', name: 'Market Risk Engine', dataDomain: 'Delta, DV01, PV01, stress sensitivities'},
  {sourceSystemId: 'COLLATERAL_SYSTEM', name: 'Collateral Management System', dataDomain: 'Collateral agreements and positions'},
  {sourceSystemId: 'CREDIT_WORKFLOW', name: 'Credit Assessment Workflow', dataDomain: 'Ratings, probability of default, approvals'},
  {sourceSystemId: 'FINANCE_LEDGER', name: 'General Ledger and Balance Sheet Hub', dataDomain: 'Accounting positions and classifications'},
  {sourceSystemId: 'GRC_PLATFORM', name: 'Governance Risk and Compliance Platform', dataDomain: 'Requirements, policies, controls, assessments'},
  {sourceSystemId: 'DOCUMENT_REPOSITORY', name: 'Enterprise Document Repository', dataDomain: 'Regulations, legal opinions, policies, model documents'}
] AS row
MERGE (node:SourceSystem {sourceSystemId: row.sourceSystemId})
SET node.name = row.name,
    node.dataDomain = row.dataDomain;

UNWIND [
  {organizationalUnitId: 'TREASURY_RISK', name: 'Treasury Risk Management'},
  {organizationalUnitId: 'COUNTERPARTY_CREDIT_RISK', name: 'Counterparty Credit Risk'},
  {organizationalUnitId: 'REGULATORY_COMPLIANCE', name: 'Regulatory Compliance'},
  {organizationalUnitId: 'LEGAL_NETTING', name: 'Legal Netting Opinions'},
  {organizationalUnitId: 'FINANCE_CONTROL', name: 'Finance Product Control'}
] AS row
MERGE (node:OrganizationalUnit {organizationalUnitId: row.organizationalUnitId})
SET node.name = row.name;

// -----------------------------------------------------------------------------
// Legal entities, branches, counterparty group, and jurisdiction
// -----------------------------------------------------------------------------

MERGE (bank:LegalEntity {legalEntityId: 'DB_AG'})
SET bank.legalName = 'Deutsche Bank AG',
    bank.lei = '7LTWFZYICNSX8D621K86',
    bank.entityType = 'Bank legal entity',
    bank.entityStatus = 'Active',
    bank.sampleDataClassification = 'Public identity; no exposure data implied';

UNWIND [
  {legalEntityId: 'DB_NEW_YORK_BRANCH_POC', legalName: 'Deutsche Bank AG New York Branch - POC representation', entityType: 'International branch', entityStatus: 'Active'},
  {legalEntityId: 'NORTHSTAR_HOLDINGS_POC', legalName: 'Northstar Holdings plc - synthetic POC entity', entityType: 'Corporate parent', entityStatus: 'Active'},
  {legalEntityId: 'NORTHSTAR_TRADING_UK_POC', legalName: 'Northstar Energy Trading Ltd - synthetic POC entity', entityType: 'Counterparty legal entity', entityStatus: 'Active'},
  {legalEntityId: 'NORTHSTAR_PRIVATE_CREDIT_US_POC', legalName: 'Northstar Private Credit US Inc - synthetic POC entity', entityType: 'Counterparty legal entity', entityStatus: 'Active'}
] AS row
MERGE (node:LegalEntity {legalEntityId: row.legalEntityId})
SET node.legalName = row.legalName,
    node.entityType = row.entityType,
    node.entityStatus = row.entityStatus,
    node.sampleDataClassification = 'Synthetic POC data';

MERGE (group:CounterpartyGroup {counterpartyGroupId: 'NORTHSTAR_GROUP_POC'})
SET group.name = 'Northstar Group - synthetic POC group',
    group.groupingBasis = 'Internal connected-counterparty policy',
    group.sampleDataClassification = 'Synthetic POC data';

MATCH (branch:LegalEntity {legalEntityId: 'DB_NEW_YORK_BRANCH_POC'}),
      (bank:LegalEntity {legalEntityId: 'DB_AG'})
MERGE (branch)-[:IS_INTERNATIONAL_BRANCH_OF_LEGAL_ENTITY]->(bank);

UNWIND ['NORTHSTAR_TRADING_UK_POC', 'NORTHSTAR_PRIVATE_CREDIT_US_POC'] AS childId
MATCH (child:LegalEntity {legalEntityId: childId}),
      (parent:LegalEntity {legalEntityId: 'NORTHSTAR_HOLDINGS_POC'}),
      (group:CounterpartyGroup {counterpartyGroupId: 'NORTHSTAR_GROUP_POC'})
MERGE (child)-[:HAS_DIRECT_PARENT_LEGAL_ENTITY]->(parent)
MERGE (child)-[:IS_MEMBER_OF_COUNTERPARTY_GROUP]->(group);

UNWIND [
  {legalEntityId: 'DB_AG', countryCode: 'DE', relationshipType: 'registered'},
  {legalEntityId: 'DB_NEW_YORK_BRANCH_POC', countryCode: 'US', relationshipType: 'operates'},
  {legalEntityId: 'NORTHSTAR_HOLDINGS_POC', countryCode: 'GB', relationshipType: 'registered'},
  {legalEntityId: 'NORTHSTAR_TRADING_UK_POC', countryCode: 'GB', relationshipType: 'registered'},
  {legalEntityId: 'NORTHSTAR_PRIVATE_CREDIT_US_POC', countryCode: 'US', relationshipType: 'registered'}
] AS row
MATCH (entity:LegalEntity {legalEntityId: row.legalEntityId}),
      (country:Country {code: row.countryCode})
MERGE (entity)-[relationship:HAS_COUNTRY_PRESENCE]->(country)
SET relationship.presenceType = row.relationshipType;

MATCH (bank:LegalEntity {legalEntityId: 'DB_AG'})
MATCH (ecb:RegulatoryAuthority {regulatoryAuthorityId: 'ECB_SSM'}),
      (bafin:RegulatoryAuthority {regulatoryAuthorityId: 'BAFIN'})
MERGE (ecb)-[:SUPERVISES_LEGAL_ENTITY]->(bank)
MERGE (bafin)-[:SUPERVISES_LEGAL_ENTITY]->(bank);

MATCH (branch:LegalEntity {legalEntityId: 'DB_NEW_YORK_BRANCH_POC'}),
      (fed:RegulatoryAuthority {regulatoryAuthorityId: 'US_FED'})
MERGE (fed)-[:SUPERVISES_LEGAL_ENTITY]->(branch);

MATCH (bank:LegalEntity {legalEntityId: 'DB_AG'}),
      (gleif:SourceSystem {sourceSystemId: 'GLEIF_PUBLIC_DATA'}),
      (partyMaster:SourceSystem {sourceSystemId: 'PARTY_MASTER'})
MERGE (bank)-[:ORIGINATES_FROM_SOURCE_SYSTEM {sourceRecordId: '7LTWFZYICNSX8D621K86', dataQualityStatus: 'Public LEI reference'}]->(gleif)
MERGE (bank)-[:ORIGINATES_FROM_SOURCE_SYSTEM {sourceRecordId: 'DB_AG', dataQualityStatus: 'Golden source'}]->(partyMaster);

UNWIND ['DB_NEW_YORK_BRANCH_POC', 'NORTHSTAR_HOLDINGS_POC', 'NORTHSTAR_TRADING_UK_POC', 'NORTHSTAR_PRIVATE_CREDIT_US_POC'] AS legalEntityId
MATCH (entity:LegalEntity {legalEntityId: legalEntityId}),
      (partyMaster:SourceSystem {sourceSystemId: 'PARTY_MASTER'})
MERGE (entity)-[:ORIGINATES_FROM_SOURCE_SYSTEM {sourceRecordId: legalEntityId, dataQualityStatus: 'Synthetic POC'}]->(partyMaster);

// -----------------------------------------------------------------------------
// Portfolio, netting sets, agreements, trades, and collateral
// -----------------------------------------------------------------------------

MERGE (portfolio:Portfolio {portfolioId: 'TREASURY_COUNTERPARTY_POC'})
SET portfolio.name = 'Treasury counterparty risk POC portfolio',
    portfolio.businessUnit = 'Treasury',
    portfolio.bookingModel = 'Multi-entity',
    portfolio.sampleDataClassification = 'Synthetic POC data';

MATCH (portfolio:Portfolio {portfolioId: 'TREASURY_COUNTERPARTY_POC'}),
      (bank:LegalEntity {legalEntityId: 'DB_AG'}),
      (tradeSystem:SourceSystem {sourceSystemId: 'TRADE_CAPTURE'})
MERGE (portfolio)-[:OWNED_BY_BANK_LEGAL_ENTITY]->(bank)
MERGE (portfolio)-[:ORIGINATES_FROM_SOURCE_SYSTEM {sourceRecordId: 'TREASURY_COUNTERPARTY_POC', dataQualityStatus: 'Synthetic POC'}]->(tradeSystem);

UNWIND [
  {nettingSetId: 'NETTING_SET_DE_001', name: 'Germany derivative netting set - Northstar UK', status: 'Active', jurisdictionId: 'DE', bankId: 'DB_AG', counterpartyId: 'NORTHSTAR_TRADING_UK_POC'},
  {nettingSetId: 'NETTING_SET_US_001', name: 'US private-credit TRS netting set - Northstar US', status: 'Active', jurisdictionId: 'US', bankId: 'DB_NEW_YORK_BRANCH_POC', counterpartyId: 'NORTHSTAR_PRIVATE_CREDIT_US_POC'}
] AS row
MERGE (nettingSet:NettingSet {nettingSetId: row.nettingSetId})
SET nettingSet.name = row.name,
    nettingSet.status = row.status,
    nettingSet.nettingRecognitionStatus = 'Recognized for POC calculation',
    nettingSet.sampleDataClassification = 'Synthetic POC data'
WITH nettingSet, row
MATCH (portfolio:Portfolio {portfolioId: 'TREASURY_COUNTERPARTY_POC'}),
      (jurisdiction:Jurisdiction {jurisdictionId: row.jurisdictionId}),
      (bank:LegalEntity {legalEntityId: row.bankId}),
      (counterparty:LegalEntity {legalEntityId: row.counterpartyId}),
      (tradeSystem:SourceSystem {sourceSystemId: 'TRADE_CAPTURE'})
MERGE (portfolio)-[:CONTAINS_NETTING_SET]->(nettingSet)
MERGE (nettingSet)-[:HAS_BANK_LEGAL_ENTITY]->(bank)
MERGE (nettingSet)-[:HAS_COUNTERPARTY_LEGAL_ENTITY]->(counterparty)
MERGE (nettingSet)-[:OPERATES_UNDER_JURISDICTION]->(jurisdiction)
MERGE (nettingSet)-[:ORIGINATES_FROM_SOURCE_SYSTEM {sourceRecordId: row.nettingSetId, dataQualityStatus: 'Synthetic POC'}]->(tradeSystem);

UNWIND [
  {productTypeId: 'INTEREST_RATE_SWAP', name: 'Interest rate swap', assetClass: 'Interest rate', regulatoryProductClass: 'OTC derivative'},
  {productTypeId: 'TOTAL_RETURN_SWAP_PRIVATE_CREDIT', name: 'Total return swap on private-credit exposure', assetClass: 'Credit', regulatoryProductClass: 'OTC derivative'}
] AS row
MERGE (node:ProductType {productTypeId: row.productTypeId})
SET node.name = row.name,
    node.assetClass = row.assetClass,
    node.regulatoryProductClass = row.regulatoryProductClass;

UNWIND [
  {code: 'EUR', name: 'Euro'},
  {code: 'USD', name: 'US dollar'},
  {code: 'GBP', name: 'Pound sterling'}
] AS row
MERGE (node:Currency {code: row.code})
SET node.name = row.name;

UNWIND [
  {riskFactorId: 'EUR_SWAP_RATE_5Y', name: 'EUR five-year swap rate', riskFactorType: 'Interest rate'},
  {riskFactorId: 'PRIVATE_CREDIT_SPREAD_US', name: 'US private-credit spread', riskFactorType: 'Credit spread'}
] AS row
MERGE (node:RiskFactor {riskFactorId: row.riskFactorId})
SET node.name = row.name,
    node.riskFactorType = row.riskFactorType;

UNWIND [
  {tradeId: 'TRADE_IRS_DE_001', nettingSetId: 'NETTING_SET_DE_001', productTypeId: 'INTEREST_RATE_SWAP', currencyCode: 'EUR', riskFactorId: 'EUR_SWAP_RATE_5Y', tradeDate: date('2024-09-18'), maturityDate: date('2029-09-18'), notionalAmount: 100000000.0, fairValueAmount: 16000000.0, privateCreditIndicator: false},
  {tradeId: 'TRADE_TRS_US_001', nettingSetId: 'NETTING_SET_US_001', productTypeId: 'TOTAL_RETURN_SWAP_PRIVATE_CREDIT', currencyCode: 'USD', riskFactorId: 'PRIVATE_CREDIT_SPREAD_US', tradeDate: date('2025-02-10'), maturityDate: date('2028-02-10'), notionalAmount: 80000000.0, fairValueAmount: 11000000.0, privateCreditIndicator: true}
] AS row
MERGE (trade:Trade {tradeId: row.tradeId})
SET trade.tradeDate = row.tradeDate,
    trade.maturityDate = row.maturityDate,
    trade.notionalAmount = row.notionalAmount,
    trade.fairValueAmount = row.fairValueAmount,
    trade.privateCreditIndicator = row.privateCreditIndicator,
    trade.sampleDataClassification = 'Synthetic POC data'
WITH trade, row
MATCH (nettingSet:NettingSet {nettingSetId: row.nettingSetId}),
      (productType:ProductType {productTypeId: row.productTypeId}),
      (currency:Currency {code: row.currencyCode}),
      (riskFactor:RiskFactor {riskFactorId: row.riskFactorId}),
      (tradeSystem:SourceSystem {sourceSystemId: 'TRADE_CAPTURE'})
MERGE (nettingSet)-[:CONTAINS_TRADE]->(trade)
MERGE (trade)-[:HAS_PRODUCT_TYPE]->(productType)
MERGE (trade)-[:DENOMINATED_IN_CURRENCY]->(currency)
MERGE (trade)-[:REFERENCES_RISK_FACTOR]->(riskFactor)
MERGE (trade)-[:ORIGINATES_FROM_SOURCE_SYSTEM {sourceRecordId: row.tradeId, dataQualityStatus: 'Synthetic POC'}]->(tradeSystem);

UNWIND [
  {masterAgreementId: 'MASTER_AGREEMENT_DE_001', agreementType: 'ISDA Master Agreement', governingLaw: 'English law', nettingSetId: 'NETTING_SET_DE_001'},
  {masterAgreementId: 'MASTER_AGREEMENT_US_001', agreementType: 'ISDA Master Agreement', governingLaw: 'New York law', nettingSetId: 'NETTING_SET_US_001'}
] AS row
MERGE (agreement:MasterAgreement {masterAgreementId: row.masterAgreementId})
SET agreement.agreementType = row.agreementType,
    agreement.governingLaw = row.governingLaw,
    agreement.executionStatus = 'Executed',
    agreement.sampleDataClassification = 'Synthetic POC data'
WITH agreement, row
MATCH (nettingSet:NettingSet {nettingSetId: row.nettingSetId}),
      (documentSystem:SourceSystem {sourceSystemId: 'DOCUMENT_REPOSITORY'})
MERGE (nettingSet)-[:GOVERNED_BY_MASTER_AGREEMENT]->(agreement)
MERGE (agreement)-[:ORIGINATES_FROM_SOURCE_SYSTEM {sourceRecordId: row.masterAgreementId, dataQualityStatus: 'Synthetic POC'}]->(documentSystem);

UNWIND [
  {collateralAgreementId: 'CSA_DE_001', masterAgreementId: 'MASTER_AGREEMENT_DE_001', agreementType: 'Credit Support Annex', marginFrequency: 'Daily', thresholdAmount: 0.0, minimumTransferAmount: 500000.0},
  {collateralAgreementId: 'CSA_US_001', masterAgreementId: 'MASTER_AGREEMENT_US_001', agreementType: 'Credit Support Annex', marginFrequency: 'Daily', thresholdAmount: 1000000.0, minimumTransferAmount: 500000.0}
] AS row
MERGE (agreement:CollateralAgreement {collateralAgreementId: row.collateralAgreementId})
SET agreement.agreementType = row.agreementType,
    agreement.marginFrequency = row.marginFrequency,
    agreement.thresholdAmount = row.thresholdAmount,
    agreement.minimumTransferAmount = row.minimumTransferAmount,
    agreement.sampleDataClassification = 'Synthetic POC data'
WITH agreement, row
MATCH (master:MasterAgreement {masterAgreementId: row.masterAgreementId}),
      (collateralSystem:SourceSystem {sourceSystemId: 'COLLATERAL_SYSTEM'})
MERGE (master)-[:HAS_COLLATERAL_AGREEMENT]->(agreement)
MERGE (agreement)-[:ORIGINATES_FROM_SOURCE_SYSTEM {sourceRecordId: row.collateralAgreementId, dataQualityStatus: 'Synthetic POC'}]->(collateralSystem);

UNWIND [
  {legalOpinionId: 'LEGAL_OPINION_DE_GB_2026', opinionStatus: 'Current', opinionDate: date('2026-01-15'), reviewDueDate: date('2027-01-14'), masterAgreementId: 'MASTER_AGREEMENT_DE_001', jurisdictionIds: ['DE', 'GB']},
  {legalOpinionId: 'LEGAL_OPINION_US_2024', opinionStatus: 'Expired', opinionDate: date('2024-01-01'), reviewDueDate: date('2025-12-31'), masterAgreementId: 'MASTER_AGREEMENT_US_001', jurisdictionIds: ['US']}
] AS row
MERGE (opinion:LegalOpinion {legalOpinionId: row.legalOpinionId})
SET opinion.opinionStatus = row.opinionStatus,
    opinion.opinionDate = row.opinionDate,
    opinion.reviewDueDate = row.reviewDueDate,
    opinion.conclusion = 'Netting enforceability conclusion - synthetic POC only',
    opinion.sampleDataClassification = 'Synthetic POC data'
WITH opinion, row
MATCH (master:MasterAgreement {masterAgreementId: row.masterAgreementId}),
      (documentSystem:SourceSystem {sourceSystemId: 'DOCUMENT_REPOSITORY'})
MERGE (opinion)-[:OPINES_ON_MASTER_AGREEMENT]->(master)
MERGE (opinion)-[:ORIGINATES_FROM_SOURCE_SYSTEM {sourceRecordId: row.legalOpinionId, dataQualityStatus: 'Synthetic POC'}]->(documentSystem)
WITH opinion, row
UNWIND row.jurisdictionIds AS jurisdictionId
MATCH (jurisdiction:Jurisdiction {jurisdictionId: jurisdictionId})
MERGE (opinion)-[:COVERS_JURISDICTION]->(jurisdiction);

UNWIND [
  {nettingSetId: 'NETTING_SET_DE_001', legalOpinionId: 'LEGAL_OPINION_DE_GB_2026'},
  {nettingSetId: 'NETTING_SET_US_001', legalOpinionId: 'LEGAL_OPINION_US_2024'}
] AS row
MATCH (nettingSet:NettingSet {nettingSetId: row.nettingSetId}),
      (opinion:LegalOpinion {legalOpinionId: row.legalOpinionId})
MERGE (nettingSet)-[:RELIES_ON_LEGAL_OPINION]->(opinion);

UNWIND [
  {collateralAssetId: 'CASH_EUR', name: 'Cash collateral in EUR', assetType: 'Cash', currencyCode: 'EUR'},
  {collateralAssetId: 'US_TREASURY_POC', name: 'US Treasury collateral basket - POC', assetType: 'Government security', currencyCode: 'USD'}
] AS row
MERGE (asset:CollateralAsset {collateralAssetId: row.collateralAssetId})
SET asset.name = row.name,
    asset.assetType = row.assetType,
    asset.sampleDataClassification = 'Synthetic POC data'
WITH asset, row
MATCH (currency:Currency {code: row.currencyCode})
MERGE (asset)-[:VALUED_IN_CURRENCY]->(currency);

UNWIND [
  {collateralPositionId: 'COLLATERAL_POSITION_DE_2026_06_30', nettingSetId: 'NETTING_SET_DE_001', collateralAssetId: 'CASH_EUR', marketValueAmount: 2000000.0, haircutAmount: 0.0, asOfDate: date('2026-06-30')},
  {collateralPositionId: 'COLLATERAL_POSITION_US_2026_06_30', nettingSetId: 'NETTING_SET_US_001', collateralAssetId: 'US_TREASURY_POC', marketValueAmount: 2000000.0, haircutAmount: 200000.0, asOfDate: date('2026-06-30')}
] AS row
MERGE (position:CollateralPosition {collateralPositionId: row.collateralPositionId})
SET position.marketValueAmount = row.marketValueAmount,
    position.haircutAmount = row.haircutAmount,
    position.asOfDate = row.asOfDate,
    position.sampleDataClassification = 'Synthetic POC data'
WITH position, row
MATCH (nettingSet:NettingSet {nettingSetId: row.nettingSetId}),
      (asset:CollateralAsset {collateralAssetId: row.collateralAssetId}),
      (collateralSystem:SourceSystem {sourceSystemId: 'COLLATERAL_SYSTEM'})
MERGE (position)-[:SECURES_NETTING_SET]->(nettingSet)
MERGE (position)-[:USES_COLLATERAL_ASSET]->(asset)
MERGE (position)-[:ORIGINATES_FROM_SOURCE_SYSTEM {sourceRecordId: row.collateralPositionId, dataQualityStatus: 'Synthetic POC'}]->(collateralSystem);

// -----------------------------------------------------------------------------
// Risk models, calculations, measurements, credit, and limits
// -----------------------------------------------------------------------------

UNWIND [
  {riskMeasureDefinitionId: 'REPLACEMENT_COST', name: 'Replacement cost', abbreviation: 'RC', unitType: 'Currency amount', aggregationBehavior: 'Additive only for compatible scopes and currencies'},
  {riskMeasureDefinitionId: 'POTENTIAL_FUTURE_EXPOSURE', name: 'Potential future exposure', abbreviation: 'PFE', unitType: 'Currency amount', aggregationBehavior: 'Do not sum without an approved aggregation methodology'},
  {riskMeasureDefinitionId: 'EXPOSURE_AT_DEFAULT', name: 'Exposure at default', abbreviation: 'EAD', unitType: 'Currency amount', aggregationBehavior: 'Additive after currency and scope alignment'},
  {riskMeasureDefinitionId: 'CREDIT_VALUATION_ADJUSTMENT', name: 'Credit valuation adjustment', abbreviation: 'CVA', unitType: 'Currency amount', aggregationBehavior: 'Additive after currency and valuation-basis alignment'},
  {riskMeasureDefinitionId: 'DOLLAR_VALUE_OF_ONE_BASIS_POINT', name: 'Dollar value of one basis point', abbreviation: 'DV01', unitType: 'Currency per basis point', aggregationBehavior: 'Signed additive sensitivity after risk-factor alignment'},
  {riskMeasureDefinitionId: 'DELTA', name: 'Delta sensitivity', abbreviation: 'Delta', unitType: 'Sensitivity', aggregationBehavior: 'Aggregate only for the same underlying and units'},
  {riskMeasureDefinitionId: 'STRESSED_EXPOSURE', name: 'Stressed counterparty exposure', abbreviation: 'Stressed exposure', unitType: 'Currency amount', aggregationBehavior: 'Scenario-specific; do not mix scenarios'},
  {riskMeasureDefinitionId: 'ECONOMIC_VALUE_OF_EQUITY', name: 'Economic value of equity', abbreviation: 'EVE', unitType: 'Currency amount', aggregationBehavior: 'Banking-book measure; aggregate only under consistent assumptions'}
] AS row
MERGE (node:RiskMeasureDefinition {riskMeasureDefinitionId: row.riskMeasureDefinitionId})
SET node.name = row.name,
    node.abbreviation = row.abbreviation,
    node.unitType = row.unitType,
    node.aggregationBehavior = row.aggregationBehavior;

UNWIND [
  {riskModelId: 'SA_CCR_MODEL_V1', name: 'SA-CCR calculation model version 1', modelType: 'Regulatory exposure model', version: '1.0'},
  {riskModelId: 'COUNTERPARTY_PD_MODEL_V3', name: 'Counterparty probability-of-default model version 3', modelType: 'Credit rating model', version: '3.0'},
  {riskModelId: 'MARKET_SENSITIVITY_MODEL_V2', name: 'Market sensitivity model version 2', modelType: 'Market risk model', version: '2.0'}
] AS row
MERGE (node:RiskModel {riskModelId: row.riskModelId})
SET node.name = row.name,
    node.modelType = row.modelType,
    node.version = row.version,
    node.approvalStatus = 'POC representation';

UNWIND [
  {modelAssumptionId: 'SA_CCR_ALPHA_1_4', name: 'SA-CCR alpha multiplier', assumptionValue: 1.4, unit: 'Multiplier', riskModelId: 'SA_CCR_MODEL_V1', sourceType: 'Regulatory parameter'},
  {modelAssumptionId: 'SA_CCR_MARGIN_PERIOD_10D', name: 'Margin period of risk', assumptionValue: 10.0, unit: 'Business days', riskModelId: 'SA_CCR_MODEL_V1', sourceType: 'POC regulatory parameter'},
  {modelAssumptionId: 'PRIVATE_CREDIT_SPREAD_PROXY', name: 'Private-credit spread proxy hierarchy', assumptionValue: 1.0, unit: 'Policy version', riskModelId: 'MARKET_SENSITIVITY_MODEL_V2', sourceType: 'Internal model assumption'}
] AS row
MERGE (assumption:ModelAssumption {modelAssumptionId: row.modelAssumptionId})
SET assumption.name = row.name,
    assumption.assumptionValue = row.assumptionValue,
    assumption.unit = row.unit,
    assumption.sourceType = row.sourceType,
    assumption.validFrom = date('2026-01-01')
WITH assumption, row
MATCH (model:RiskModel {riskModelId: row.riskModelId})
MERGE (model)-[:USES_MODEL_ASSUMPTION]->(assumption);

UNWIND [
  {stressScenarioId: 'RATES_UP_200_BPS', name: 'Parallel interest-rate shock up 200 basis points', scenarioType: 'Hypothetical stress'},
  {stressScenarioId: 'PRIVATE_CREDIT_SPREAD_WIDEN_300_BPS', name: 'Private-credit spread widening 300 basis points', scenarioType: 'Hypothetical stress'}
] AS row
MERGE (node:StressScenario {stressScenarioId: row.stressScenarioId})
SET node.name = row.name,
    node.scenarioType = row.scenarioType;

UNWIND [
  {riskCalculationRunId: 'CCR_RUN_2026_06_30', name: 'Counterparty credit risk close', asOfDate: date('2026-06-30'), runStatus: 'Completed', modelId: 'SA_CCR_MODEL_V1', engineId: 'CREDIT_RISK_ENGINE'},
  {riskCalculationRunId: 'MARKET_RUN_2026_06_30', name: 'Market risk sensitivity close', asOfDate: date('2026-06-30'), runStatus: 'Completed', modelId: 'MARKET_SENSITIVITY_MODEL_V2', engineId: 'MARKET_RISK_ENGINE'}
] AS row
MERGE (run:RiskCalculationRun {riskCalculationRunId: row.riskCalculationRunId})
SET run.name = row.name,
    run.asOfDate = row.asOfDate,
    run.runStatus = row.runStatus,
    run.completedAt = datetime('2026-07-01T03:30:00Z'),
    run.sampleDataClassification = 'Synthetic POC data'
WITH run, row
MATCH (model:RiskModel {riskModelId: row.modelId}),
      (engine:SourceSystem {sourceSystemId: row.engineId})
MERGE (run)-[:USES_RISK_MODEL]->(model)
MERGE (run)-[:EXECUTED_BY_SOURCE_SYSTEM]->(engine);

MATCH (run:RiskCalculationRun {riskCalculationRunId: 'CCR_RUN_2026_06_30'})
UNWIND ['TRADE_CAPTURE', 'COLLATERAL_SYSTEM', 'CREDIT_WORKFLOW'] AS sourceSystemId
MATCH (system:SourceSystem {sourceSystemId: sourceSystemId})
MERGE (run)-[:READS_FROM_SOURCE_SYSTEM]->(system);

MATCH (run:RiskCalculationRun {riskCalculationRunId: 'MARKET_RUN_2026_06_30'})
UNWIND ['TRADE_CAPTURE', 'MARKET_RISK_ENGINE'] AS sourceSystemId
MATCH (system:SourceSystem {sourceSystemId: sourceSystemId})
MERGE (run)-[:READS_FROM_SOURCE_SYSTEM]->(system);

UNWIND [
  {riskMeasurementId: 'MEASURE_RC_DE_2026_06_30', definitionId: 'REPLACEMENT_COST', nettingSetId: 'NETTING_SET_DE_001', value: 14000000.0, currencyCode: 'EUR', runId: 'CCR_RUN_2026_06_30'},
  {riskMeasurementId: 'MEASURE_PFE_DE_2026_06_30', definitionId: 'POTENTIAL_FUTURE_EXPOSURE', nettingSetId: 'NETTING_SET_DE_001', value: 6000000.0, currencyCode: 'EUR', runId: 'CCR_RUN_2026_06_30'},
  {riskMeasurementId: 'MEASURE_EAD_DE_2026_06_30', definitionId: 'EXPOSURE_AT_DEFAULT', nettingSetId: 'NETTING_SET_DE_001', value: 28000000.0, currencyCode: 'EUR', runId: 'CCR_RUN_2026_06_30'},
  {riskMeasurementId: 'MEASURE_CVA_DE_2026_06_30', definitionId: 'CREDIT_VALUATION_ADJUSTMENT', nettingSetId: 'NETTING_SET_DE_001', value: 1250000.0, currencyCode: 'EUR', runId: 'CCR_RUN_2026_06_30'},
  {riskMeasurementId: 'MEASURE_RC_US_2026_06_30', definitionId: 'REPLACEMENT_COST', nettingSetId: 'NETTING_SET_US_001', value: 9000000.0, currencyCode: 'EUR', runId: 'CCR_RUN_2026_06_30'},
  {riskMeasurementId: 'MEASURE_PFE_US_2026_06_30', definitionId: 'POTENTIAL_FUTURE_EXPOSURE', nettingSetId: 'NETTING_SET_US_001', value: 4000000.0, currencyCode: 'EUR', runId: 'CCR_RUN_2026_06_30'},
  {riskMeasurementId: 'MEASURE_EAD_US_2026_06_30', definitionId: 'EXPOSURE_AT_DEFAULT', nettingSetId: 'NETTING_SET_US_001', value: 18200000.0, currencyCode: 'EUR', runId: 'CCR_RUN_2026_06_30'},
  {riskMeasurementId: 'MEASURE_CVA_US_2026_06_30', definitionId: 'CREDIT_VALUATION_ADJUSTMENT', nettingSetId: 'NETTING_SET_US_001', value: 900000.0, currencyCode: 'EUR', runId: 'CCR_RUN_2026_06_30'},
  {riskMeasurementId: 'MEASURE_STRESS_DE_2026_06_30', definitionId: 'STRESSED_EXPOSURE', nettingSetId: 'NETTING_SET_DE_001', value: 39000000.0, currencyCode: 'EUR', runId: 'CCR_RUN_2026_06_30'},
  {riskMeasurementId: 'MEASURE_STRESS_US_2026_06_30', definitionId: 'STRESSED_EXPOSURE', nettingSetId: 'NETTING_SET_US_001', value: 31500000.0, currencyCode: 'EUR', runId: 'CCR_RUN_2026_06_30'},
  {riskMeasurementId: 'MEASURE_DV01_DE_2026_06_30', definitionId: 'DOLLAR_VALUE_OF_ONE_BASIS_POINT', nettingSetId: 'NETTING_SET_DE_001', value: 42000.0, currencyCode: 'EUR', runId: 'MARKET_RUN_2026_06_30'},
  {riskMeasurementId: 'MEASURE_DELTA_US_2026_06_30', definitionId: 'DELTA', nettingSetId: 'NETTING_SET_US_001', value: 0.82, currencyCode: 'EUR', runId: 'MARKET_RUN_2026_06_30'}
] AS row
MERGE (measurement:RiskMeasurement {riskMeasurementId: row.riskMeasurementId})
SET measurement.value = row.value,
    measurement.asOfDate = date('2026-06-30'),
    measurement.measurementBasis = 'End-of-day',
    measurement.sampleDataClassification = 'Synthetic POC data'
WITH measurement, row
MATCH (definition:RiskMeasureDefinition {riskMeasureDefinitionId: row.definitionId}),
      (nettingSet:NettingSet {nettingSetId: row.nettingSetId}),
      (currency:Currency {code: row.currencyCode}),
      (run:RiskCalculationRun {riskCalculationRunId: row.runId})
MERGE (measurement)-[:USES_RISK_MEASURE_DEFINITION]->(definition)
MERGE (measurement)-[:MEASURES_NETTING_SET]->(nettingSet)
MERGE (measurement)-[:DENOMINATED_IN_CURRENCY]->(currency)
MERGE (measurement)-[:PRODUCED_BY_RISK_CALCULATION_RUN]->(run);

UNWIND [
  {measurementId: 'MEASURE_STRESS_DE_2026_06_30', scenarioId: 'RATES_UP_200_BPS'},
  {measurementId: 'MEASURE_STRESS_US_2026_06_30', scenarioId: 'PRIVATE_CREDIT_SPREAD_WIDEN_300_BPS'}
] AS row
MATCH (measurement:RiskMeasurement {riskMeasurementId: row.measurementId}),
      (scenario:StressScenario {stressScenarioId: row.scenarioId})
MERGE (measurement)-[:MEASURED_UNDER_STRESS_SCENARIO]->(scenario);

UNWIND [
  {creditAssessmentId: 'CREDIT_ASSESSMENT_NORTHSTAR_UK_2026_06_30', legalEntityId: 'NORTHSTAR_TRADING_UK_POC', internalRating: 'BBB-', probabilityOfDefault: 0.012, watchListStatus: 'No'},
  {creditAssessmentId: 'CREDIT_ASSESSMENT_NORTHSTAR_US_2026_06_30', legalEntityId: 'NORTHSTAR_PRIVATE_CREDIT_US_POC', internalRating: 'BB', probabilityOfDefault: 0.028, watchListStatus: 'Enhanced monitoring'}
] AS row
MERGE (assessment:CreditAssessment {creditAssessmentId: row.creditAssessmentId})
SET assessment.internalRating = row.internalRating,
    assessment.probabilityOfDefault = row.probabilityOfDefault,
    assessment.watchListStatus = row.watchListStatus,
    assessment.asOfDate = date('2026-06-30'),
    assessment.sampleDataClassification = 'Synthetic POC data'
WITH assessment, row
MATCH (entity:LegalEntity {legalEntityId: row.legalEntityId}),
      (model:RiskModel {riskModelId: 'COUNTERPARTY_PD_MODEL_V3'}),
      (workflow:SourceSystem {sourceSystemId: 'CREDIT_WORKFLOW'})
MERGE (assessment)-[:ASSESSES_LEGAL_ENTITY]->(entity)
MERGE (assessment)-[:PRODUCED_BY_RISK_MODEL]->(model)
MERGE (assessment)-[:ORIGINATES_FROM_SOURCE_SYSTEM {sourceRecordId: row.creditAssessmentId, dataQualityStatus: 'Synthetic POC'}]->(workflow);

UNWIND [
  {measurementId: 'MEASURE_CVA_DE_2026_06_30', creditAssessmentId: 'CREDIT_ASSESSMENT_NORTHSTAR_UK_2026_06_30'},
  {measurementId: 'MEASURE_CVA_US_2026_06_30', creditAssessmentId: 'CREDIT_ASSESSMENT_NORTHSTAR_US_2026_06_30'}
] AS row
MATCH (measurement:RiskMeasurement {riskMeasurementId: row.measurementId}),
      (assessment:CreditAssessment {creditAssessmentId: row.creditAssessmentId})
MERGE (measurement)-[:USES_CREDIT_ASSESSMENT]->(assessment);

MERGE (limit:RiskLimit {riskLimitId: 'NORTHSTAR_GROUP_EAD_LIMIT'})
SET limit.name = 'Northstar Group aggregate EAD limit',
    limit.thresholdValue = 45000000.0,
    limit.limitStatus = 'Active',
    limit.validFrom = date('2026-01-01'),
    limit.sampleDataClassification = 'Synthetic POC data';

MATCH (limit:RiskLimit {riskLimitId: 'NORTHSTAR_GROUP_EAD_LIMIT'}),
      (group:CounterpartyGroup {counterpartyGroupId: 'NORTHSTAR_GROUP_POC'}),
      (definition:RiskMeasureDefinition {riskMeasureDefinitionId: 'EXPOSURE_AT_DEFAULT'}),
      (currency:Currency {code: 'EUR'}),
      (riskEngine:SourceSystem {sourceSystemId: 'CREDIT_RISK_ENGINE'})
MERGE (limit)-[:LIMITS_COUNTERPARTY_GROUP]->(group)
MERGE (limit)-[:USES_RISK_MEASURE_DEFINITION]->(definition)
MERGE (limit)-[:DENOMINATED_IN_CURRENCY]->(currency)
MERGE (limit)-[:ORIGINATES_FROM_SOURCE_SYSTEM {sourceRecordId: 'NORTHSTAR_GROUP_EAD_LIMIT', dataQualityStatus: 'Synthetic POC'}]->(riskEngine);

// -----------------------------------------------------------------------------
// Finance / balance-sheet bridge
// -----------------------------------------------------------------------------

MERGE (classification:AccountingClassification {accountingClassificationId: 'IFRS9_FVTPL_DERIVATIVE_ASSET'})
SET classification.name = 'IFRS 9 fair value through profit or loss - derivative asset',
    classification.accountingStandard = 'IFRS';

MERGE (account:GeneralLedgerAccount {generalLedgerAccountId: 'GL_DERIVATIVE_ASSETS_POC'})
SET account.accountNumber = 'POC-135000',
    account.name = 'Derivative assets - POC',
    account.chartOfAccounts = 'Synthetic POC chart';

UNWIND [
  {balanceSheetPositionId: 'BALANCE_POSITION_DE_2026_06_30', tradeId: 'TRADE_IRS_DE_001', legalEntityId: 'DB_AG', carryingValueAmount: 15800000.0, currencyCode: 'EUR'},
  {balanceSheetPositionId: 'BALANCE_POSITION_US_2026_06_30', tradeId: 'TRADE_TRS_US_001', legalEntityId: 'DB_NEW_YORK_BRANCH_POC', carryingValueAmount: 10700000.0, currencyCode: 'USD'}
] AS row
MERGE (position:BalanceSheetPosition {balanceSheetPositionId: row.balanceSheetPositionId})
SET position.carryingValueAmount = row.carryingValueAmount,
    position.asOfDate = date('2026-06-30'),
    position.balanceSheetSide = 'Asset',
    position.sampleDataClassification = 'Synthetic POC data'
WITH position, row
MATCH (trade:Trade {tradeId: row.tradeId}),
      (entity:LegalEntity {legalEntityId: row.legalEntityId}),
      (classification:AccountingClassification {accountingClassificationId: 'IFRS9_FVTPL_DERIVATIVE_ASSET'}),
      (account:GeneralLedgerAccount {generalLedgerAccountId: 'GL_DERIVATIVE_ASSETS_POC'}),
      (currency:Currency {code: row.currencyCode}),
      (financeSystem:SourceSystem {sourceSystemId: 'FINANCE_LEDGER'})
MERGE (position)-[:RELATES_TO_TRADE]->(trade)
MERGE (position)-[:BOOKED_BY_LEGAL_ENTITY]->(entity)
MERGE (position)-[:HAS_ACCOUNTING_CLASSIFICATION]->(classification)
MERGE (position)-[:POSTED_TO_GENERAL_LEDGER_ACCOUNT]->(account)
MERGE (position)-[:DENOMINATED_IN_CURRENCY]->(currency)
MERGE (position)-[:ORIGINATES_FROM_SOURCE_SYSTEM {sourceRecordId: row.balanceSheetPositionId, dataQualityStatus: 'Synthetic POC'}]->(financeSystem);

UNWIND [
  {measurementId: 'MEASURE_RC_DE_2026_06_30', balanceSheetPositionId: 'BALANCE_POSITION_DE_2026_06_30'},
  {measurementId: 'MEASURE_RC_US_2026_06_30', balanceSheetPositionId: 'BALANCE_POSITION_US_2026_06_30'}
] AS row
MATCH (measurement:RiskMeasurement {riskMeasurementId: row.measurementId}),
      (position:BalanceSheetPosition {balanceSheetPositionId: row.balanceSheetPositionId})
MERGE (measurement)-[:COMPARED_WITH_BALANCE_SHEET_POSITION]->(position);

// -----------------------------------------------------------------------------
// Applicability, policy, controls, assessments, evidence, and gaps
// -----------------------------------------------------------------------------

UNWIND [
  {applicabilityRuleId: 'RULE_EU_DERIVATIVE_EXPOSURE', name: 'EU derivative exposure rule', ruleExpression: 'bankEntity is in EU AND productClass is OTC derivative', ruleLanguage: 'Plain English decision rule'},
  {applicabilityRuleId: 'RULE_UK_NETTING_LEGAL_OPINION', name: 'UK contractual netting opinion rule', ruleExpression: 'nettingSet uses UK law OR counterparty or branch is in UK', ruleLanguage: 'Plain English decision rule'},
  {applicabilityRuleId: 'RULE_US_CCR_EXPOSURE_AGGREGATION', name: 'US CCR aggregation rule', ruleExpression: 'US supervised branch has material counterparty exposure', ruleLanguage: 'Plain English decision rule'},
  {applicabilityRuleId: 'RULE_US_ANNUAL_LEGAL_REVIEW', name: 'US annual legal enforceability review rule', ruleExpression: 'nettingSet is recognized in US AND legalOpinion.reviewDueDate is before assessment date', ruleLanguage: 'Plain English decision rule'}
] AS row
MERGE (node:ApplicabilityRule {applicabilityRuleId: row.applicabilityRuleId})
SET node.name = row.name,
    node.ruleExpression = row.ruleExpression,
    node.ruleLanguage = row.ruleLanguage,
    node.version = 'POC-1';

UNWIND [
  {requirementId: 'EU_CRR_ARTICLE_271_EXPOSURE_VALUE', ruleId: 'RULE_EU_DERIVATIVE_EXPOSURE'},
  {requirementId: 'UK_PRA_2027_NETTING_LEGAL_OPINION', ruleId: 'RULE_UK_NETTING_LEGAL_OPINION'},
  {requirementId: 'US_CCR_AGGREGATE_EXPOSURE_METRICS', ruleId: 'RULE_US_CCR_EXPOSURE_AGGREGATION'},
  {requirementId: 'US_CCR_ANNUAL_LEGAL_ENFORCEABILITY_REVIEW', ruleId: 'RULE_US_ANNUAL_LEGAL_REVIEW'}
] AS row
MATCH (requirement:RegulatoryRequirement {regulatoryRequirementId: row.requirementId}),
      (rule:ApplicabilityRule {applicabilityRuleId: row.ruleId})
MERGE (requirement)-[:HAS_APPLICABILITY_RULE]->(rule);

UNWIND [
  {requirementId: 'BASEL_CRE52_SA_CCR_SCOPE', measureIds: ['REPLACEMENT_COST', 'POTENTIAL_FUTURE_EXPOSURE', 'EXPOSURE_AT_DEFAULT']},
  {requirementId: 'EU_CRR_ARTICLE_271_EXPOSURE_VALUE', measureIds: ['REPLACEMENT_COST', 'POTENTIAL_FUTURE_EXPOSURE', 'EXPOSURE_AT_DEFAULT']},
  {requirementId: 'US_CCR_AGGREGATE_EXPOSURE_METRICS', measureIds: ['REPLACEMENT_COST', 'POTENTIAL_FUTURE_EXPOSURE', 'CREDIT_VALUATION_ADJUSTMENT', 'DOLLAR_VALUE_OF_ONE_BASIS_POINT', 'STRESSED_EXPOSURE']}
] AS row
MATCH (requirement:RegulatoryRequirement {regulatoryRequirementId: row.requirementId})
UNWIND row.measureIds AS measureId
MATCH (definition:RiskMeasureDefinition {riskMeasureDefinitionId: measureId})
MERGE (requirement)-[:REQUIRES_RISK_MEASURE]->(definition);

MERGE (policy:InternalPolicy {internalPolicyId: 'POLICY_COUNTERPARTY_RISK_001'})
SET policy.name = 'Counterparty risk measurement and netting policy',
    policy.version = '2026.1',
    policy.status = 'Approved POC representation',
    policy.summary = 'Defines counterparty exposure measurement, netting recognition, legal opinion currency, and escalation expectations.';

UNWIND [
  {controlId: 'CONTROL_DAILY_SA_CCR_CALCULATION', name: 'Daily SA-CCR calculation and source reconciliation', controlType: 'Automated preventive and detective', frequency: 'Daily', ownerId: 'COUNTERPARTY_CREDIT_RISK'},
  {controlId: 'CONTROL_ANNUAL_NETTING_OPINION_REVIEW', name: 'Annual netting legal opinion currency review', controlType: 'Manual detective', frequency: 'Annual', ownerId: 'LEGAL_NETTING'},
  {controlId: 'CONTROL_CCR_TO_FINANCE_RECONCILIATION', name: 'CCR replacement cost to finance carrying-value comparison', controlType: 'Automated detective', frequency: 'Daily', ownerId: 'FINANCE_CONTROL'}
] AS row
MERGE (control:Control {controlId: row.controlId})
SET control.name = row.name,
    control.controlType = row.controlType,
    control.frequency = row.frequency,
    control.status = 'Active POC representation'
WITH control, row
MATCH (owner:OrganizationalUnit {organizationalUnitId: row.ownerId}),
      (policy:InternalPolicy {internalPolicyId: 'POLICY_COUNTERPARTY_RISK_001'})
MERGE (policy)-[:IMPLEMENTED_BY_CONTROL]->(control)
MERGE (control)-[:OWNED_BY_ORGANIZATIONAL_UNIT]->(owner);

UNWIND [
  {policyId: 'POLICY_COUNTERPARTY_RISK_001', requirementId: 'EU_CRR_ARTICLE_271_EXPOSURE_VALUE'},
  {policyId: 'POLICY_COUNTERPARTY_RISK_001', requirementId: 'UK_PRA_2027_NETTING_LEGAL_OPINION'},
  {policyId: 'POLICY_COUNTERPARTY_RISK_001', requirementId: 'US_CCR_AGGREGATE_EXPOSURE_METRICS'},
  {policyId: 'POLICY_COUNTERPARTY_RISK_001', requirementId: 'US_CCR_ANNUAL_LEGAL_ENFORCEABILITY_REVIEW'}
] AS row
MATCH (policy:InternalPolicy {internalPolicyId: row.policyId}),
      (requirement:RegulatoryRequirement {regulatoryRequirementId: row.requirementId})
MERGE (policy)-[:INTERPRETS_REGULATORY_REQUIREMENT]->(requirement);

UNWIND [
  {controlId: 'CONTROL_DAILY_SA_CCR_CALCULATION', measureIds: ['REPLACEMENT_COST', 'POTENTIAL_FUTURE_EXPOSURE', 'EXPOSURE_AT_DEFAULT']},
  {controlId: 'CONTROL_CCR_TO_FINANCE_RECONCILIATION', measureIds: ['REPLACEMENT_COST']}
] AS row
MATCH (control:Control {controlId: row.controlId})
UNWIND row.measureIds AS measureId
MATCH (definition:RiskMeasureDefinition {riskMeasureDefinitionId: measureId})
MERGE (control)-[:VALIDATES_RISK_MEASURE]->(definition);

UNWIND [
  {evidenceArtifactId: 'EVIDENCE_CCR_RUN_2026_06_30', name: 'CCR calculation completion and reconciliation evidence', evidenceType: 'System-generated control evidence', generatedAt: datetime('2026-07-01T04:00:00Z'), controlId: 'CONTROL_DAILY_SA_CCR_CALCULATION'},
  {evidenceArtifactId: 'EVIDENCE_LEGAL_OPINION_REGISTER_2026_06_30', name: 'Netting legal opinion currency register', evidenceType: 'Control report', generatedAt: datetime('2026-07-01T05:00:00Z'), controlId: 'CONTROL_ANNUAL_NETTING_OPINION_REVIEW'},
  {evidenceArtifactId: 'EVIDENCE_CCR_FINANCE_COMPARE_2026_06_30', name: 'CCR versus finance comparison report', evidenceType: 'System-generated reconciliation', generatedAt: datetime('2026-07-01T05:30:00Z'), controlId: 'CONTROL_CCR_TO_FINANCE_RECONCILIATION'}
] AS row
MERGE (evidence:EvidenceArtifact {evidenceArtifactId: row.evidenceArtifactId})
SET evidence.name = row.name,
    evidence.evidenceType = row.evidenceType,
    evidence.generatedAt = row.generatedAt,
    evidence.retentionClass = 'POC only',
    evidence.sampleDataClassification = 'Synthetic POC data'
WITH evidence, row
MATCH (control:Control {controlId: row.controlId}),
      (grc:SourceSystem {sourceSystemId: 'GRC_PLATFORM'})
MERGE (control)-[:PRODUCES_EVIDENCE_ARTIFACT]->(evidence)
MERGE (evidence)-[:ORIGINATES_FROM_SOURCE_SYSTEM {sourceRecordId: row.evidenceArtifactId, dataQualityStatus: 'Synthetic POC'}]->(grc);

UNWIND [
  {assessmentId: 'ASSESSMENT_EU_EXPOSURE_DE_2026_06_30', requirementId: 'EU_CRR_ARTICLE_271_EXPOSURE_VALUE', ruleId: 'RULE_EU_DERIVATIVE_EXPOSURE', legalEntityId: 'DB_AG', nettingSetId: 'NETTING_SET_DE_001', status: 'Compliant', conclusion: 'Required exposure measures were produced and linked to source lineage.', evidenceId: 'EVIDENCE_CCR_RUN_2026_06_30', measurementIds: ['MEASURE_RC_DE_2026_06_30', 'MEASURE_PFE_DE_2026_06_30', 'MEASURE_EAD_DE_2026_06_30']},
  {assessmentId: 'ASSESSMENT_US_AGGREGATION_2026_06_30', requirementId: 'US_CCR_AGGREGATE_EXPOSURE_METRICS', ruleId: 'RULE_US_CCR_EXPOSURE_AGGREGATION', legalEntityId: 'DB_NEW_YORK_BRANCH_POC', nettingSetId: 'NETTING_SET_US_001', status: 'Compliant', conclusion: 'Current, potential, stressed, CVA, and sensitivity measures are connected for the counterparty.', evidenceId: 'EVIDENCE_CCR_RUN_2026_06_30', measurementIds: ['MEASURE_RC_US_2026_06_30', 'MEASURE_PFE_US_2026_06_30', 'MEASURE_CVA_US_2026_06_30', 'MEASURE_STRESS_US_2026_06_30', 'MEASURE_DELTA_US_2026_06_30']},
  {assessmentId: 'ASSESSMENT_US_LEGAL_REVIEW_2026_06_30', requirementId: 'US_CCR_ANNUAL_LEGAL_ENFORCEABILITY_REVIEW', ruleId: 'RULE_US_ANNUAL_LEGAL_REVIEW', legalEntityId: 'DB_NEW_YORK_BRANCH_POC', nettingSetId: 'NETTING_SET_US_001', status: 'NonCompliant', conclusion: 'The linked US legal opinion review date has expired.', evidenceId: 'EVIDENCE_LEGAL_OPINION_REGISTER_2026_06_30', measurementIds: []}
] AS row
MERGE (assessment:ComplianceAssessment {complianceAssessmentId: row.assessmentId})
SET assessment.asOfDate = date('2026-06-30'),
    assessment.status = row.status,
    assessment.conclusion = row.conclusion,
    assessment.assessor = 'Synthetic POC workflow',
    assessment.sampleDataClassification = 'Synthetic POC data'
WITH assessment, row
MATCH (requirement:RegulatoryRequirement {regulatoryRequirementId: row.requirementId}),
      (rule:ApplicabilityRule {applicabilityRuleId: row.ruleId}),
      (entity:LegalEntity {legalEntityId: row.legalEntityId}),
      (nettingSet:NettingSet {nettingSetId: row.nettingSetId}),
      (evidence:EvidenceArtifact {evidenceArtifactId: row.evidenceId}),
      (grc:SourceSystem {sourceSystemId: 'GRC_PLATFORM'})
MERGE (assessment)-[:ASSESSES_REGULATORY_REQUIREMENT]->(requirement)
MERGE (assessment)-[:EVALUATED_USING_APPLICABILITY_RULE]->(rule)
MERGE (assessment)-[:APPLIES_TO_LEGAL_ENTITY]->(entity)
MERGE (assessment)-[:APPLIES_TO_NETTING_SET]->(nettingSet)
MERGE (assessment)-[:SUPPORTED_BY_EVIDENCE_ARTIFACT]->(evidence)
MERGE (assessment)-[:ORIGINATES_FROM_SOURCE_SYSTEM {sourceRecordId: row.assessmentId, dataQualityStatus: 'Synthetic POC'}]->(grc)
WITH assessment, row
UNWIND row.measurementIds AS measurementId
MATCH (measurement:RiskMeasurement {riskMeasurementId: measurementId})
MERGE (assessment)-[:ASSESSES_RISK_MEASUREMENT]->(measurement);

MERGE (gap:ComplianceGap {complianceGapId: 'GAP_US_LEGAL_OPINION_EXPIRED'})
SET gap.name = 'US netting legal opinion is past review date',
    gap.severity = 'High',
    gap.status = 'Open',
    gap.targetRemediationDate = date('2026-07-31'),
    gap.sampleDataClassification = 'Synthetic POC data';

MATCH (assessment:ComplianceAssessment {complianceAssessmentId: 'ASSESSMENT_US_LEGAL_REVIEW_2026_06_30'}),
      (gap:ComplianceGap {complianceGapId: 'GAP_US_LEGAL_OPINION_EXPIRED'}),
      (nettingSet:NettingSet {nettingSetId: 'NETTING_SET_US_001'}),
      (control:Control {controlId: 'CONTROL_ANNUAL_NETTING_OPINION_REVIEW'})
MERGE (assessment)-[:IDENTIFIES_COMPLIANCE_GAP]->(gap)
MERGE (gap)-[:AFFECTS_NETTING_SET]->(nettingSet)
MERGE (gap)-[:REQUIRES_REMEDIATION_CONTROL]->(control);

// -----------------------------------------------------------------------------
// Source documents and GraphRAG-ready chunks
// -----------------------------------------------------------------------------

UNWIND [
  {sourceDocumentId: 'DOC_BASEL_CRE52', title: 'Basel Framework CRE52', publisher: 'Bank for International Settlements', documentType: 'Global standard', sourceUrl: 'https://www.bis.org/basel_framework/chapter/CRE/52.htm', publicSource: true},
  {sourceDocumentId: 'DOC_EU_CRR_2019', title: 'EU CRR consolidated text 2019-01-01', publisher: 'EUR-Lex', documentType: 'EU regulation', sourceUrl: 'https://eur-lex.europa.eu/eli/reg/2013/575/2019-01-01/eng', publicSource: true},
  {sourceDocumentId: 'DOC_UK_PRA_CCR_2027', title: 'PRA Counterparty Credit Risk rules - 2027 implementation', publisher: 'Bank of England', documentType: 'PRA rulebook material', sourceUrl: 'https://www.bankofengland.co.uk/prudential-regulation/publication/2026/january/restatement-of-crr-requirements-final-policy-statement', publicSource: true},
  {sourceDocumentId: 'DOC_US_INTERAGENCY_CCR', title: 'Interagency Supervisory Guidance on Counterparty Credit Risk Management', publisher: 'Federal Reserve Board', documentType: 'Supervisory guidance', sourceUrl: 'https://www.federalreserve.gov/frrs/guidance/interagency-supervisory-guidance-on-counterparty-credit-risk-management.htm', publicSource: true},
  {sourceDocumentId: 'DOC_INTERNAL_SA_CCR_MODEL', title: 'SA-CCR model methodology and assumptions - POC', publisher: 'Internal synthetic POC', documentType: 'Model document', sourceUrl: 'document-repository://poc/sa-ccr-model-v1', publicSource: false},
  {sourceDocumentId: 'DOC_LEGAL_OPINION_DE_GB_POC', title: 'Germany and United Kingdom netting opinion - POC', publisher: 'Internal synthetic POC', documentType: 'Legal opinion', sourceUrl: 'document-repository://poc/legal-opinion-de-gb-2026', publicSource: false},
  {sourceDocumentId: 'DOC_LEGAL_OPINION_US_POC', title: 'United States netting opinion - expired POC example', publisher: 'Internal synthetic POC', documentType: 'Legal opinion', sourceUrl: 'document-repository://poc/legal-opinion-us-2024', publicSource: false}
] AS row
MERGE (document:SourceDocument {sourceDocumentId: row.sourceDocumentId})
SET document.title = row.title,
    document.publisher = row.publisher,
    document.documentType = row.documentType,
    document.sourceUrl = row.sourceUrl,
    document.publicSource = row.publicSource
WITH document, row
MATCH (repository:SourceSystem {sourceSystemId: 'DOCUMENT_REPOSITORY'})
MERGE (document)-[:STORED_IN_SOURCE_SYSTEM {sourceRecordId: row.sourceDocumentId}]->(repository);

UNWIND [
  {documentChunkId: 'CHUNK_BASEL_CRE52_SCOPE', sourceDocumentId: 'DOC_BASEL_CRE52', chunkIndex: 0, text: 'CRE52 describes the standardized approach for counterparty credit risk for OTC derivatives, exchange-traded derivatives, and long settlement transactions.'},
  {documentChunkId: 'CHUNK_BASEL_CRE52_NETTING', sourceDocumentId: 'DOC_BASEL_CRE52', chunkIndex: 1, text: 'Recognition of netting depends on a legally enforceable bilateral arrangement and written, reasoned legal review for the relevant jurisdictions.'},
  {documentChunkId: 'CHUNK_EU_CRR_ARTICLE_271', sourceDocumentId: 'DOC_EU_CRR_2019', chunkIndex: 0, text: 'Article 271 requires institutions to determine exposure value for derivative instruments under the counterparty credit risk chapter.'},
  {documentChunkId: 'CHUNK_UK_PRA_NETTING', sourceDocumentId: 'DOC_UK_PRA_CCR_2027', chunkIndex: 0, text: 'The PRA material requires written and reasoned legal opinions for the validity and enforceability of contractual netting under relevant jurisdictions.'},
  {documentChunkId: 'CHUNK_US_CCR_METRICS', sourceDocumentId: 'DOC_US_INTERAGENCY_CCR', chunkIndex: 0, text: 'The guidance calls for current, potential, stressed, CVA, sensitivity, and concentration views of counterparty exposure.'},
  {documentChunkId: 'CHUNK_US_CCR_LEGAL_REVIEW', sourceDocumentId: 'DOC_US_INTERAGENCY_CCR', chunkIndex: 1, text: 'The guidance calls for at least annual review of legal enforceability for collateral and netting agreements in relevant jurisdictions.'},
  {documentChunkId: 'CHUNK_INTERNAL_ALPHA', sourceDocumentId: 'DOC_INTERNAL_SA_CCR_MODEL', chunkIndex: 0, text: 'The POC SA-CCR implementation calculates exposure at default as alpha multiplied by replacement cost plus potential future exposure, with alpha set to 1.4.'},
  {documentChunkId: 'CHUNK_INTERNAL_MPOR', sourceDocumentId: 'DOC_INTERNAL_SA_CCR_MODEL', chunkIndex: 1, text: 'The POC assumes a ten-business-day margin period of risk for the daily-margined example netting sets.'},
  {documentChunkId: 'CHUNK_LEGAL_OPINION_DE_GB', sourceDocumentId: 'DOC_LEGAL_OPINION_DE_GB_POC', chunkIndex: 0, text: 'Synthetic POC opinion concludes that the example master agreement is enforceable in the modeled Germany and United Kingdom jurisdiction combination through 14 January 2027.'},
  {documentChunkId: 'CHUNK_LEGAL_OPINION_US', sourceDocumentId: 'DOC_LEGAL_OPINION_US_POC', chunkIndex: 0, text: 'Synthetic POC opinion for the United States example reached its review due date on 31 December 2025 and is marked expired.'}
] AS row
MERGE (chunk:DocumentChunk {documentChunkId: row.documentChunkId})
SET chunk.chunkIndex = row.chunkIndex,
    chunk.text = row.text,
    chunk.embeddingStatus = 'Not generated'
WITH chunk, row
MATCH (document:SourceDocument {sourceDocumentId: row.sourceDocumentId})
MERGE (document)-[:CONTAINS_DOCUMENT_CHUNK]->(chunk);

UNWIND [
  {fromId: 'CHUNK_BASEL_CRE52_SCOPE', toId: 'CHUNK_BASEL_CRE52_NETTING'},
  {fromId: 'CHUNK_US_CCR_METRICS', toId: 'CHUNK_US_CCR_LEGAL_REVIEW'},
  {fromId: 'CHUNK_INTERNAL_ALPHA', toId: 'CHUNK_INTERNAL_MPOR'}
] AS row
MATCH (from:DocumentChunk {documentChunkId: row.fromId}),
      (to:DocumentChunk {documentChunkId: row.toId})
MERGE (from)-[:NEXT_DOCUMENT_CHUNK]->(to);

UNWIND [
  {requirementId: 'BASEL_CRE52_SA_CCR_SCOPE', chunkId: 'CHUNK_BASEL_CRE52_SCOPE'},
  {requirementId: 'BASEL_CRE52_NETTING_LEGAL_REVIEW', chunkId: 'CHUNK_BASEL_CRE52_NETTING'},
  {requirementId: 'EU_CRR_ARTICLE_271_EXPOSURE_VALUE', chunkId: 'CHUNK_EU_CRR_ARTICLE_271'},
  {requirementId: 'UK_PRA_2027_NETTING_LEGAL_OPINION', chunkId: 'CHUNK_UK_PRA_NETTING'},
  {requirementId: 'US_CCR_AGGREGATE_EXPOSURE_METRICS', chunkId: 'CHUNK_US_CCR_METRICS'},
  {requirementId: 'US_CCR_ANNUAL_LEGAL_ENFORCEABILITY_REVIEW', chunkId: 'CHUNK_US_CCR_LEGAL_REVIEW'}
] AS row
MATCH (requirement:RegulatoryRequirement {regulatoryRequirementId: row.requirementId}),
      (chunk:DocumentChunk {documentChunkId: row.chunkId})
MERGE (requirement)-[:HAS_SOURCE_TEXT_IN_DOCUMENT_CHUNK]->(chunk);

UNWIND [
  {assumptionId: 'SA_CCR_ALPHA_1_4', chunkId: 'CHUNK_INTERNAL_ALPHA'},
  {assumptionId: 'SA_CCR_MARGIN_PERIOD_10D', chunkId: 'CHUNK_INTERNAL_MPOR'}
] AS row
MATCH (assumption:ModelAssumption {modelAssumptionId: row.assumptionId}),
      (chunk:DocumentChunk {documentChunkId: row.chunkId})
MERGE (assumption)-[:DOCUMENTED_IN_DOCUMENT_CHUNK]->(chunk);

UNWIND [
  {opinionId: 'LEGAL_OPINION_DE_GB_2026', chunkId: 'CHUNK_LEGAL_OPINION_DE_GB'},
  {opinionId: 'LEGAL_OPINION_US_2024', chunkId: 'CHUNK_LEGAL_OPINION_US'}
] AS row
MATCH (opinion:LegalOpinion {legalOpinionId: row.opinionId}),
      (chunk:DocumentChunk {documentChunkId: row.chunkId})
MERGE (opinion)-[:DOCUMENTED_IN_DOCUMENT_CHUNK]->(chunk);
