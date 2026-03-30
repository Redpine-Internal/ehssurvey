# Security Review

## Task Metadata
```yaml
id: security-review
description: Revisar segurança de projeto GCP
elicit: false
agent: google-sre
```

## Steps

### Step 1: IAM Audit
```bash
# All IAM bindings
gcloud projects get-iam-policy PROJECT_ID --format json

# Service accounts
gcloud iam service-accounts list --project PROJECT_ID

# SA keys (should be zero for Workload Identity)
for sa in $(gcloud iam service-accounts list --project PROJECT_ID --format='value(email)'); do
  echo "=== $sa ==="
  gcloud iam service-accounts keys list --iam-account=$sa --managed-by=user
done

# Check for dangerous bindings
gcloud projects get-iam-policy PROJECT_ID --format json | jq '.bindings[] | select(.members[] | contains("allUsers") or contains("allAuthenticatedUsers"))'
```

### Step 2: Network Security
```bash
# VPC and subnets
gcloud compute networks list --project PROJECT_ID
gcloud compute networks subnets list --project PROJECT_ID

# Firewall rules
gcloud compute firewall-rules list --project PROJECT_ID --format='table(name,direction,action,sourceRanges,allowed)'

# Cloud Run ingress
gcloud run services list --project PROJECT_ID --format='table(name,status.url,spec.template.metadata.annotations["run.googleapis.com/ingress"])'
```

### Step 3: Generate Report
Categorize findings:

| Severity | Finding | Recommendation |
|----------|---------|----------------|
| CRITICAL | allUsers IAM binding | Remove immediately |
| HIGH | Editor role on SA | Replace with specific roles |
| HIGH | SA key files exist | Migrate to Workload Identity |
| MEDIUM | Public Cloud Run ingress | Use LB + Cloud Armor |
| LOW | Default firewall rules | Review and tighten |

### Step 4: Remediation Commands
For each finding, provide the exact `gcloud` command to fix it.
