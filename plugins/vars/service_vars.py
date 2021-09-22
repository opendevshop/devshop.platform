# Copyright 2019 RedHat, inc
#
# This file is part of Ansible
#
# Ansible is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Ansible is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Ansible.  If not, see <http://www.gnu.org/licenses/>.
#############################################
from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

DOCUMENTATION = '''
    name: devshop.platform.service_vars
    version_added: 0.1.0
    short_description: Load service variables into app hosts.
    description: Load service variables into app hosts.
    options:
      stage:
        ini:
          - key: stage
            section: vars_service_vars
            default: all
        env:
          - name: ANSIBLE_VARS_PLUGIN_STAGE
    extends_documentation_fragment:
      - vars_plugin_staging
'''

ERROR_SERVICE_GROUP_MISSING_DATA = '''
    From devshop.platform.service_vars: The Host Group '%s' is a child of 'servers', but it
    is missing the required variable '%s'. If the group '%s' is not intended to be a service
    group, remove it from the parent group 'servers'. If the group '%s' *is* intended to be
    a Service Group, add the variable '%s'.
'''

from ansible.errors import AnsibleParserError
from ansible.plugins.vars import BaseVarsPlugin
from ansible.inventory.host import Host
from ansible.inventory.group import Group


class VarsModule(BaseVarsPlugin):

    REQUIRES_ENABLED = True

    def __init__(self):
        """ constructor """
        super(VarsModule, self).__init__()
        self.apps = {}
        self.services = {}
        self.servers = {}

    def get_vars(self, loader, path, entities, cache=True):
        super(VarsModule, self).get_vars(loader, path, entities)

        vars = {}

        for entity in entities:
            self._display.debug('get_vars %s entity: %s ' % (type(entity), entity))

            if isinstance(entity, Host):
                self._display.debug('app host groups: %s ' % (entity.groups))

                for group in entity.groups:
                    if group.name == 'apps':
                        self._display.v('Found app host: %s ' % entity)
                        self.apps[entity] = entity
                        vars['devshop_app_servers'] = {}

                        # @TODO: Load services from app type thing.
                        service_requirements = entity.vars.get("devshop_app_service_requirements") or group.vars.get("devshop_app_service_requirements")

                        if not service_requirements:
                            self._display.warning('Unable to determine service requirements from "app" group or host "%s" \
                                Add the variable "devshop_app_service_requirements" to resolve.')
                        else:
                            for service in service_requirements:

                                # If inventory var defines the server to use.
                                app_service_server = (
                                    entity.vars.get("devshop_app_server_%s" % service)
                                    or group.vars.get("devshop_app_server_%s" % service)
                                    or None
                                )

                                if not entity.vars.get("devshop_app_server_%s" % service):
                                    vars["devshop_app_server_%s" % service] = app_service_server

                                vars['devshop_app_servers'][service] = app_service_server

                        if not entity.vars.get('devshop_app_name'):
                            vars['devshop_app_name'] = 'app'

                        if not entity.vars.get('devshop_app_environment'):
                            vars['devshop_app_environment'] = 'default'

                    if group.name == 'servers':
                        self._display.v('Found server host: %s ' % entity)
                        self.servers[entity] = entity

                        # Loop through all of the Server Host's groups.
                        # @TODO: Load common roles
                        devshop_host_services = []
                        devshop_host_roles = []

                        for service_group in entity.groups:

                            # If this is a service group, add to the list of this hosts services.
                            if service_group.vars.get('devshop_service_%s' % service_group):
                                devshop_service_meta = service_group.vars.get('devshop_service_%s' % service_group)
                                self._display.v('Found server service: %s ' % devshop_service_meta)
                                if devshop_service_meta.get('no_service'):
                                    self._display.v('no_service was set for %s. Not adding to this servers advertised services.' % devshop_service_meta)
                                else:
                                    devshop_host_services.append("%s" % service_group)
                                if devshop_service_meta.get('roles'):
                                    devshop_host_roles = devshop_host_roles + devshop_service_meta.get('roles')

                        # Save list of services this server offers.
                        vars['devshop_host_services'] = devshop_host_services
                        vars['devshop_host_roles'] = devshop_host_roles

                        # @TODO:
                        # Set facts:
                        #   - devshop_host_services
                        #   - devshop_host_roles
                        #   - devshop_host_apps

            elif isinstance(entity, Group):
                self._display.debug('parent_groups: %s ' % (entity.parent_groups))

                for parent in entity.parent_groups:
                    if parent.name == 'servers':
                        variable_name = 'devshop_service_%s' % entity
                        if variable_name not in entity.vars:
                            raise AnsibleParserError(ERROR_SERVICE_GROUP_MISSING_DATA % (entity, variable_name, entity, entity, variable_name))

                        self._display.v('Found service group: %s (%s)' % (entity, path))
                        self.services[entity] = entity

            else:
                raise AnsibleParserError("Supplied entity must be Host or Group, got %s instead" % (type(entity)))

        return vars
