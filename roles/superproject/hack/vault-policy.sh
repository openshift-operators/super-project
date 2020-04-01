#!/usr/bin/env bash

OCP_INFRA_SECRETS_PATH="ocp/projects/+/infra"
POLICY_NAME=ocp-infra-secrets-viewer
MOUNT_PREFIX="kv"

cat<<EOF | vault policy write ${POLICY_NAME}  -
path "${MOUNT_PREFIX}/metadata/${OCP_INFRA_SECRETS_PATH}/*"
{
  capabilities = ["list", "read"]
}
path "${MOUNT_PREFIX}/data/${OCP_INFRA_SECRETS_PATH}/*"
{
  capabilities = ["read", "list"]
}
path "${MOUNT_PREFIX}/data/${OCP_INFRA_SECRETS_PATH}"
{
  capabilities = [ "read", "list"]
}
EOF
