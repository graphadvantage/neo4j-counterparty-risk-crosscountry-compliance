// POC demonstration queries. Each statement is independent and APOC-free.

// -----------------------------------------------------------------------------
// 1. Global-to-local requirement map across jurisdictions
// -----------------------------------------------------------------------------

MATCH (localInstrument:RegulatoryInstrument)-[:CONTAINS_REGULATORY_REQUIREMENT]->(localRequirement:RegulatoryRequirement)
MATCH (localRequirement)-[mapping:LOCALLY_IMPLEMENTS_REQUIREMENT]->(globalRequirement:RegulatoryRequirement)
MATCH (globalInstrument:RegulatoryInstrument)-[:CONTAINS_REGULATORY_REQUIREMENT]->(globalRequirement)
MATCH (localInstrument)-[:APPLIES_IN_JURISDICTION]->(jurisdiction:Jurisdiction)
RETURN globalInstrument.name AS globalStandard,
       globalRequirement.referenceCode AS globalReference,
       globalRequirement.title AS globalRequirement,
       jurisdiction.name AS localJurisdiction,
       localInstrument.name AS localInstrument,
       localRequirement.referenceCode AS localReference,
       localRequirement.title AS localRequirement,
       mapping.mappingStatus AS mappingStatus,
       mapping.mappingRationale AS mappingRationale
ORDER BY globalReference, localJurisdiction;

// -----------------------------------------------------------------------------
// 2. Requirement-to-control-to-evidence traceability
// Parameter: :param requirementId => 'EU_CRR_ARTICLE_271_EXPOSURE_VALUE';
// -----------------------------------------------------------------------------

MATCH (requirement:RegulatoryRequirement {regulatoryRequirementId: $requirementId})
MATCH (instrument:RegulatoryInstrument)-[:CONTAINS_REGULATORY_REQUIREMENT]->(requirement)
OPTIONAL MATCH (policy:InternalPolicy)-[:INTERPRETS_REGULATORY_REQUIREMENT]->(requirement)
OPTIONAL MATCH (policy)-[:IMPLEMENTED_BY_CONTROL]->(control:Control)
OPTIONAL MATCH (control)-[:PRODUCES_EVIDENCE_ARTIFACT]->(evidence:EvidenceArtifact)
OPTIONAL MATCH (assessment:ComplianceAssessment)-[:ASSESSES_REGULATORY_REQUIREMENT]->(requirement)
OPTIONAL MATCH (assessment)-[:APPLIES_TO_NETTING_SET]->(nettingSet:NettingSet)
OPTIONAL MATCH (assessment)-[:SUPPORTED_BY_EVIDENCE_ARTIFACT]->(assessmentEvidence:EvidenceArtifact)
RETURN instrument.name AS regulatoryInstrument,
       requirement.referenceCode AS referenceCode,
       requirement.title AS requirement,
       collect(DISTINCT policy.name) AS internalPolicies,
       collect(DISTINCT control.name) AS controls,
       collect(DISTINCT coalesce(evidence.name, assessmentEvidence.name)) AS evidence,
       collect(DISTINCT {
         assessmentId: assessment.complianceAssessmentId,
         status: assessment.status,
         nettingSetId: nettingSet.nettingSetId,
         conclusion: assessment.conclusion
       }) AS assessments;

// -----------------------------------------------------------------------------
// 3. Counterparty-group EAD across countries and comparison with limit
// Parameter: :param counterpartyGroupId => 'NORTHSTAR_GROUP_POC';
// -----------------------------------------------------------------------------

MATCH (group:CounterpartyGroup {counterpartyGroupId: $counterpartyGroupId})
MATCH (counterparty:LegalEntity)-[:IS_MEMBER_OF_COUNTERPARTY_GROUP]->(group)
MATCH (nettingSet:NettingSet)-[:HAS_COUNTERPARTY_LEGAL_ENTITY]->(counterparty)
MATCH (measurement:RiskMeasurement)-[:MEASURES_NETTING_SET]->(nettingSet)
MATCH (measurement)-[:USES_RISK_MEASURE_DEFINITION]->(definition:RiskMeasureDefinition {riskMeasureDefinitionId: 'EXPOSURE_AT_DEFAULT'})
MATCH (measurement)-[:DENOMINATED_IN_CURRENCY]->(currency:Currency)
MATCH (nettingSet)-[:OPERATES_UNDER_JURISDICTION]->(jurisdiction:Jurisdiction)
WITH group, currency,
     sum(measurement.value) AS aggregateEad,
     collect({
       counterparty: counterparty.legalName,
       jurisdiction: jurisdiction.name,
       nettingSetId: nettingSet.nettingSetId,
       ead: measurement.value
     }) AS exposureBreakdown
OPTIONAL MATCH (limit:RiskLimit)-[:LIMITS_COUNTERPARTY_GROUP]->(group)
OPTIONAL MATCH (limit)-[:DENOMINATED_IN_CURRENCY]->(limitCurrency:Currency)
RETURN group.name AS counterpartyGroup,
       aggregateEad,
       currency.code AS exposureCurrency,
       limit.thresholdValue AS limitValue,
       limitCurrency.code AS limitCurrency,
       CASE
         WHEN limit.thresholdValue IS NULL OR limit.thresholdValue = 0 THEN null
         ELSE round(100.0 * aggregateEad / limit.thresholdValue, 1)
       END AS limitUtilizationPercent,
       aggregateEad > limit.thresholdValue AS limitBreached,
       exposureBreakdown
ORDER BY exposureCurrency;

// -----------------------------------------------------------------------------
// 4. Cross-domain private-credit view: trading + market + credit + finance + GRC
// -----------------------------------------------------------------------------

MATCH (nettingSet:NettingSet)-[:CONTAINS_TRADE]->(trade:Trade {privateCreditIndicator: true})
MATCH (nettingSet)-[:HAS_COUNTERPARTY_LEGAL_ENTITY]->(counterparty:LegalEntity)
MATCH (trade)-[:HAS_PRODUCT_TYPE]->(productType:ProductType)
OPTIONAL MATCH (ead:RiskMeasurement)-[:MEASURES_NETTING_SET]->(nettingSet),
               (ead)-[:USES_RISK_MEASURE_DEFINITION]->(:RiskMeasureDefinition {riskMeasureDefinitionId: 'EXPOSURE_AT_DEFAULT'})
OPTIONAL MATCH (sensitivity:RiskMeasurement)-[:MEASURES_NETTING_SET]->(nettingSet),
               (sensitivity)-[:USES_RISK_MEASURE_DEFINITION]->(sensitivityDefinition:RiskMeasureDefinition)
               WHERE sensitivityDefinition.riskMeasureDefinitionId IN ['DELTA', 'DOLLAR_VALUE_OF_ONE_BASIS_POINT']
OPTIONAL MATCH (credit:CreditAssessment)-[:ASSESSES_LEGAL_ENTITY]->(counterparty)
OPTIONAL MATCH (balance:BalanceSheetPosition)-[:RELATES_TO_TRADE]->(trade)
OPTIONAL MATCH (compliance:ComplianceAssessment)-[:APPLIES_TO_NETTING_SET]->(nettingSet)
RETURN trade.tradeId AS tradeId,
       productType.name AS product,
       counterparty.legalName AS counterparty,
       credit.internalRating AS internalRating,
       credit.probabilityOfDefault AS probabilityOfDefault,
       ead.value AS exposureAtDefault,
       sensitivityDefinition.abbreviation AS sensitivityType,
       sensitivity.value AS sensitivityValue,
       balance.carryingValueAmount AS carryingValue,
       collect(DISTINCT {
         assessmentId: compliance.complianceAssessmentId,
         status: compliance.status
       }) AS complianceAssessments;

// -----------------------------------------------------------------------------
// 5. Netting sets with stale or missing jurisdictional legal opinions
// -----------------------------------------------------------------------------

MATCH (nettingSet:NettingSet)
OPTIONAL MATCH (nettingSet)-[:RELIES_ON_LEGAL_OPINION]->(opinion:LegalOpinion)
OPTIONAL MATCH (opinion)-[:COVERS_JURISDICTION]->(jurisdiction:Jurisdiction)
OPTIONAL MATCH (gap:ComplianceGap)-[:AFFECTS_NETTING_SET]->(nettingSet)
WITH nettingSet, opinion,
     collect(DISTINCT jurisdiction.name) AS coveredJurisdictions,
     collect(DISTINCT gap.name) AS complianceGaps
WHERE opinion IS NULL
   OR opinion.opinionStatus <> 'Current'
   OR opinion.reviewDueDate < date()
RETURN nettingSet.nettingSetId AS nettingSetId,
       nettingSet.name AS nettingSet,
       opinion.legalOpinionId AS legalOpinionId,
       opinion.opinionStatus AS opinionStatus,
       opinion.reviewDueDate AS reviewDueDate,
       coveredJurisdictions,
       complianceGaps
ORDER BY reviewDueDate;

// -----------------------------------------------------------------------------
// 6. Explain one EAD number from requirement to source systems and assumptions
// Parameter: :param measurementId => 'MEASURE_EAD_DE_2026_06_30';
// -----------------------------------------------------------------------------

MATCH (measurement:RiskMeasurement {riskMeasurementId: $measurementId})
MATCH (measurement)-[:USES_RISK_MEASURE_DEFINITION]->(definition:RiskMeasureDefinition)
MATCH (measurement)-[:MEASURES_NETTING_SET]->(nettingSet:NettingSet)
MATCH (measurement)-[:PRODUCED_BY_RISK_CALCULATION_RUN]->(run:RiskCalculationRun)
MATCH (run)-[:USES_RISK_MODEL]->(model:RiskModel)
OPTIONAL MATCH (model)-[:USES_MODEL_ASSUMPTION]->(assumption:ModelAssumption)
OPTIONAL MATCH (assumption)-[:DOCUMENTED_IN_DOCUMENT_CHUNK]->(assumptionChunk:DocumentChunk)
OPTIONAL MATCH (run)-[:READS_FROM_SOURCE_SYSTEM]->(inputSystem:SourceSystem)
OPTIONAL MATCH (assessment:ComplianceAssessment)-[:ASSESSES_RISK_MEASUREMENT]->(measurement)
OPTIONAL MATCH (assessment)-[:ASSESSES_REGULATORY_REQUIREMENT]->(requirement:RegulatoryRequirement)
OPTIONAL MATCH (requirement)-[:HAS_SOURCE_TEXT_IN_DOCUMENT_CHUNK]->(requirementChunk:DocumentChunk)
RETURN measurement.riskMeasurementId AS measurementId,
       definition.name AS measure,
       measurement.value AS value,
       measurement.asOfDate AS asOfDate,
       nettingSet.nettingSetId AS nettingSetId,
       run.riskCalculationRunId AS calculationRun,
       model.name AS model,
       collect(DISTINCT {
         name: assumption.name,
         value: assumption.assumptionValue,
         unit: assumption.unit,
         sourceText: assumptionChunk.text
       }) AS assumptions,
       collect(DISTINCT inputSystem.name) AS inputSystems,
       collect(DISTINCT {
         requirementId: requirement.regulatoryRequirementId,
         reference: requirement.referenceCode,
         title: requirement.title,
         sourceText: requirementChunk.text,
         assessmentStatus: assessment.status
       }) AS regulatoryTrace;

// -----------------------------------------------------------------------------
// 7. Impact analysis when a global or local requirement changes
// Parameter: :param changedRequirementId => 'BASEL_CRE52_NETTING_LEGAL_REVIEW';
// -----------------------------------------------------------------------------

MATCH (changed:RegulatoryRequirement {regulatoryRequirementId: $changedRequirementId})
OPTIONAL MATCH (local:RegulatoryRequirement)-[:LOCALLY_IMPLEMENTS_REQUIREMENT*1..2]->(changed)
WITH changed, [changed] + collect(DISTINCT local) AS impactedRequirements
UNWIND impactedRequirements AS requirement
WITH changed, requirement
WHERE requirement IS NOT NULL
OPTIONAL MATCH (policy:InternalPolicy)-[:INTERPRETS_REGULATORY_REQUIREMENT]->(requirement)
OPTIONAL MATCH (policy)-[:IMPLEMENTED_BY_CONTROL]->(control:Control)
OPTIONAL MATCH (assessment:ComplianceAssessment)-[:ASSESSES_REGULATORY_REQUIREMENT]->(requirement)
OPTIONAL MATCH (assessment)-[:APPLIES_TO_NETTING_SET]->(nettingSet:NettingSet)
OPTIONAL MATCH (nettingSet)-[:HAS_COUNTERPARTY_LEGAL_ENTITY]->(counterparty:LegalEntity)
OPTIONAL MATCH (gap:ComplianceGap)-[:AFFECTS_NETTING_SET]->(nettingSet)
RETURN changed.title AS changedRequirement,
       requirement.regulatoryRequirementId AS impactedRequirementId,
       requirement.title AS impactedRequirement,
       collect(DISTINCT policy.name) AS impactedPolicies,
       collect(DISTINCT control.name) AS impactedControls,
       collect(DISTINCT nettingSet.nettingSetId) AS impactedNettingSets,
       collect(DISTINCT counterparty.legalName) AS impactedCounterparties,
       collect(DISTINCT gap.name) AS openGaps
ORDER BY impactedRequirementId;

// -----------------------------------------------------------------------------
// 8. GraphRAG lexical seed + deterministic graph expansion
// Parameter: :param searchText => 'netting legal opinion jurisdiction';
// -----------------------------------------------------------------------------

CALL db.index.fulltext.queryNodes('regulatory_text_search', $searchText)
YIELD node, score
WHERE node:RegulatoryRequirement
WITH node AS requirement, score
ORDER BY score DESC
LIMIT 5
OPTIONAL MATCH (instrument:RegulatoryInstrument)-[:CONTAINS_REGULATORY_REQUIREMENT]->(requirement)
OPTIONAL MATCH (requirement)-[:HAS_SOURCE_TEXT_IN_DOCUMENT_CHUNK]->(chunk:DocumentChunk)
OPTIONAL MATCH (document:SourceDocument)-[:CONTAINS_DOCUMENT_CHUNK]->(chunk)
OPTIONAL MATCH (assessment:ComplianceAssessment)-[:ASSESSES_REGULATORY_REQUIREMENT]->(requirement)
OPTIONAL MATCH (assessment)-[:APPLIES_TO_NETTING_SET]->(nettingSet:NettingSet)
OPTIONAL MATCH (nettingSet)-[:HAS_COUNTERPARTY_LEGAL_ENTITY]->(counterparty:LegalEntity)
OPTIONAL MATCH (assessment)-[:SUPPORTED_BY_EVIDENCE_ARTIFACT]->(evidence:EvidenceArtifact)
RETURN requirement.regulatoryRequirementId AS requirementId,
       requirement.title AS requirement,
       score,
       instrument.name AS instrument,
       collect(DISTINCT {
         sourceDocument: document.title,
         sourceUrl: document.sourceUrl,
         sourceText: chunk.text
       }) AS groundedSourceText,
       collect(DISTINCT {
         assessmentStatus: assessment.status,
         nettingSetId: nettingSet.nettingSetId,
         counterparty: counterparty.legalName,
         evidence: evidence.name
       }) AS operationalContext
ORDER BY score DESC;

// Optional vector start when document_chunk_embedding has been created and
// embeddings have been populated:
// CALL db.index.vector.queryNodes('document_chunk_embedding', 5, $queryEmbedding)
// YIELD node AS chunk, score
// MATCH (document:SourceDocument)-[:CONTAINS_DOCUMENT_CHUNK]->(chunk)
// OPTIONAL MATCH (requirement:RegulatoryRequirement)-[:HAS_SOURCE_TEXT_IN_DOCUMENT_CHUNK]->(chunk)
// RETURN chunk.text, score, document.title, document.sourceUrl,
//        requirement.regulatoryRequirementId, requirement.title;

// -----------------------------------------------------------------------------
// 9. Source-system lineage for risk and compliance facts
// -----------------------------------------------------------------------------

MATCH (measurement:RiskMeasurement)-[:PRODUCED_BY_RISK_CALCULATION_RUN]->(run:RiskCalculationRun)
MATCH (run)-[:READS_FROM_SOURCE_SYSTEM]->(inputSystem:SourceSystem)
MATCH (measurement)-[:MEASURES_NETTING_SET]->(nettingSet:NettingSet)
OPTIONAL MATCH (assessment:ComplianceAssessment)-[:ASSESSES_RISK_MEASUREMENT]->(measurement)
OPTIONAL MATCH (assessment)-[:ORIGINATES_FROM_SOURCE_SYSTEM]->(grcSystem:SourceSystem)
RETURN nettingSet.nettingSetId AS nettingSetId,
       measurement.riskMeasurementId AS measurementId,
       collect(DISTINCT inputSystem.name) AS riskInputSystems,
       collect(DISTINCT assessment.complianceAssessmentId) AS complianceAssessments,
       collect(DISTINCT grcSystem.name) AS complianceSourceSystems
ORDER BY nettingSetId, measurementId;
