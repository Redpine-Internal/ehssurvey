# Deploy Troubleshoot

## Task Metadata
```yaml
id: deploy-troubleshoot
description: Diagnosticar falhas de deploy e CI/CD no GCP
elicit: true
agent: seth-vargo
```

## Steps

### Step 1: Identificar Falha
Onde está falhando?
1. Cloud Build (build step failure)
2. Artifact Registry (push/pull failure)
3. Cloud Run deploy (revision failed)
4. GitHub Actions → GCP (auth failure)
5. Terraform apply (state/resource error)

### Step 2: Coletar Logs
```bash
# Cloud Build logs
gcloud builds list --limit 5 --format='table(id,status,source.repoSource.branchName,createTime)'
gcloud builds log BUILD_ID

# Artifact Registry images
gcloud artifacts docker images list REGION-docker.pkg.dev/PROJECT/REPO

# Cloud Run revision status
gcloud run revisions list --service SERVICE --region REGION --limit 5
```

### Step 3: Diagnóstico por Tipo

**Cloud Build failure:**
1. Dockerfile syntax error? → Check build step logs
2. Dependency install failure? → Network/registry access
3. Service account missing permissions? → Check cloudbuild SA roles
4. Substitution variables? → Verify _VARS in trigger config

**Artifact Registry failure:**
1. Auth configured? `gcloud auth configure-docker REGION-docker.pkg.dev`
2. Repository exists? `gcloud artifacts repositories list`
3. IAM: artifactregistry.writer role on build SA?

**Cloud Run deploy failure:**
1. Image accessible? → AR permissions
2. Container contract met? → PORT, health, startup
3. Service account has required roles?
4. VPC connector exists and is ready?

**GitHub Actions auth failure:**
1. Workload Identity Federation configured?
2. Service account has correct roles?
3. Provider/pool config matches repo?

### Step 4: Fix e Redeployar
Fornecer comandos exatos para resolver + re-trigger build/deploy.
