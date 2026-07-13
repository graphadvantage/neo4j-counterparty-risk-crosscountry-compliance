// Counterparty risk + cross-jurisdiction compliance POC
// Target: Neo4j 5.26+ / AuraDB. All statements are idempotent.
// Naming: CamelCase labels, UPPER_SNAKE_CASE relationship types, camelCase properties.

// -----------------------------------------------------------------------------
// Business-key constraints
// -----------------------------------------------------------------------------

CREATE CONSTRAINT unique_country_code IF NOT EXISTS
FOR (node:Country) REQUIRE node.code IS UNIQUE;

CREATE CONSTRAINT unique_jurisdiction_id IF NOT EXISTS
FOR (node:Jurisdiction) REQUIRE node.jurisdictionId IS UNIQUE;

CREATE CONSTRAINT unique_regulatory_authority_id IF NOT EXISTS
FOR (node:RegulatoryAuthority) REQUIRE node.regulatoryAuthorityId IS UNIQUE;

CREATE CONSTRAINT unique_legal_entity_id IF NOT EXISTS
FOR (node:LegalEntity) REQUIRE node.legalEntityId IS UNIQUE;

CREATE CONSTRAINT unique_legal_entity_lei IF NOT EXISTS
FOR (node:LegalEntity) REQUIRE node.lei IS UNIQUE;

CREATE CONSTRAINT unique_counterparty_group_id IF NOT EXISTS
FOR (node:CounterpartyGroup) REQUIRE node.counterpartyGroupId IS UNIQUE;

CREATE CONSTRAINT unique_organizational_unit_id IF NOT EXISTS
FOR (node:OrganizationalUnit) REQUIRE node.organizationalUnitId IS UNIQUE;

CREATE CONSTRAINT unique_source_system_id IF NOT EXISTS
FOR (node:SourceSystem) REQUIRE node.sourceSystemId IS UNIQUE;

CREATE CONSTRAINT unique_portfolio_id IF NOT EXISTS
FOR (node:Portfolio) REQUIRE node.portfolioId IS UNIQUE;

CREATE CONSTRAINT unique_netting_set_id IF NOT EXISTS
FOR (node:NettingSet) REQUIRE node.nettingSetId IS UNIQUE;

CREATE CONSTRAINT unique_trade_id IF NOT EXISTS
FOR (node:Trade) REQUIRE node.tradeId IS UNIQUE;

CREATE CONSTRAINT unique_product_type_id IF NOT EXISTS
FOR (node:ProductType) REQUIRE node.productTypeId IS UNIQUE;

CREATE CONSTRAINT unique_master_agreement_id IF NOT EXISTS
FOR (node:MasterAgreement) REQUIRE node.masterAgreementId IS UNIQUE;

CREATE CONSTRAINT unique_collateral_agreement_id IF NOT EXISTS
FOR (node:CollateralAgreement) REQUIRE node.collateralAgreementId IS UNIQUE;

CREATE CONSTRAINT unique_legal_opinion_id IF NOT EXISTS
FOR (node:LegalOpinion) REQUIRE node.legalOpinionId IS UNIQUE;

CREATE CONSTRAINT unique_collateral_asset_id IF NOT EXISTS
FOR (node:CollateralAsset) REQUIRE node.collateralAssetId IS UNIQUE;

CREATE CONSTRAINT unique_collateral_position_id IF NOT EXISTS
FOR (node:CollateralPosition) REQUIRE node.collateralPositionId IS UNIQUE;

CREATE CONSTRAINT unique_currency_code IF NOT EXISTS
FOR (node:Currency) REQUIRE node.code IS UNIQUE;

CREATE CONSTRAINT unique_risk_factor_id IF NOT EXISTS
FOR (node:RiskFactor) REQUIRE node.riskFactorId IS UNIQUE;

CREATE CONSTRAINT unique_risk_measure_definition_id IF NOT EXISTS
FOR (node:RiskMeasureDefinition) REQUIRE node.riskMeasureDefinitionId IS UNIQUE;

CREATE CONSTRAINT unique_risk_measurement_id IF NOT EXISTS
FOR (node:RiskMeasurement) REQUIRE node.riskMeasurementId IS UNIQUE;

CREATE CONSTRAINT unique_risk_calculation_run_id IF NOT EXISTS
FOR (node:RiskCalculationRun) REQUIRE node.riskCalculationRunId IS UNIQUE;

CREATE CONSTRAINT unique_risk_model_id IF NOT EXISTS
FOR (node:RiskModel) REQUIRE node.riskModelId IS UNIQUE;

CREATE CONSTRAINT unique_model_assumption_id IF NOT EXISTS
FOR (node:ModelAssumption) REQUIRE node.modelAssumptionId IS UNIQUE;

CREATE CONSTRAINT unique_stress_scenario_id IF NOT EXISTS
FOR (node:StressScenario) REQUIRE node.stressScenarioId IS UNIQUE;

CREATE CONSTRAINT unique_risk_limit_id IF NOT EXISTS
FOR (node:RiskLimit) REQUIRE node.riskLimitId IS UNIQUE;

CREATE CONSTRAINT unique_credit_assessment_id IF NOT EXISTS
FOR (node:CreditAssessment) REQUIRE node.creditAssessmentId IS UNIQUE;

CREATE CONSTRAINT unique_balance_sheet_position_id IF NOT EXISTS
FOR (node:BalanceSheetPosition) REQUIRE node.balanceSheetPositionId IS UNIQUE;

CREATE CONSTRAINT unique_accounting_classification_id IF NOT EXISTS
FOR (node:AccountingClassification) REQUIRE node.accountingClassificationId IS UNIQUE;

CREATE CONSTRAINT unique_general_ledger_account_id IF NOT EXISTS
FOR (node:GeneralLedgerAccount) REQUIRE node.generalLedgerAccountId IS UNIQUE;

CREATE CONSTRAINT unique_regulatory_instrument_id IF NOT EXISTS
FOR (node:RegulatoryInstrument) REQUIRE node.regulatoryInstrumentId IS UNIQUE;

CREATE CONSTRAINT unique_regulatory_requirement_id IF NOT EXISTS
FOR (node:RegulatoryRequirement) REQUIRE node.regulatoryRequirementId IS UNIQUE;

CREATE CONSTRAINT unique_risk_topic_id IF NOT EXISTS
FOR (node:RiskTopic) REQUIRE node.riskTopicId IS UNIQUE;

CREATE CONSTRAINT unique_applicability_rule_id IF NOT EXISTS
FOR (node:ApplicabilityRule) REQUIRE node.applicabilityRuleId IS UNIQUE;

CREATE CONSTRAINT unique_internal_policy_id IF NOT EXISTS
FOR (node:InternalPolicy) REQUIRE node.internalPolicyId IS UNIQUE;

CREATE CONSTRAINT unique_control_id IF NOT EXISTS
FOR (node:Control) REQUIRE node.controlId IS UNIQUE;

CREATE CONSTRAINT unique_compliance_assessment_id IF NOT EXISTS
FOR (node:ComplianceAssessment) REQUIRE node.complianceAssessmentId IS UNIQUE;

CREATE CONSTRAINT unique_evidence_artifact_id IF NOT EXISTS
FOR (node:EvidenceArtifact) REQUIRE node.evidenceArtifactId IS UNIQUE;

CREATE CONSTRAINT unique_compliance_gap_id IF NOT EXISTS
FOR (node:ComplianceGap) REQUIRE node.complianceGapId IS UNIQUE;

CREATE CONSTRAINT unique_source_document_id IF NOT EXISTS
FOR (node:SourceDocument) REQUIRE node.sourceDocumentId IS UNIQUE;

CREATE CONSTRAINT unique_document_chunk_id IF NOT EXISTS
FOR (node:DocumentChunk) REQUIRE node.documentChunkId IS UNIQUE;

// -----------------------------------------------------------------------------
// Search-performance indexes
// -----------------------------------------------------------------------------

CREATE RANGE INDEX legal_entity_name IF NOT EXISTS
FOR (node:LegalEntity) ON (node.legalName);

CREATE RANGE INDEX legal_entity_status IF NOT EXISTS
FOR (node:LegalEntity) ON (node.entityStatus);

CREATE RANGE INDEX netting_set_status IF NOT EXISTS
FOR (node:NettingSet) ON (node.status);

CREATE RANGE INDEX trade_maturity_date IF NOT EXISTS
FOR (node:Trade) ON (node.maturityDate);

CREATE RANGE INDEX risk_measurement_as_of_date IF NOT EXISTS
FOR (node:RiskMeasurement) ON (node.asOfDate);

CREATE RANGE INDEX risk_calculation_run_as_of_date IF NOT EXISTS
FOR (node:RiskCalculationRun) ON (node.asOfDate);

CREATE RANGE INDEX compliance_assessment_status IF NOT EXISTS
FOR (node:ComplianceAssessment) ON (node.status);

CREATE RANGE INDEX compliance_assessment_as_of_date IF NOT EXISTS
FOR (node:ComplianceAssessment) ON (node.asOfDate);

CREATE RANGE INDEX regulatory_requirement_reference IF NOT EXISTS
FOR (node:RegulatoryRequirement) ON (node.referenceCode);

CREATE RANGE INDEX regulatory_requirement_effective_dates IF NOT EXISTS
FOR (node:RegulatoryRequirement) ON (node.effectiveFrom, node.effectiveTo);

CREATE RANGE INDEX source_lineage_record_id IF NOT EXISTS
FOR ()-[relationship:ORIGINATES_FROM_SOURCE_SYSTEM]-()
ON (relationship.sourceRecordId);

CREATE FULLTEXT INDEX regulatory_text_search IF NOT EXISTS
FOR (node:RegulatoryInstrument|RegulatoryRequirement|InternalPolicy|Control)
ON EACH [node.name, node.title, node.summary, node.requirementText, node.description];

CREATE FULLTEXT INDEX document_chunk_text_search IF NOT EXISTS
FOR (node:DocumentChunk) ON EACH [node.text];

// Optional GraphRAG vector index. Set dimensions to the embedding model in use,
// then uncomment. Example below assumes a 1536-dimensional embedding.
// CREATE VECTOR INDEX document_chunk_embedding IF NOT EXISTS
// FOR (node:DocumentChunk) ON (node.embedding)
// OPTIONS {indexConfig: {
//   `vector.dimensions`: 1536,
//   `vector.similarity_function`: 'cosine'
// }};

// -----------------------------------------------------------------------------
// Optional Enterprise-only existence checks
// -----------------------------------------------------------------------------

// CREATE CONSTRAINT risk_measurement_value_exists IF NOT EXISTS
// FOR (node:RiskMeasurement) REQUIRE node.value IS NOT NULL;
// CREATE CONSTRAINT requirement_text_exists IF NOT EXISTS
// FOR (node:RegulatoryRequirement) REQUIRE node.requirementText IS NOT NULL;
