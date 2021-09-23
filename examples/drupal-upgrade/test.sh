
set -e
molecule create
echo "Running playbook with d7 & d8 inventory..."
./d -i services -i examples/drupal-upgrade/inventory.platform.yml -i examples/drupal-upgrade/inventory.sites.yml --connection docker $*

echo "Running playbook with d9 inventory..."
./d -i services -i examples/drupal-upgrade/inventory.platform.yml -i examples/drupal-upgrade/inventory.sites.upgraded.yml --connection docker $*
