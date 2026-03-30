# Diagnose GCP Issue

## Task Metadata
```yaml
id: diagnose-issue
description: Diagnosticar problema genérico no GCP com triage automático
elicit: true
agent: gcp-chief
```

## Steps

### Step 1: Coletar Informações
Pergunte ao usuário:
1. Qual serviço GCP está com problema?
2. Qual o erro/sintoma? (código de erro, mensagem, comportamento)
3. Quando começou? (após deploy, mudança de config, do nada)
4. Ambiente? (dev, staging, production)

### Step 2: Triage
Baseado nas informações, categorize:

| Categoria | Indicadores | Rota |
|-----------|-------------|------|
| Cloud Run | 503, 504, container failed, cold start, scaling | @steren |
| CI/CD | build failed, deploy error, artifact push | @seth-vargo |
| Observability | no logs, missing metrics, can't trace | @liz-fong-jones |
| Costs | unexpected charges, budget alert | @storment |
| Architecture | design question, VPC, connectivity | @priyanka |
| Security | IAM denied, SSL error, auth failure | @google-sre |

### Step 3: Diagnóstico Rápido
Antes de rotear, execute verificações rápidas:

```bash
# Status geral do projeto
gcloud projects describe PROJECT_ID

# Serviços habilitados
gcloud services list --enabled --project PROJECT_ID

# Logs recentes com erros
gcloud logging read "severity>=ERROR" --limit 10 --project PROJECT_ID --format json

# Cloud Run services
gcloud run services list --project PROJECT_ID --region REGION
```

### Step 4: Rotear
Rotear para o especialista apropriado com:
- Resumo do problema
- Informações coletadas
- Logs relevantes
- Hipótese inicial
