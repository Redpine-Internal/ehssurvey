#!/bin/bash
# GCP Squad — IAM Change Validator
# Usage: ./validate-iam-change.sh "gcloud projects add-iam-policy-binding ..."
# Covers: PY-SEC-001, PY-SEC-002, PY-SEC-003, PY-GCP-005
#
# Validates IAM changes before execution:
# - No allUsers/allAuthenticatedUsers without justification
# - No Owner/Editor roles on service accounts
# - Blast radius assessment for org/project level changes

set -euo pipefail

CMD="${1:-}"
if [[ -z "$CMD" ]]; then
  echo "Usage: validate-iam-change.sh \"gcloud iam command here\""
  exit 1
fi

RESULT="PASS"
MESSAGES=()

# ==============================================================================
# PY-SEC-001: No allUsers Binding (CRITICAL)
# ==============================================================================
if echo "$CMD" | grep -qiE "(allUsers|allAuthenticatedUsers)"; then
  RESULT="BLOCK"
  MESSAGES+=("BLOCK [PY-SEC-001] Public IAM binding detected (allUsers/allAuthenticatedUsers).")
  MESSAGES+=("       REQUIRES: Explicit written justification from user.")
  MESSAGES+=("       SUGGEST: Use IAP or Identity-Aware Proxy instead.")
fi

# ==============================================================================
# PY-SEC-003: No Owner/Editor on SA (CRITICAL)
# ==============================================================================
if echo "$CMD" | grep -qiE "roles/(owner|editor)" && echo "$CMD" | grep -qiE "serviceAccount:"; then
  RESULT="BLOCK"
  MESSAGES+=("BLOCK [PY-SEC-003] Owner/Editor role on service account.")
  MESSAGES+=("       REQUIRES: Use specific predefined role instead.")
  MESSAGES+=("       SUGGEST: gcloud iam list-grantable-roles //cloudresourcemanager.googleapis.com/projects/PROJECT")
fi

# ==============================================================================
# PY-SEC-002: No SA Key Files (HIGH)
# ==============================================================================
if echo "$CMD" | grep -qiE "iam service-accounts keys create"; then
  if [[ "$RESULT" != "BLOCK" ]]; then RESULT="WARN"; fi
  MESSAGES+=("WARN  [PY-SEC-002] SA key creation. Recommend Workload Identity Federation instead.")
  MESSAGES+=("       DOCS: https://cloud.google.com/iam/docs/workload-identity-federation")
fi

# ==============================================================================
# PY-GCP-005: Org-Level IAM (CRITICAL)
# ==============================================================================
if echo "$CMD" | grep -qiE "(organizations/|--organization|--folder)"; then
  RESULT="BLOCK"
  MESSAGES+=("BLOCK [PY-GCP-005] Org/folder-level IAM change detected.")
  MESSAGES+=("       BLAST RADIUS: Affects ALL projects under this org/folder.")
  MESSAGES+=("       REQUIRES: User confirmation + rollback command prepared.")
fi

# ==============================================================================
# ADDITIONAL: Role width check (HIGH)
# ==============================================================================
if echo "$CMD" | grep -qiE "roles/(editor|owner|admin)" && [[ "$RESULT" != "BLOCK" ]]; then
  RESULT="WARN"
  MESSAGES+=("WARN  [BEST-PRACTICE] Broad role detected. Consider narrower predefined role.")
fi

# ==============================================================================
# ADDITIONAL: Missing --condition (INFO)
# ==============================================================================
if echo "$CMD" | grep -qiE "add-iam-policy-binding" && ! echo "$CMD" | grep -qiE "\-\-condition"; then
  MESSAGES+=("INFO  [BEST-PRACTICE] No --condition flag. Consider conditional binding (IP, time, resource).")
fi

# ==============================================================================
# OUTPUT
# ==============================================================================
echo "IAM VALIDATION: $RESULT"
if [[ ${#MESSAGES[@]} -eq 0 ]]; then
  echo "IAM change validated. Least privilege checks passed."
else
  for msg in "${MESSAGES[@]}"; do
    echo "  $msg"
  done
fi

exit $( [[ "$RESULT" == "BLOCK" ]] && echo 1 || echo 0 )
