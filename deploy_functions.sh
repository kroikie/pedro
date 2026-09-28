#!/bin/bash

# Configuration
PROJECT_ID="${1:-pedro-f65a6}"
MAX_RETRIES=10

echo "=== Starting Firebase Functions Deployment for $PROJECT_ID ==="

attempt=1
targets="functions"

while [ $attempt -le $MAX_RETRIES ]; do
  echo ""
  echo "=================================================="
  echo "Deployment Attempt $attempt of $MAX_RETRIES"
  echo "=================================================="
  
  if [ "$targets" = "functions" ]; then
    echo "Deploying all functions..."
    firebase deploy --only functions --project "$PROJECT_ID" --force 2>&1 | tee deploy_attempt.log
    exit_code=${PIPESTATUS[0]}
  else
    echo "Retrying only failed functions: $targets"
    firebase deploy --only "$targets" --project "$PROJECT_ID" --force 2>&1 | tee deploy_attempt.log
    exit_code=${PIPESTATUS[0]}
  fi

  if [ $exit_code -eq 0 ]; then
    echo ""
    echo "✔ Deployment completed successfully on attempt $attempt!"
    rm -f deploy_attempt.log
    exit 0
  fi

  echo ""
  echo "⚠ Deployment encountered errors. Extracting failed functions..."
  
  # Strip ANSI color codes, then extract lines with the function(region) format.
  failed_list=$(sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" deploy_attempt.log | awk '/Functions deploy had errors with the following functions:/{flag=1;next} flag && /^i  /{flag=0;next} flag && /^[[:space:]]+[a-zA-Z0-9_-]+\(/{print} flag && /^[^[:space:]]/{flag=0}' | sed 's/^[[:space:]]*//' | sed 's/(.*)//' | grep -v '^$')

  if [ -z "$failed_list" ]; then
    echo "❌ Deployment failed at a higher level (compilation, permissions, or secrets validation)."
    echo "Please check the log output above."
    rm -f deploy_attempt.log
    exit $exit_code
  fi

  echo "The following functions failed:"
  for fn in $failed_list; do
    echo "  - $fn"
  done

  # Convert list to target string: "functions:fn1,functions:fn2"
  targets=""
  for fn in $failed_list; do
    if [ -n "$targets" ]; then
      targets="$targets,functions:$fn"
    else
      targets="functions:$fn"
    fi
  done

  echo ""
  echo "Retargeting next attempt to: $targets"
  attempt=$((attempt + 1))
done

echo ""
echo "❌ Deployment failed after $MAX_RETRIES attempts."
rm -f deploy_attempt.log
exit 1
