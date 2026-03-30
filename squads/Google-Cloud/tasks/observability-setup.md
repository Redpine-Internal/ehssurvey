# Observability Setup

## Task Metadata
```yaml
id: observability-setup
description: Configurar observabilidade no GCP (monitoring, logging, tracing)
elicit: true
agent: liz-fong-jones
```

## Steps

### Step 1: Assessment de Maturidade
Avaliar nível atual:
- L0: Sem monitoring
- L1: Uptime checks básicos
- L2: Logs estruturados + dashboards
- L3: Tracing distribuído + SLOs
- L4: Observabilidade completa

### Step 2: Setup Básico (L1 → L2)
```bash
# Verificar APIs habilitadas
gcloud services list --enabled --filter='name:(monitoring OR logging OR trace OR cloudprofiler)'

# Habilitar se necessário
gcloud services enable monitoring.googleapis.com logging.googleapis.com cloudtrace.googleapis.com

# Criar uptime check para Cloud Run
gcloud monitoring uptime create SERVICE_CHECK \
  --resource-type=cloud-run-revision \
  --resource-labels=service_name=SERVICE,project_id=PROJECT

# Log-based metric para erros
gcloud logging metrics create error_count \
  --description="Count of error logs" \
  --log-filter='severity>=ERROR'
```

### Step 3: Setup Avançado (L2 → L3)
- Dashboard com métricas Cloud Run (request count, latency, instance count)
- Alerting policies para error rate > threshold
- Log Router para export long-term para Cloud Storage
- Trace sampling configuration

### Step 4: SLOs
Definir SLOs para serviços críticos:
- Availability SLO: 99.9% (8.76h downtime/year)
- Latency SLO: p99 < 500ms
- Error rate SLO: < 0.1% of requests

### Step 5: Alerting
Configurar alertas baseados em SLOs (burn rate alerting) ao invés de thresholds estáticos.
