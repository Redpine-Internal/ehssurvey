# Cost Analysis

## Task Metadata
```yaml
id: cost-analysis
description: Analisar custos GCP e identificar oportunidades de economia
elicit: true
agent: storment
```

## Steps

### Step 1: Coletar Dados de Billing
Pergunte ao usuário:
1. Qual o gasto mensal atual (aproximado)?
2. Quais serviços consomem mais?
3. Tem billing export para BigQuery configurado?
4. Quantos ambientes (dev/staging/prod)?

### Step 2: Verificar Recursos
```bash
# Cloud Run services e config
gcloud run services list --format='table(name,region,spec.template.spec.containerConcurrency,spec.template.metadata.annotations["autoscaling.knative.dev/minScale"],spec.template.metadata.annotations["autoscaling.knative.dev/maxScale"])'

# Cloud SQL instances
gcloud sql instances list --format='table(name,databaseVersion,settings.tier,settings.availabilityType,region)'

# Compute Engine (if any)
gcloud compute instances list --format='table(name,zone,machineType,status)'

# Disks
gcloud compute disks list --format='table(name,zone,sizeGb,type,status,users)'

# Static IPs (charged when not in use)
gcloud compute addresses list --format='table(name,region,status,address)'

# Artifact Registry cleanup
gcloud artifacts docker images list REGION-docker.pkg.dev/PROJECT/REPO --include-tags --sort-by=CREATE_TIME
```

### Step 3: Análise de Otimização

**Quick wins (imediato):**
- [ ] Deletar recursos não usados (disks, IPs, old images)
- [ ] Cloud Run: min-instances=0 para não-produção
- [ ] Cloud SQL: shared-core para dev/staging
- [ ] Desabilitar HA em Cloud SQL não-produção

**Médio prazo:**
- [ ] Configurar billing export para BigQuery
- [ ] Implementar labels para cost allocation
- [ ] Budget alerts em 50%, 80%, 100%
- [ ] Cleanup policy no Artifact Registry

**Longo prazo:**
- [ ] Committed Use Discounts para Cloud SQL produção
- [ ] CPU allocation: request-based para low-traffic services
- [ ] Avaliar Cloud Run vs Cloud Functions para workloads event-driven

### Step 4: Estimativa de Economia
Apresentar tabela com economia estimada por ação.
