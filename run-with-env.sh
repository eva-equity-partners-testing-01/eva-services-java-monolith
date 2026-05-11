#!/usr/bin/env bash
set -euo pipefail

if [[ ! -f ".env" ]]; then
  echo "Missing .env file in project root"
  exit 1
fi

set -a
source ./.env
set +a

mvn spring-boot:run 
