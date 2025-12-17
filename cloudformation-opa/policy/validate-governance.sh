#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

exec 1>&2

CF_JSON="$1"

if [ -z "$CF_JSON" ] || [ ! -f "$CF_JSON" ]; then
  echo -e "${RED}❌ ERROR: CloudFormation JSON not found${NC}"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POLICY_FILE="$SCRIPT_DIR/serverless-governance.rego"

echo -e "${YELLOW}🔍 Running CloudFormation governance checks...${NC}"

# Evaluate allow directly
ALLOW=$(opa eval \
  -i "$CF_JSON" \
  -d "$POLICY_FILE" \
  "data.system.allow" \
  --format raw)

# Evaluate violations directly
VIOLATIONS=$(opa eval \
  -i "$CF_JSON" \
  -d "$POLICY_FILE" \
  "data.system.violations" \
  --format raw)

if [ "$ALLOW" = "true" ]; then
  echo -e "${GREEN}✅ PASSED - Governance checks successful${NC}"
  exit 0
else
  echo -e "${RED}❌ FAILED - Governance violations detected${NC}"
  echo
  echo "Violations:"
  echo "$VIOLATIONS"
  exit 1
fi
