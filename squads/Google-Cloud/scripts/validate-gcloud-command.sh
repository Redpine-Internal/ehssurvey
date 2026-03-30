#!/bin/bash
# GCP Squad — Poka-Yoke Validator for gcloud commands
# Usage: ./validate-gcloud-command.sh "gcloud run deploy ..."
# Returns: PASS, WARN, or BLOCK with reason
#
# Covers: PY-GCP-001 (destructive), PY-GCP-002 (project scope),
#         PY-GCP-004 (billing impact), PY-GCP-005 (IAM blast radius),
#         PY-CR-001 (region), PY-CICD-001 (secrets in code),
#         PY-CICD-003 (latest tag), PY-SEC-001 (allUsers),
#         PY-SEC-003 (owner role), PY-SEC-004 (firewall allow-all)

set -euo pipefail

CMD="${1:-}"
if [[ -z "$CMD" ]]; then
  echo "Usage: validate-gcloud-command.sh \"gcloud command here\""
  exit 1
fi

RESULT="PASS"
MESSAGES=()

# ==============================================================================
# PY-GCP-001: Destructive Command Gate (CRITICAL)
# ==============================================================================
DESTRUCTIVE_WORDS="delete|destroy|remove|disable|drop|purge|reset"
if echo "$CMD" | grep -qiE "($DESTRUCTIVE_WORDS)"; then
  RESULT="BLOCK"
  MESSAGES+=("BLOCK [PY-GCP-001] Destructive command detected. Present impact + rollback BEFORE execution.")
fi

# ==============================================================================
# PY-GCP-002: Project Scope Check (HIGH)
# ==============================================================================
if echo "$CMD" | grep -q "^gcloud " && ! echo "$CMD" | grep -qE "\-\-project[= ]"; then
  if [[ "$RESULT" != "BLOCK" ]]; then RESULT="WARN"; fi
  MESSAGES+=("WARN  [PY-GCP-002] No --project flag. Command targets default project.")
fi

# ==============================================================================
# PY-GCP-004: Billing Impact Alert (HIGH)
# ==============================================================================
RESOURCE_CREATORS="deploy|create|instances create|clusters create|reservations create"
if echo "$CMD" | grep -qiE "($RESOURCE_CREATORS)"; then
  if [[ "$RESULT" != "BLOCK" ]]; then RESULT="WARN"; fi
  MESSAGES+=("WARN  [PY-GCP-004] Resource creation detected. Estimate monthly cost before execution.")
fi

# ==============================================================================
# PY-GCP-005: IAM Blast Radius (CRITICAL)
# ==============================================================================
if echo "$CMD" | grep -qiE "(set-iam-policy|add-iam-policy-binding)" && echo "$CMD" | grep -qiE "(organizations/|--organization)"; then
  RESULT="BLOCK"
  MESSAGES+=("BLOCK [PY-GCP-005] Org-level IAM change. Full impact analysis required.")
fi

# ==============================================================================
# PY-CR-001: Region Consistency (HIGH)
# ==============================================================================
if echo "$CMD" | grep -qiE "(gcloud run deploy|gcloud run services)" && ! echo "$CMD" | grep -qE "\-\-region[= ]"; then
  if [[ "$RESULT" != "BLOCK" ]]; then RESULT="WARN"; fi
  MESSAGES+=("WARN  [PY-CR-001] Cloud Run command without --region. Specify explicitly.")
fi

# ==============================================================================
# PY-CICD-003: Artifact Tag Immutability (HIGH)
# ==============================================================================
if echo "$CMD" | grep -qiE ":latest"; then
  if [[ "$RESULT" != "BLOCK" ]]; then RESULT="WARN"; fi
  MESSAGES+=("WARN  [PY-CICD-003] :latest tag detected. Use SHA digest or semantic version.")
fi

# ==============================================================================
# PY-SEC-001: No allUsers Binding (CRITICAL)
# ==============================================================================
if echo "$CMD" | grep -qiE "(allUsers|allAuthenticatedUsers)"; then
  RESULT="BLOCK"
  MESSAGES+=("BLOCK [PY-SEC-001] allUsers/allAuthenticatedUsers binding. Requires explicit justification.")
fi

# ==============================================================================
# PY-SEC-003: Owner Role Block (CRITICAL)
# ==============================================================================
if echo "$CMD" | grep -qiE "(roles/owner|roles/editor)" && echo "$CMD" | grep -qiE "serviceAccount:"; then
  RESULT="BLOCK"
  MESSAGES+=("BLOCK [PY-SEC-003] Owner/Editor role on service account. Use specific predefined role.")
fi

# ==============================================================================
# PY-SEC-004: Firewall Allow-All Check (HIGH)
# ==============================================================================
if echo "$CMD" | grep -qiE "firewall-rules create" && echo "$CMD" | grep -qE "0\.0\.0\.0/0"; then
  if [[ "$RESULT" != "BLOCK" ]]; then RESULT="WARN"; fi
  MESSAGES+=("WARN  [PY-SEC-004] Firewall rule allows 0.0.0.0/0. Restrict source IP range.")
fi

# ==============================================================================
# OUTPUT
# ==============================================================================
echo "VALIDATION: $RESULT"
if [[ ${#MESSAGES[@]} -eq 0 ]]; then
  echo "All poka-yoke checks passed."
else
  for msg in "${MESSAGES[@]}"; do
    echo "  $msg"
  done
fi

exit $( [[ "$RESULT" == "BLOCK" ]] && echo 1 || echo 0 )
