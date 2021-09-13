# DevShop.App

Builds and installs an application and it's required services using pre-defined roles.
 
This role is part of the *DevShop Ansible Platform*.

It works in concert with the `devshop.host` and `devshop.services` roles to create a platform that can host as many apps on as many hosts as needed.

## Requirements

1. A host configured with `devshop.host` and `devshop.services`.
2. A playbook with the `devshop_apps` inventory plugin. *(See [../../playbook.yml](../../playbook.yml))*.
3. An `apps.yml` inventory file. *(See [../../apps.yml](../../apps.yml))*.

This role is responsible for:

1. Cloning application source code and trigger handlers when code changes are detected.
2. Build source code with default commands for each app type, optionally overriding depending on environment.
3. Configure dependent services on designated hosts. For example, create a mysql database, an virtualhost, and a solr core.

## Role Variables

This role is different from most, in that the role variables are derived from a special inventory of all the apps and environments managed by the platform.

  


## Dependencies

This role depends on the Ansible Inventory plugin `devshop_apps`. 

The plugin loads data from `apps.yml` and creates "virtual" ansible hosts for each application environment.

For example, with an app named `support` and environments named `dev` and `live`, Ansible hosts named `support.dev` and `support.live` will be added to the inventory.

In addition, all variables that are needed for the app to be configured will be populated.

## Example Platform

To create a DevShop Platform, you only need a playbook, host inventory, and app inventory.

    ---
    # playbook.yml    
    - name: Configure Hosts
      hosts: "!apps"
      become: yes
      gather_facts: yes

      roles:
        # Common configuration and metadata gathering.
        - devshop.host
 
        # Launches dependent roles and prepares them for use by apps.
        - devshop.services
    
    - name: Configure Apps
      hosts: apps
      become: yes
      gather_facts: yes
 
      roles:
        - devshop.app

### App Inventory

The `devshop_apps` inventory plugin reads a `apps.yml` file and generates hosts and groups for each environment:

    ---
    # apps.yml
    devshop_apps:
      ourapp:
        name: OurApp.com
        description: A super cool app everyone needs.
        git_repository: git@githost:org/ourappproject.git
        environments:
          production:
            git_reference: v1.0.0
            domains:
              - www.ourapp.com
              - ourapp.com
          dev:
            git_reference: develop


### Host Inventory

The DevShop Platform works by creating host groups that represent required "services".

Variables in the `devshop.services` role define a list of Ansible roles to install per service. If a host is in a group that has these roles defined, they will be added to the overall list of roles for that host.

Add hosts to your inventory in groups called `http` and `db` to tell the `devshop.services` role to configure `server.myapp.com` to run as a web and database server:

    # inventory.production
    [http]
    server.myapp.com
    
    [db]
    server.myapp.com

#### How it works

The `devshop.host` role parses the host groups and looks for variables with the name pattern `devshop_service_roles_{{ group }}`.

If that variable exists, it loads the list into that host's `devshop_host_roles` variable.

The `devshop.services` role then triggers the running of the `devshop_host_roles` using the `dependencies` feature.

**NOTE:** All dependant roles must be listed in `devshop.services/meta/main.yml` and use the `when` keyword to detect if that host wants to install that role.

For example, here are the `db` and `http` service roles (as defined in `devshop.host/defaults/main.yml`):

    ---
    devshop_service_roles_http:    
      - geerlingguy.apache
      - geerlingguy.php
      - geerlingguy.php-mysql
      - geerlingguy.php-versions
      - geerlingguy.composer
      - geerlingguy.drush

    devshop_service_roles_db:
      - geerlingguy.mysql

#### Custom Services

Using this model, you can easily create custom "services" by simply creating a variable with a list of roles and a matching host group:

Inventory:

    [myspecialservice]
    host.ourapp.com

Variables:

    devshop_service_roles_myspecialservice:
      - ourapp.common
      - ourapp.special


## License

MIT / BSD

## Author Information

This role was created in 2021 by [Jon Pugh](https://www.thinkdrop.net/).
