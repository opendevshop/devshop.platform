#!/usr/bin/python
# Copyright: (c) 2021 DevShop Project
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)
# originally copied from Ansible's service_facts module.

from __future__ import absolute_import, division, print_function
__metaclass__ = type


DOCUMENTATION = r'''
---
module: server_facts
short_description: Return server state information as fact data.
description:
     - Return server state information as fact data for App Hosts.
version_added: 0.1.0
requirements: ["devshop.platform collection."]

notes:
  - TODO

author:
  - Jon Pugh (@jonpugh)
'''

EXAMPLES = r'''
- name: Populate server facts
  ansible.builtin.server_facts:

- name: Print server facts
  ansible.builtin.debug:
    var: ansible_facts.servers
'''

RETURN = r'''
ansible_facts:
  description: Facts to add to ansible_facts about the servers and services that this host subscribes to.
  returned: always
  type: complex
  contains:
    servers:
      description: States of the services with service name as key.
      returned: always
      type: complex
      contains:
        inventory_hostname:
          description:
          - The name of the Server Host that this App Host is assigned.
          returned: always
          type: str
          sample: webserver1
        ansible_facts:
          description:
          - ansible_facts from the Server Host
          returned: always
          type: dict
'''


import platform
import re
from ansible.module_utils.basic import AnsibleModule


def main():
    # define available arguments/parameters a user can pass to the module
    module_args = dict(
        # name=dict(type='str', required=True),
    )

    # seed the result dict in the object
    # we primarily care about changed and state
    # changed is if this module effectively modified the target
    # state will include any data that you want your module to pass back
    # for consumption, for example, in a subsequent task

    # the AnsibleModule object will be our abstraction working with Ansible
    # this includes instantiation, a couple of common attr would be the
    # args/params passed to the execution, as well as if the module
    # supports check mode
    module = AnsibleModule(
        argument_spec=module_args,
        supports_check_mode=True
    )

    # if the user is working with this module in only check mode we do not
    # want to make any changes to the environment, just return the current
    # state with no modifications
    if module.check_mode:
        module.exit_json(**result)

    # manipulate or modify the state as needed (this is going to be the
    # part where your module will do what it needs to do)
#     result['original_message'] = module.params['name']
#     result['message'] = 'goodbye'
#     result['servers'] = {
#     }
    result = {}
    result['server_facts'] = {}
    result['server_facts']['apps'] = {}
    result['server_facts']['http'] = {}

    # in the event of a successful module execution, you will want to
    # simple AnsibleModule.exit_json(), passing the key/value results
    module.exit_json(**result)


if __name__ == '__main__':
    main()
