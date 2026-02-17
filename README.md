# dbt Streaming Platform — Medallion Architecture on Databricks

End-to-end implementation of the **Medallion Architecture** (Bronze → Silver → Gold) using **dbt Core** and **Databricks Unity Catalog** for a streaming platform with complete Databricks Asset Bundle deployment and GitHub Actions CI/CD.

---

## 📋 Table of Contents
- [Project Structure](#project-structure)
- [Architecture Overview](#architecture-overview)
- [Quick Start](#quick-start)
- [Layer Details](#layer-details)
- [Common dbt Commands](#common-dbt-commands)
- [Databricks Asset Bundle Deployment](#databricks-asset-bundle-deployment)
- [GitHub Actions CI/CD](#github-actions-cicd)
- [Configuration & Credentials](#configuration--credentials)
- [Local Development](#local-development)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)
- [Resources](#resources)

---

## Project Structure

```
dbt_streaming_db/
├── dbt_project.yml              # dbt project configuration
├── profiles.yml                 # Databricks connection (copy to ~/.dbt/)
├── packages.yml                 # dbt_utils + dbt_expectations
├── schema.yml                   # Sources, model docs & tests
├── databricks.yml               # Asset bundle configuration
│
├── seeds/                       # Raw CSV seed data
│   ├── raw_users.csv
│   ├── raw_shows.csv
│   ├── raw_watches.csv
│   └── raw_ratings.csv
│
├── macros/                      # Reusable SQL macros
│   ├── generate_custom_schema.sql   # Schema routing macro
│   └── generate_record_hash.sql     # MD5 hash helper
│
├── models/
│   ├── 010_bronze/              # Raw ingestion — light curation + audit cols
│   │   ├── bronze_users.sql
│   │   ├── bronze_shows.sql
│   │   ├── bronze_watches.sql
│   │   └── bronze_ratings.sql
│   │
│   ├── 020_silver/              # Cleaned, validated, type-cast
│   │   ├── silver_users.sql
│   │   ├── silver_shows.sql
│   │   ├── silver_watches.sql
│   │   └── silver_ratings.sql
│   │
│   └── 030_gold/                # Business-level facts & dimensions
│       ├── dim_shows.sql
│       ├── fct_watches.sql
│       └── fct_ratings.sql
│
├── snapshots/
│   └── snap_users.sql           # SCD Type-2 on silver_users
│
├── tests/                       # Data quality tests
│   ├── assert_completed_watches_have_ratings.sql
│   ├── assert_completion_pct_valid.sql
│   ├── assert_fct_watches_valid_ratings.sql
│   └── assert_ratings_valid_range.sql
│
├── analyses/                    # Ad-hoc analytics queries
│   ├── monthly_viewing_trend.sql
│   ├── show_ratings_by_genre.sql
│   └── top_users_by_engagement.sql
│
├── notebooks/                   # Databricks notebooks for job execution
│   ├── dbt_seed.py
│   ├── dbt_run_bronze.py
│   ├── dbt_run_silver.py
│   ├── dbt_snapshot.py
│   ├── dbt_run_gold.py
│   └── dbt_test.py
│
├── .github/workflows/
│   └── deploy.yml               # GitHub Actions CI/CD pipeline
│
├── setup.sh / setup.bat         # Automated local setup scripts
├── requirements.txt             # Python dependencies
├── .env.example                 # Environment template
├── .gitignore                   # Git configuration
└── README.md                    # This file
```

---

## Architecture Overview

```
Source CSVs (seeds)
      │
      ▼
┌─────────────────────────────────────────┐
│  BRONZE  (streaming_dev.bronze.*)       │
│  • Raw data, no transformation          │
│  • Audit cols: _loaded_at, _source,     │
│    _row_hash                            │
└──────────────────┬──────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────┐
│  SILVER  (streaming_dev.silver.*)       │
│  • Type casting & null filtering        │
│  • String normalisation (trim/upper)    │
│  • Derived: rating_sentiment            │
│  • Referential integrity tests          │
└──────────────────┬──────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────┐
│  GOLD    (streaming_dev.gold.*)         │
│  • dim_shows     — quality_tier, length │
│  • fct_watches   — views/completion     │
│  • fct_ratings   — enriched reviews     │
└─────────────────────────────────────────┘
```

**Unity Catalog three-level namespace:**
```
<catalog>.<schema>.<table>
 streaming_dev.bronze.bronze_users
 streaming_dev.silver.silver_watches
 streaming_dev.gold.fct_ratings
```

---

## Quick Start

### 1. Prerequisites

- **Databricks Account**: Access to workspace
- **Python 3.9+**: For dbt
- **Databricks CLI**: v0.200.0+ (for Asset Bundle deployment)
- **GitHub Account**: For CI/CD (optional for local dev)

### 2. Install Required Tools

```bash
pip install -r requirements.txt
```

### 3. Automated Local Setup

```bash
# Linux/macOS
chmod +x setup.sh
./setup.sh

# Windows
setup.bat
```

### 4. Manual Configuration

```bash
mkdir -p ~/.dbt
cp profiles.yml ~/.dbt/
# Edit ~/.dbt/profiles.yml with your credentials
```

### 5. Create Databricks Resources

```sql
CREATE CATALOG IF NOT EXISTS streaming_dev;
CREATE SCHEMA IF NOT EXISTS streaming_dev.bronze;
CREATE SCHEMA IF NOT EXISTS streaming_dev.silver;
CREATE SCHEMA IF NOT EXISTS streaming_dev.gold;
```

### 6. Run dbt Pipeline

```bash
dbt seed --profiles-dir ~/.dbt
dbt run --profiles-dir ~/.dbt
dbt test --profiles-dir ~/.dbt
dbt docs generate --profiles-dir ~/.dbt
dbt docs serve --profiles-dir ~/.dbt
```

---

## Layer Details

### 🟤 Bronze — Raw Ingestion

| Model | Source | Transformations |
|---|---|---|
| `bronze_users` | `raw_users.csv` | Add audit columns (_loaded_at, _source, _row_hash) |
| `bronze_shows` | `raw_shows.csv` | Add audit columns |
| `bronze_watches` | `raw_watches.csv` | Add audit columns |
| `bronze_ratings` | `raw_ratings.csv` | Add audit columns |

### 🩶 Silver — Cleaned & Validated

| Model | Key Transformations |
|---|---|
| `silver_users` | Trim, initcap name, lowercase email, uppercase country, drop nulls |
| `silver_shows` | Type cast, validate rating_avg 0-5 |
| `silver_watches` | Lowercase status, cast date, validate completion_pct 0-1 |
| `silver_ratings` | Type cast, validate rating 1-5, compute sentiment (Positive/Neutral) |

### 🟡 Gold — Business-Ready

| Model | Purpose |
|---|---|
| `dim_shows` | Show dimension with quality_tier and series_length |
| `fct_watches` | Watch facts with completion, ratings, time dimensions |
| `fct_ratings` | Enriched ratings with show, watch, and user context |

---

## Common dbt Commands

### Run Models by Layer

```bash
# Bronze layer
dbt run --select "010_bronze" --profiles-dir ~/.dbt

# Silver layer
dbt run --select "020_silver" --profiles-dir ~/.dbt

# Gold layer
dbt run --select "030_gold" --profiles-dir ~/.dbt

# All layers
dbt run --profiles-dir ~/.dbt

# Specific model
dbt run --select "silver_users" --profiles-dir ~/.dbt
```

### Testing & Validation

```bash
# All tests
dbt test --profiles-dir ~/.dbt

# By layer
dbt test --select "silver" --profiles-dir ~/.dbt

# By model
dbt test --select "fct_watches" --profiles-dir ~/.dbt

# Verbose output
dbt test -v --profiles-dir ~/.dbt
```

### Snapshots (SCD Type-2)

```bash
dbt snapshot --profiles-dir ~/.dbt
dbt snapshot --select "snap_users" --profiles-dir ~/.dbt
```

### Documentation

```bash
dbt docs generate --profiles-dir ~/.dbt
dbt docs serve --profiles-dir ~/.dbt
# Opens: http://localhost:8000
```

### Parsing & Validation

```bash
dbt parse --profiles-dir ~/.dbt
dbt debug --profiles-dir ~/.dbt
dbt compile --profiles-dir ~/.dbt
dbt ls --profiles-dir ~/.dbt
```

---

## Databricks Asset Bundle Deployment

### Prerequisites

1. **Databricks CLI v0.200.0+**
   ```bash
   curl https://raw.githubusercontent.com/databricks/databricks-cli/db-connect/install.sh | sh
   ```

2. **Databricks Resources**: Catalog, schemas, and cluster configured

3. **Environment Variables**
   ```bash
   export DATABRICKS_HOST="https://adb-<workspace-id>.azuredatabricks.net"
   export DATABRICKS_TOKEN="dapi<your-token>"
   export DBT_CLUSTER_ID="<cluster-id>"
   export ALERT_EMAIL="<email@example.com>"
   ```

### Create Databricks Resources

```sql
-- Create catalogs
CREATE CATALOG IF NOT EXISTS streaming_dev;
CREATE CATALOG IF NOT EXISTS streaming_prod;

-- Create schemas
CREATE SCHEMA IF NOT EXISTS streaming_dev.bronze;
CREATE SCHEMA IF NOT EXISTS streaming_dev.silver;
CREATE SCHEMA IF NOT EXISTS streaming_dev.gold;
```

### Create Compute Cluster

- **Name**: dbt-cluster
- **Runtime**: 13.3 LTS Scala 2.12
- **Worker Type**: i3.xlarge
- **Min Workers**: 1, Max Workers: 8
- **Auto-termination**: 30 minutes

### Deploy Bundle

```bash
# Validate
databricks bundle validate

# Deploy to dev
databricks bundle deploy --target dev

# Deploy to prod
databricks bundle deploy --target prod
```

### Run Jobs

```bash
# List jobs
databricks jobs list

# Run job
databricks jobs run-now --job-id <job-id>

# View history
databricks jobs list-runs --job-id <job-id>
```

---

## GitHub Actions CI/CD

### Setup GitHub Secrets

Go to repository → Settings → Secrets and variables → Actions

| Secret | Value |
|---|---|
| DATABRICKS_HOST | `https://adb-<workspace-id>.azuredatabricks.net` |
| DATABRICKS_TOKEN | Your PAT token |
| DATABRICKS_HTTP_PATH | `/sql/1.0/warehouses/<warehouse-id>` |
| DBT_CLUSTER_ID | Your cluster ID |
| ALERT_EMAIL | Your email |

### CI/CD Workflow

```
PR → Lint & Test
  ↓
Approve & Merge
  ↓
Push to develop → Deploy to Dev
  ↓
Push to main → Deploy to Prod (with approval)
```

### Triggers

- **Pull Request**: Lint and test only
- **Push to develop**: Deploy to dev
- **Push to main**: Deploy to prod

---

## Configuration & Credentials

### Environment Variables

```bash
# Databricks
export DATABRICKS_HOST="https://adb-<workspace-id>.azuredatabricks.net"
export DATABRICKS_TOKEN="dapi<your-token>"
export DATABRICKS_HTTP_PATH="/sql/1.0/warehouses/<warehouse-id>"

# dbt & Deployment
export DBT_CLUSTER_ID="<cluster-id>"
export ALERT_EMAIL="<email@example.com>"
```

### .env File

```bash
cp .env.example .env
# Edit with your values
```

### dbt Profiles (~/.dbt/profiles.yml)

```yaml
databricks_medallion:
  target: dev
  outputs:
    dev:
      type: databricks
      method: http
      catalog: streaming_dev
      schema: default
      host: your-workspace.azuredatabricks.net
      http_path: /sql/1.0/warehouses/your-warehouse-id
      token: "{{ env_var('DATABRICKS_TOKEN') }}"
      threads: 4
```

---

## Local Development

### Setup

```bash
# Clone and setup
git clone <repo>
cd <repo>

# Create virtual environment
python -m venv venv
source venv/bin/activate  # or venv\Scripts\activate on Windows

# Install dependencies
pip install -r requirements.txt

# Or use setup script
./setup.sh
```

### Run Models

```bash
# Test connection
dbt debug --profiles-dir ~/.dbt

# Build pipeline
dbt seed --profiles-dir ~/.dbt
dbt run --profiles-dir ~/.dbt
dbt test --profiles-dir ~/.dbt

# Before pushing
dbt build --profiles-dir ~/.dbt
```

### Git Workflow

```bash
# Create feature branch
git checkout -b feature/new-model

# Make changes and test
dbt build --profiles-dir ~/.dbt

# Commit with descriptive message
git commit -m "feat: add watch completion trend analysis"

# Push and create PR
git push origin feature/new-model
```

---

## Troubleshooting

### dbt Errors

**"Target profile name dev not found"**
```bash
mkdir -p ~/.dbt
cp profiles.yml ~/.dbt/
```

**"Catalog not found"**
```sql
CREATE CATALOG IF NOT EXISTS streaming_dev;
```

**"Cluster not found"**
```bash
databricks clusters list
export DBT_CLUSTER_ID="<correct-id>"
```

**"Model selection returned no results"**
```bash
dbt parse
dbt ls
```

### Databricks Issues

**Authentication failed**
```bash
export DATABRICKS_HOST="https://adb-<workspace-id>.azuredatabricks.net"
export DATABRICKS_TOKEN="dapi<your-token>"
dbt debug --profiles-dir ~/.dbt
```

**Test failures**
```bash
dbt test --select "test_name" -v --profiles-dir ~/.dbt
```

### GitHub Actions Issues

- Check workflow logs in Actions tab
- Verify all GitHub secrets are set
- Ensure Databricks resources exist
- Check cluster is running

---

## Best Practices

### Development

1. **Test locally before pushing**
   ```bash
   dbt build --profiles-dir ~/.dbt
   ```

2. **Use feature branches**
   ```bash
   git checkout -b feature/streaming-analytics
   ```

3. **Descriptive commit messages**
   - `feat: add monthly viewing trend analysis`
   - `fix: correct watch completion calculation`
   - `docs: update model descriptions`

4. **Document models in YAML**
   ```yaml
   - name: fct_watches
     description: "Fact table for viewing sessions"
     columns:
       - name: watch_id
         tests: [not_null, unique]
   ```

5. **Full build before production**
   ```bash
   dbt build --fail-fast
   ```

### Testing

- Add tests for critical models
- Use schema tests in YAML
- Create SQL tests for complex logic
- Run tests before every commit

### Production

- Monitor job execution logs daily
- Update dbt packages monthly
- Review and optimize slow models
- Use GitHub environment approval for prod

---

## Resources

### Official Documentation
- [dbt Documentation](https://docs.getdbt.com/)
- [dbt + Databricks](https://docs.getdbt.com/reference/warehouse-setups/databricks-setup)
- [Databricks Asset Bundles](https://docs.databricks.com/en/dev-tools/bundles/index.html)
- [GitHub Actions](https://docs.github.com/en/actions)

### Databricks Resources
- [Medallion Architecture](https://www.databricks.com/glossary/medallion-architecture)
- [Unity Catalog](https://docs.databricks.com/en/data-governance/unity-catalog/index.html)
- [Databricks Jobs](https://docs.databricks.com/en/workflows/jobs/index.html)

---

**Version**: 1.0.0 | **Last Updated**: February 2026
