#!/usr/bin/env bash
set -e

SCRIPT_FOLDER_PATH="$( cd "$(dirname "$0")" ; pwd -P )"

#TODO: Look for /vendor and set dynamically.
PLATFORM_FOLDER_PATH="$(cd "$(dirname $(dirname $(dirname "$SCRIPT_FOLDER_PATH")))" && pwd)"

ANSIBLE_PLAYBOOK=${ANSIBLE_PLAYBOOK:-"playbook.yml"}
ANSIBLE_TAGS=${ANSIBLE_TAGS:-""}
ANSIBLE_SKIP_TAGS=${ANSIBLE_SKIP_TAGS:-""}
ANSIBLE_EXTRA_VARS=${ANSIBLE_EXTRA_VARS:-""}
ANSIBLE_PLAYBOOK_COMMAND_OPTIONS=${ANSIBLE_PLAYBOOK_COMMAND_OPTIONS:-""}
ANSIBLE_VERBOSITY=${ANSIBLE_VERBOSITY:-"0"}

# If the including repo has an inventory.yml file at the root, load it.
if [[ -f "$PLATFORM_FOLDER_PATH/inventory.yml" ]]; then
  ANSIBLE_PLAYBOOK_COMMAND_OPTIONS="$ANSIBLE_PLAYBOOK_COMMAND_OPTIONS --inventory=$PLATFORM_FOLDER_PATH/inventory.yml"
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


ANSIBLE_PLAYBOOK_COMMAND_OPTIONS="$ANSIBLE_PLAYBOOK_COMMAND_OPTIONS --inventory=$SCRIPT_FOLDER_PATH/services"

ON_FAIL=${ON_FAIL:-"systemctl status --no-pager"}
# TODO: Goat Scripts
LINE="------------------------"
echo $LINE
echo "Welcome to the Platform."

if [ -n "$DEBUG" ]; then
  echo $LINE
  echo "devshop-ansible-playbook.sh Environment Vars:"
  echo
  echo "SCRIPT_FOLDER_PATH: $SCRIPT_FOLDER_PATH"
  echo "PLATFORM_FOLDER_PATH: $PLATFORM_FOLDER_PATH"
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
#if [ ! -d ${PLATFORM_FOLDER_PATH}/roles/contrib ]; then
#  echo "No ansible roles found at ${PLATFORM_FOLDER_PATH}/roles/contrib."
#  echo "Running ./scripts/ansible-galaxy-install.sh..."
#  cd ${PLATFORM_FOLDER_PATH}
#  ./scripts/ansible-galaxy-install.sh
#  cd -
#fi

cd $SCRIPT_FOLDER_PATH
echo "Changed director to $SCRIPT_FOLDER_PATH"
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
