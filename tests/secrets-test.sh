#!/bin/bash

export DEVOPS_TRACKING_SECRETS

DEVOPS_TRACKING_SECRETS="$(cat tests/fixtures/DEVOPS_TRACKING_SECRETS)"

echo "${DEVOPS_TRACKING_SECRETS}"

source src/secrets.sh

process_secrets