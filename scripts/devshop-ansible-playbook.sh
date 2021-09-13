#!/usr/bin/env bash
set -e

ANSIBLE_PLAYBOOK=${ANSIBLE_PLAYBOOK:-"playbook.yml"}
ANSIBLE_TAGS=${ANSIBLE_TAGS:-""}
ANSIBLE_SKIP_TAGS=${ANSIBLE_SKIP_TAGS:-""}
ANSIBLE_EXTRA_VARS=${ANSIBLE_EXTRA_VARS:-""}
ANSIBLE_PLAYBOOK_COMMAND_OPTIONS=${ANSIBLE_PLAYBOOK_COMMAND_OPTIONS:-"--diff"}
ANSIBLE_VERBOSITY=${ANSIBLE_VERBOSITY:-"0"}

# Build options string if ENV vars exist.
if [[ -n "${ANSIBLE_TAGS}" ]]; then
  ANSIBLE_PLAYBOOK_COMMAND_OPTIONS="--tags $ANSIBLE_TAGS $ANSIBLE_PLAYBOOK_COMMAND_OPTIONS"
fi
if [[ -n "${ANSIBLE_SKIP_TAGS}" ]]; then
  ANSIBLE_PLAYBOOK_COMMAND_OPTIONS="--skip-tags $ANSIBLE_SKIP_TAGS $ANSIBLE_PLAYBOOK_COMMAND_OPTIONS"
fi
if [[ -n "${ANSIBLE_EXTRA_VARS}" ]]; then
  ANSIBLE_PLAYBOOK_COMMAND_OPTIONS="--extra-vars $ANSIBLE_EXTRA_VARS $ANSIBLE_PLAYBOOK_COMMAND_OPTIONS"
fi

ON_FAIL=${ON_FAIL:-"systemctl status --no-pager"}
# TODO: Goat Scripts
LINE="------------------------"
echo $LINE
echo "Welcome to the Platform."

if [ -n "$DEBUG" ]; then
  echo $LINE
  echo "devshop-ansible-playbook.sh Environment Vars:"
  echo
  echo "ANSIBLE_PLAYBOOK: $ANSIBLE_PLAYBOOK"
  echo "ANSIBLE_TAGS: $ANSIBLE_TAGS"
  echo "ANSIBLE_SKIP_TAGS: $ANSIBLE_SKIP_TAGS"
  echo "ANSIBLE_EXTRA_VARS: $ANSIBLE_EXTRA_VARS"
  echo "ANSIBLE_VERBOSITY: $ANSIBLE_VERBOSITY"
  echo "ANSIBLE_PLAYBOOK_COMMAND_OPTIONS: $ANSIBLE_PLAYBOOK_COMMAND_OPTIONS"
  echo "Additional Arguments: $*"
fi

ANSIBLE_PLAYBOOK_INVENTORY_COMMAND="ansible-playbook --list-hosts $ANSIBLE_PLAYBOOK \
    $ANSIBLE_PLAYBOOK_COMMAND_OPTIONS \
    $*"

ANSIBLE_PLAYBOOK_FULL_COMMAND="ansible-playbook $ANSIBLE_PLAYBOOK \
    $ANSIBLE_PLAYBOOK_COMMAND_OPTIONS \
    $*"

echo $LINE
echo "Running Ansible Playbook --list-hosts Command: "
echo "> $ANSIBLE_PLAYBOOK_INVENTORY_COMMAND"
$ANSIBLE_PLAYBOOK_INVENTORY_COMMAND

echo $LINE
echo "Running Ansible Playbook Command: "
echo "> $ANSIBLE_PLAYBOOK_FULL_COMMAND"

# Do not exit on error so we can run additional commands.
set +e
time $ANSIBLE_PLAYBOOK_FULL_COMMAND || \
    echo "Playbook Failed! (exit $?)"; \
    exit $?
