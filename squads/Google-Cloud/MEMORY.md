# Google Cloud Squad — Shared Memory

## Protocol

Each agent reads and writes to this file following the shared memory protocol defined in their L5 configuration.

### Write Permissions

| Agent | Writes |
|-------|--------|
| gcp-chief | Routing misses, cross-domain problems, user project context |
| steren | Cloud Run issues resolved, service configs, cold start optimizations |
| seth-vargo | Build failure patterns, pipeline configs, Terraform patterns |
| liz-fong-jones | SLO/SLI definitions, latency findings, alert configs |
| storment | Cost baselines, optimization recommendations, CUD decisions |
| priyanka | Architecture decisions (ADR), VPC configs, migration plans |
| google-sre | IAM audit results, hardening actions, Cloud Armor rules |

### TTL Policy (Memory Decay)

| Type | TTL (days) | Rationale |
|------|-----------|-----------|
| Cost baselines | 90 | Costs change frequently |
| IAM audits | 90 | Security posture evolves |
| Latency findings | 90 | Performance changes with deploys |
| Build failures | 120 | Build patterns evolve |
| Optimization results | 120 | Need periodic re-evaluation |
| Resolved issues | 180 | Solutions stay relevant longer |
| Alert/Armor configs | 180 | Configs are semi-stable |
| Terraform patterns | 180 | IaC patterns reusable |
| Architecture decisions | 365 | ADRs are long-lived |
| VPC/service configs | 365 | Infrastructure is stable |
| User project context | 365 | Rarely changes |
| CUD decisions | 365 | Commitment periods are long |

---

## Auto-Purge Protocol

**Owner:** gcp-chief executes on every session start.

**Rule:** For each entry below, check `[YYYY-MM-DD]` date against TTL from table above.
- `entry_date + TTL < today` → **DELETE** the entry
- `entry_date + TTL < today + 14 days` → Append `[EXPIRING SOON]` tag
- Log purge count in Routing Log: `- [YYYY-MM-DD] AUTO-PURGE: removed N expired entries`

**Entry format:** All entries MUST use the tagged format below. Entries without dates are treated as TTL=30 days from file last-modified date.

**Tagged format (OBRIGATÓRIO):**
```
- [YYYY-MM-DD] [service] [error-type] [agent] Description. Fix: solution. TTL:days
```

**Tags válidas:**
- `[service]`: cloud-run, cloud-build, cloud-sql, iam, vpc, billing, monitoring, logging, tracing, cloud-armor, secret-manager, artifact-registry, terraform, load-balancer, cloud-storage, cloud-cdn, architecture
- `[error-type]`: 503, 504, timeout, permission-denied, config-error, cost-spike, deploy-fail, startup-fail, memory-exceeded, connection-refused, certificate-error, quota-exceeded, routing-miss, drift
- `[agent]`: gcp-chief, steren, seth-vargo, liz-fong-jones, storment, priyanka, google-sre

**Retrieval:** Agents MUST grep MEMORY.md for `[service]` and `[error-type]` tags BEFORE starting diagnosis. Include matching entries in context.

---

## Entries

### User Project Context
- *No entries yet*

### Architecture Decisions
- *No entries yet*

### Resolved Issues
- [2026-03-02] [cloud-run] [503] [steren] Container PORT not configured after deploy. Fix: gcloud run services update --port=8080. Verify: curl SERVICE_URL returns 200. TTL:180

### Cost Baselines
- *No entries yet*

### Security Audits
- *No entries yet*

### Routing Log
- [2026-03-02] [routing] Matched: "Cloud Run + 503" → @steren. Method: regex. Secondary: @seth-vargo (deploy keyword, not routed). Resolution: RESOLVED
