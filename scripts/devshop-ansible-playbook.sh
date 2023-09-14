#!/usr/bin/env bash
set -e
if [[ -z "$COMPOSER_RUNTIME_BIN_DIR" ]]; then
  BIN_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
else
  BIN_DIR="$COMPOSER_RUNTIME_BIN_DIR"
fi

PLATFORM_FOLDER_PATH="$( cd "$(dirname "$0")" ; pwd -P )"
PROJECT_FOLDER_PATH=$(dirname $BIN_DIR)

ANSIBLE_PLAYBOOK=${ANSIBLE_PLAYBOOK:-"${PLATFORM_FOLDER_PATH}/playbook.yml"}
ANSIBLE_TAGS=${ANSIBLE_TAGS:-""}
ANSIBLE_SKIP_TAGS=${ANSIBLE_SKIP_TAGS:-""}
ANSIBLE_EXTRA_VARS=${ANSIBLE_EXTRA_VARS:-""}
ANSIBLE_PLAYBOOK_COMMAND_OPTIONS=${ANSIBLE_PLAYBOOK_COMMAND_OPTIONS:-""}
ANSIBLE_VERBOSITY=${ANSIBLE_VERBOSITY:-"0"}

# If the including repo has an inventory.yml file at the root, load it.
if [[ -f "$PROJECT_FOLDER_PATH/inventory.yml" ]]; then
  ANSIBLE_PLAYBOOK_COMMAND_OPTIONS="$ANSIBLE_PLAYBOOK_COMMAND_OPTIONS --inventory=$PROJECT_FOLDER_PATH/inventory.yml"
fi

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


ANSIBLE_PLAYBOOK_COMMAND_OPTIONS="$ANSIBLE_PLAYBOOK_COMMAND_OPTIONS --inventory=$PLATFORM_FOLDER_PATH/services"

ON_FAIL=${ON_FAIL:-"systemctl status --no-pager"}
# TODO: Goat Scripts
LINE="------------------------"
echo $LINE
echo "Welcome to the Platform."
echo "Current Dir: ${pwd}"
# Detect dependencies
if [[ ! `command -v ansible` ]]; then
  echo "This script requires ansible. Install it and try again."
  exit 1
fi

if [ -n "$DEBUG" ]; then
  echo $LINE
  echo "devshop-ansible-playbook.sh Environment Vars:"
  echo
  echo "PLATFORM_FOLDER_PATH: $PLATFORM_FOLDER_PATH"
  echo "PROJECT_FOLDER_PATH: $PROJECT_FOLDER_PATH"
  echo "PWD: $PWD"
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

# @TODO: detect missing roles using ansible instead. This is tricky due to paths & ansible config. We don't want this to run unless called.
## Detect missing roles and install.
#if [ ! -d ${PROJECT_FOLDER_PATH}/roles/contrib ]; then
#  echo "No ansible roles found at ${PROJECT_FOLDER_PATH}/roles/contrib."
#  echo "Running ./scripts/ansible-galaxy-install.sh..."
#  cd ${PROJECT_FOLDER_PATH}
#  ./scripts/ansible-galaxy-install.sh
#  cd -
#fi

cd $PROJECT_FOLDER_PATH
echo "Changed directory to $PROJECT_FOLDER_PATH"
echo "Running Ansible Playbook --list-hosts Command: "
echo "> $ANSIBLE_PLAYBOOK_INVENTORY_COMMAND"
$ANSIBLE_PLAYBOOK_INVENTORY_COMMAND

echo $LINE
echo "Running Ansible Playbook Command: "
echo "> $ANSIBLE_PLAYBOOK_FULL_COMMAND"

# Do not exit on error so we can run additional commands.
set +e
time $ANSIBLE_PLAYBOOK_FULL_COMMAND || \
    (
      EXIT=$?
      echo "Playbook Failed! (exit $EXIT)"
      exit $EXIT
    )
