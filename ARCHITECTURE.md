# Azure Data Analytics Platform - Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Azure Data Analytics Platform                     │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────┐
│   Source    │
│   Systems   │──┐
│ (SQL, APIs, │  │
│   Files)    │  │
└─────────────┘  │
                 │
                 ▼
        ┌────────────────┐
        │  Azure Data    │
        │    Factory     │◄──────────┐
        │  (Orchestrate) │           │
        └────────┬───────┘           │
                 │                    │
                 ▼                    │
    ┌────────────────────────┐       │
    │  Data Lake Storage Gen2│       │
    │  ┌──────────────────┐  │       │
    │  │ Landing Container│  │       │
    │  │  (Raw Data)      │  │       │
    │  └──────────┬───────┘  │       │
    │             │           │       │
    │             ▼           │       │
    │  ┌──────────────────┐  │       │
    │  │Azure Databricks  │  │       │
    │  │  - Clean Data    │◄─┼───────┘
    │  │  - Transform     │  │
    │  │  - Validate      │  │
    │  └──────────┬───────┘  │
    │             │           │
    │             ▼           │
    │  ┌──────────────────┐  │
    │  │ Interim Container│  │
    │  │ (Transformed)    │  │
    │  └──────────┬───────┘  │
    │             │           │
    │             ▼           │
    │  ┌──────────────────┐  │
    │  │Azure Databricks  │  │
    │  │  - Aggregate     │◄─┼───────┐
    │  │  - Enrich        │  │       │
    │  └──────────┬───────┘  │       │
    │             │           │       │
    │             ▼           │       │
    │  ┌──────────────────┐  │       │
    │  │Data Warehouse    │  │       │
    │  │Container         │  │       │
    │  │(Curated Data)    │  │       │
    │  └──────────┬───────┘  │       │
    │             │           │       │
    │  ┌──────────────────┐  │       │
    │  │Malformed         │  │       │
    │  │Container         │  │       │
    │  │(Error Data)      │  │       │
    │  └──────────────────┘  │       │
    └─────────────┬───────────┘       │
                  │                    │
                  ▼                    │
         ┌─────────────────┐          │
         │ Azure Synapse   │          │
         │   Analytics     │──────────┘
         │  (SQL Queries)  │
         └────────┬────────┘
                  │
                  ▼
         ┌─────────────────┐
         │  BI Tools &     │
         │  Dashboards     │
         │ (Power BI,      │
         │  Tableau)       │
         └─────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                         Supporting Services                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌─────────────────┐          ┌─────────────────┐                      │
│  │  Azure Key      │          │  Azure Monitor  │                      │
│  │  Vault          │          │  & Log Analytics│                      │
│  │  (Secrets)      │          │  (Monitoring)   │                      │
│  └─────────────────┘          └─────────────────┘                      │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘

Key Features:
━━━━━━━━━━━━━━
• Managed Identities for secure authentication
• Role-Based Access Control (RBAC)
• Automated data pipelines
• Scalable compute (Databricks clusters)
• Serverless SQL queries (Synapse)
• Multi-zone data storage (Landing, Interim, Warehouse, Malformed)
```

## Data Flow

1. **Ingestion**: Data Factory pulls from source systems → Landing container
2. **Validation**: Databricks reads Landing → validates → writes to Interim (good) and Malformed (bad)
3. **Transformation**: Databricks reads Interim → transforms → writes to Data Warehouse container
4. **Serving**: Synapse creates external tables on Data Warehouse container
5. **Consumption**: BI tools query Synapse SQL Pool for reports and dashboards

## Container Purposes

| Container | Purpose | Data State |
|-----------|---------|------------|
| **Landing** | Raw data ingestion from sources | Unvalidated, original format |
| **Malformed** | Invalid/error records for review | Failed validation checks |
| **Interim** | Validated and cleaned data | Passed validation, ready for transformation |
| **Data Warehouse** | Final curated datasets | Fully processed, analysis-ready |
