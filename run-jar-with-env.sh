#!/usr/bin/env bash
set -euo pipefail

if [[ ! -f ".env" ]]; then
  echo "Missing .env file in project root"
  exit 1
fi

set -a
source ./.env
set +a

./mvnw clean package -DskipTests

JAR_FILE=$(ls target/*.jar | grep -v 'original' | head -n 1)
if [[ -z "${JAR_FILE:-}" ]]; then
  echo "No runnable jar found in target/"
  exit 1
fi

java -jar "$JAR_FILE"
 
