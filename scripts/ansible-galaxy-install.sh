#!/usr/bin/env bash
set -e

DEVSHOP_ROLES_PATH=roles/contrib
DEVSHOP_ROLES_FILE=roles.yml

DEVSHOP_COLLECTIONS_PATH=roles

ansible-galaxy install \
  --roles-path $DEVSHOP_ROLES_PATH \
  --role-file $DEVSHOP_ROLES_FILE \
  --force

ansible-galaxy collection install \
  --collections-path $DEVSHOP_COLLECTIONS_PATH \
  --requirements-file $DEVSHOP_ROLES_FILE \
  --force
