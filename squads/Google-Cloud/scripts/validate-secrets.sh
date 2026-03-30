#!/bin/bash
# GCP Squad — Secret Exposure Validator
# Usage: ./validate-secrets.sh <file-or-directory>
# Covers: PY-CICD-001 (no secrets in code)
#
# Scans cloudbuild.yaml, Dockerfile, .env, and YAML/JSON files
# for common secret patterns (API keys, passwords, tokens)

set -euo pipefail

TARGET="${1:-}"
if [[ -z "$TARGET" ]]; then
  echo "Usage: validate-secrets.sh <file-or-directory>"
  exit 1
fi

RESULT="PASS"
FINDINGS=()

# Patterns that indicate hardcoded secrets
SECRET_PATTERNS=(
  'PRIVATE.KEY'
  'password\s*[:=]\s*["\x27][^"\x27]{8,}'
  'api[_-]?key\s*[:=]\s*["\x27][^"\x27]{8,}'
  'secret[_-]?key\s*[:=]\s*["\x27][^"\x27]{8,}'
  'token\s*[:=]\s*["\x27][^"\x27]{20,}'
  'AIza[0-9A-Za-z_-]{35}'
  'ya29\.[0-9A-Za-z_-]+'
  'GOOG[\w]{10,30}'
  'BEGIN (RSA |EC |DSA )?PRIVATE KEY'
  'sk-[a-zA-Z0-9]{20,}'
)

# Files to scan
if [[ -d "$TARGET" ]]; then
  FILES=$(find "$TARGET" -type f \( -name "*.yaml" -o -name "*.yml" -o -name "*.json" -o -name "Dockerfile*" -o -name ".env*" -o -name "*.sh" -o -name "*.tf" \) 2>/dev/null)
else
  FILES="$TARGET"
fi

for file in $FILES; do
  for pattern in "${SECRET_PATTERNS[@]}"; do
    matches=$(grep -inE "$pattern" "$file" 2>/dev/null || true)
    if [[ -n "$matches" ]]; then
      RESULT="BLOCK"
      FINDINGS+=("BLOCK [PY-CICD-001] Potential secret in $file:")
      while IFS= read -r line; do
        FINDINGS+=("       $line")
      done <<< "$matches"
    fi
  done
done

# ==============================================================================
# OUTPUT
# ==============================================================================
echo "SECRET SCAN: $RESULT"
if [[ ${#FINDINGS[@]} -eq 0 ]]; then
  echo "No hardcoded secrets detected."
else
  for f in "${FINDINGS[@]}"; do
    echo "  $f"
  done
  echo ""
  echo "ACTION: Move secrets to Secret Manager. Use:"
  echo "  gcloud secrets create SECRET_NAME --data-file=secret.txt"
  echo "  gcloud run services update SERVICE --set-secrets=ENV=SECRET_NAME:latest"
fi

exit $( [[ "$RESULT" == "BLOCK" ]] && echo 1 || echo 0 )
