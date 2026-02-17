# Azure DevOps Pipelines Configuration

This file will be used as a reference for setting up CI/CD with Azure DevOps instead of GitHub Actions.

## Setup Instructions

### 1. Create Azure DevOps Project

```bash
# Navigate to your Azure DevOps organization
https://dev.azure.com/{organization}

# Create a new project or use existing one
```

### 2. Create Service Connection for Databricks

```bash
# In Azure DevOps:
# Project Settings → Service connections → New service connection
# Type: Databricks (if available) or Generic HTTP

# Fill in:
# - Name: Databricks
# - Server URL: https://adb-<workspace-id>.azuredatabricks.net
# - Authentication: Personal Access Token (PAT)
```

### 3. Create Variable Groups for Secrets

**Project Settings → Pipelines → Library → Add variable group**

```yaml
Variable Group: Databricks-Dev
- DATABRICKS_HOST: https://adb-<workspace-id>.azuredatabricks.net
- DATABRICKS_TOKEN: dapi... (mark as secret)
- DATABRICKS_HTTP_PATH: /sql/1.0/warehouses/<warehouse-id>

Variable Group: Databricks-Prod
- DATABRICKS_HOST: https://adb-<workspace-id>.azuredatabricks.net
- DATABRICKS_TOKEN: dapi... (mark as secret)
- DATABRICKS_HTTP_PATH: /sql/1.0/warehouses/<warehouse-id>
```

### 4. Create Pipeline from YAML

```bash
# In Azure DevOps:
# Pipelines → Create Pipeline
# Select: Azure Repos Git (or GitHub)
# Configure using existing YAML: azure-pipelines.yml
```

### 5. Create Environments for Approvals

**Pipelines → Environments**

```yaml
Environment: development
- No approvals required

Environment: production
- Add approval
- Approvers: <your team members>
```

### 6. Link Variable Groups to Pipeline

Edit `azure-pipelines.yml` to reference your variable groups:

```yaml
variables:
  - group: Databricks-Dev     # For dev stage
  - group: Databricks-Prod    # For prod stage
```

---

## Pipeline Triggers

| Event | Condition | Action |
|-------|-----------|--------|
| Push to `develop` | Always | Deploys to `streaming_dev` |
| Push to `main` | Always | Deploys to `streaming_prod` |
| Pull Request | Any branch | Runs lint + test |
| Manual | Any time | Queues pipeline |

---

## Stage Breakdown

### Stage 1: Lint
- ✅ Validates dbt project syntax
- ✅ Runs `dbt parse`, `dbt debug`, `dbt compile`
- ✅ Lists all models
- **Duration:** ~2-3 minutes
- **Runs:** Always (all branches)

### Stage 2: Test
- ✅ Loads seed data
- ✅ Runs all models
- ✅ Executes tests
- ✅ Generates documentation
- **Duration:** ~5-8 minutes
- **Runs:** Only on Pull Requests

### Stage 3: Deploy Dev
- ✅ Seeds data
- ✅ Runs full pipeline (seed → run → test)
- ✅ Generates docs
- **Duration:** ~7-10 minutes
- **Runs:** Push to `develop` branch only

### Stage 4: Deploy Prod
- ✅ Seeds data
- ✅ Runs full validated pipeline
- ✅ Generates docs
- **Duration:** ~10-15 minutes
- **Runs:** Push to `main` branch only
- **Approval:** Required from environment managers

### Stage 5: Cleanup
- ✅ Health check
- ✅ Build statistics summary
- **Duration:** ~1 minute
- **Runs:** Always (final stage regardless of previous results)

---

## Environment Variables

### Required (Add to Variable Groups)

```yaml
DATABRICKS_HOST
DATABRICKS_TOKEN (mark as secret)
DATABRICKS_HTTP_PATH
```

### Optional

```yaml
DBT_PROFILES_DIR        # Default: ~/.dbt
ALERT_EMAIL             # For notifications
```

---

## Deployment Strategy

### Development (develop branch)
```
develop → Build & Test → streaming_dev
   │
   └─→ No approval needed
   └─→ Auto-deploy on push
   └─→ Ephemeral environment
   └─→ Safe for testing
```

### Production (main branch)
```
main → Lint → Production Approval → Build & Deploy → streaming_prod
  │                                                      │
  └──────────────────────────────────────────────────────┘
       Requires manual approval from authorized users
```

---

## Usage Examples

### Manually Trigger Pipeline

```bash
# Azure DevOps Portal
Pipelines → Select pipeline → Run pipeline
  → Select Branch: develop or main
  → Run
```

### View Pipeline Results

```bash
# Azure DevOps Portal
Pipelines → Pipeline name → Builds
  → View Summary, Logs, Tests
  → Download Artifacts
```

### Check Artifact Downloads

```bash
# Published artifacts:
- dbt-test-artifacts
- dbt-dev-artifacts-{BuildId}
- dbt-prod-artifacts-{BuildId}
```

---

## Troubleshooting

### Pipeline Not Triggering

**Issue:** Pipeline doesn't run on push

**Solutions:**
1. Check trigger conditions in YAML
2. Verify branch protection rules
3. Confirm YAML file path: `azure-pipelines.yml` at repo root
4. Check if other pipelines exist (only latest runs)

### Authentication Failures

**Issue:** dbt connect fails to Databricks

**Solutions:**
```bash
# Verify credentials
- Check DATABRICKS_TOKEN is valid PAT
- Confirm DATABRICKS_HOST URL format
- Verify DATABRICKS_HTTP_PATH for correct warehouse
- Check token has required scopes
```

### Timeout Issues

**Issue:** Pipeline times out

**Solutions:**
```yaml
# Increase timeout in pipeline
jobs:
  - job: DBTRun
    timeoutInMinutes: 30   # Increase from default 60
```

### Approval Delays

**Issue:** Production deployment stuck in approval

**Solutions:**
1. Check environment approval queues
2. Notify approvers
3. Consider changing approval requirements if needed

---

## Performance Tips

### 1. Use Pipeline Caching
✅ Already configured: `Cache@2` task

### 2. Parallel Execution
```yaml
# Stages run sequentially by default
# To enable parallel: remove dependencies
dependsOn: []
```

### 3. Reduce Artifact Retention
```yaml
# Current: Unlimited
# Recommended: 7-30 days
retentionDays: 30
```

### 4. Use Self-Hosted Agents
```yaml
# For faster builds, consider running on:
pool:
  name: 'Default'           # Self-hosted agent pool
  demands:
    - agent.os -equals Linux
```

---

## Cost Optimization

| Action | Savings |
|--------|---------|
| Artifact retention policy | 20-30% storage |
| Parallel stages (where possible) | 10-15% time |
| Cache pip packages | 25-35% time |
| Use self-hosted agents | 50% compute |

---

## Security Best Practices

### 1. Secrets Management
✅ Use variable groups with secret masks
✅ Never hardcode credentials
✅ Rotate tokens regularly

### 2. Branch Protection
```yaml
# Configure in Azure DevOps:
- Require PR reviews: 2 approvers
- Require builds: All pipelines
- Lock main branch: Admin-only
```

### 3. Audit Logging
```yaml
# Check: Pipelines → Settings → Audit logs
- Who ran the pipeline
- What changed
- When deployment happened
```

---

## Migration from GitHub Actions

| Feature | GitHub Actions | Azure Pipelines |
|---------|---|---|
| Triggering | `on:` | `trigger:` |
| Environments | `environment:` | `environment:` |
| Secrets | `secrets.` | Variable groups |
| Artifacts | `actions/upload-artifact` | `PublishBuildArtifacts` |
| Cache | `actions/cache` | `Cache@2` |
| Conditionals | `if:` | `condition:` |

---

## Support & Resources

- **Azure Pipelines Docs:** https://docs.microsoft.com/en-us/azure/devops/pipelines/
- **YAML Schema Reference:** https://docs.microsoft.com/en-us/azure/devops/pipelines/yaml-schema
- **dbt + Databricks:** https://docs.getdbt.com/reference/warehouse-setups/databricks-setup
- **Databricks PAT:** https://docs.databricks.com/en/dev-tools/auth/pat.html

---

## Next Steps

1. **Create Azure DevOps project** if not exists
2. **Create Databricks service connection**
3. **Set up variable groups** with credentials
4. **Create environments** (development, production)
5. **Commit azure-pipelines.yml** to main branch
6. **Verify pipeline triggers** on GitHub/Azure Repos
7. **Run manual test** to validate setup
8. **Monitor first few builds** for issues

---

**Last Updated:** February 17, 2026  
**Status:** Ready for implementation
