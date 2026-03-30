# Cloud Run Troubleshoot

## Task Metadata
```yaml
id: cloud-run-troubleshoot
description: Diagnosticar e resolver problemas no Cloud Run
elicit: true
agent: steren
```

## Steps

### Step 1: Identificar o Problema
Pergunte ao usuário o sintoma:
- HTTP error code (503, 504, 500, etc.)
- "Container failed to start"
- Cold start lento
- Scaling issues
- Conectividade (Cloud SQL, Storage, etc.)

### Step 2: Coletar Dados
```bash
# Service details
gcloud run services describe SERVICE_NAME --region REGION --format yaml

# Recent revisions
gcloud run revisions list --service SERVICE_NAME --region REGION

# Logs do container
gcloud logging read 'resource.type="cloud_run_revision" AND resource.labels.service_name="SERVICE_NAME" AND severity>=WARNING' --limit 50 --format json

# Instance metrics
gcloud monitoring metrics list --filter='metric.type="run.googleapis.com/container/instance_count"'
```

### Step 3: Árvore de Diagnóstico

**503 Service Unavailable:**
1. Container não está ouvindo na PORT correta?
2. Container excedeu startup timeout (4min default)?
3. Container crashou durante startup? (check logs)
4. Memória insuficiente? (OOM kill)
5. Health check falhando?

**504 Gateway Timeout:**
1. Request excedeu timeout (default 5min)?
2. Downstream service (Cloud SQL) lento?
3. VPC connector com throttling?

**Container failed to start:**
1. PORT env var não configurada?
2. Dependência faltando no container?
3. Startup crash (segfault, missing lib)?

**Cold start lento:**
1. min-instances está 0?
2. Imagem muito grande?
3. App init lento (DB connections, cache warm)?
4. Startup CPU boost habilitado?

### Step 4: Aplicar Fix
Forneça o comando `gcloud` exato para o fix, ex:
```bash
# Fix min-instances
gcloud run services update SERVICE --min-instances 1 --region REGION

# Fix memory
gcloud run services update SERVICE --memory 1Gi --region REGION

# Fix timeout
gcloud run services update SERVICE --timeout 300 --region REGION
```

### Step 5: Verificar
```bash
# Verificar se nova revisão está healthy
gcloud run services describe SERVICE --region REGION --format='value(status.conditions)'

# Teste de saúde
curl -s -o /dev/null -w "%{http_code}" https://SERVICE_URL/
```
