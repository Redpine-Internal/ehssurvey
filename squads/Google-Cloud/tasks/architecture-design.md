# Architecture Design

## Task Metadata
```yaml
id: architecture-design
description: Projetar arquitetura GCP para um caso de uso
elicit: true
agent: priyanka
```

## Steps

### Step 1: Entender Requisitos
Pergunte:
1. O que o sistema precisa fazer?
2. Quantos usuários/requests esperados?
3. Requisitos de latência?
4. Budget disponível?
5. Equipe técnica (tamanho, experiência GCP)?

### Step 2: Selecionar Serviços
Baseado nos requisitos, mapear para serviços GCP:

| Necessidade | Serviço GCP | Alternativa |
|-------------|-------------|-------------|
| Web app hosting | Cloud Run | GKE (se K8s necessário) |
| Database relacional | Cloud SQL | AlloyDB (alta performance) |
| File storage | Cloud Storage | Filestore (NFS) |
| Cache | Memorystore Redis | — |
| Queue/Events | Pub/Sub | Cloud Tasks |
| CDN | Cloud CDN | — |
| Load Balancing | Cloud Load Balancing | — |
| DNS | Cloud DNS | — |
| Secrets | Secret Manager | — |
| CI/CD | Cloud Build | GitHub Actions |

### Step 3: Diagrama de Arquitetura
Gerar diagrama em ASCII/texto mostrando:
- Componentes e serviços
- Fluxo de dados
- Limites de rede (VPC, subnets)
- Pontos de entrada/saída

### Step 4: Checklist de Qualidade
- [ ] Segurança: IAM least privilege, private networking
- [ ] Reliability: HA, backups, failover
- [ ] Performance: auto-scaling, CDN, caching
- [ ] Cost: right-sized, labels, budgets
- [ ] Operations: monitoring, logging, alerting

### Step 5: Estimativa de Custo
Usar GCP Pricing Calculator para estimar custo mensal por componente.
