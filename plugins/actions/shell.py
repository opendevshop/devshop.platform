# Copyright: (c) 2021, DevShop Project
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#
# This action plugin extends ansible.builtin.shell to add options for controlling output.
#

from __future__ import (absolute_import, division, print_function)
__metaclass__ = type
import copy
import os
import errno

from ansible.plugins.action import ActionBase


class ActionModule(ActionBase):

    def run(self, tmp=None, task_vars=None):
        del tmp  # tmp no longer has any effect

        # Shell module is implemented via command with a special arg
        self._task.args['_uses_shell'] = True

        # Test to confirm that this plugin is loading.
        # Any invalid task args passed to the ansible.legacy.command action will fail.
        # self._task.args['will_break'] = True

        arg_output_file = self._task.args.get('output_file')
        arg_redirect_stderr = self._task.args.get('redirect_stderr')

        pipe = ">"
        if self._task.args.get('append'):
            pipe = ">>"
            del self._task.args['append']

        cmd = copy.copy(self._task.args['_raw_params'])
        if arg_output_file:
            cmd = "%s %s %s 2>&1" % (cmd, pipe, arg_output_file)
            del self._task.args['output_file']

        if arg_redirect_stderr:
            cmd = "%s 2 %s &1" % (cmd, pip)
            del self._task.args['redirect_stderr']

        self._task.args['_raw_params'] = cmd
        command_action = self._shared_loader_obj.action_loader.get('ansible.legacy.command',
                                                                   task=self._task,
                                                                   connection=self._connection,
                                                                   play_context=self._play_context,
                                                                   loader=self._loader,
                                                                   templar=self._templar,
                                                                   shared_loader_obj=self._shared_loader_obj)
        result = command_action.run(task_vars=task_vars)
        result['output_file'] = arg_output_file
        result['redirect_stderr'] = arg_redirect_stderr
        result['output_file_contents'] = False

        if arg_output_file:
            try:
                file_object = open(arg_output_file)
                result['output_file_contents'] = file_object.read()

            except OSError as e:
                if e.errno == errno.ENOENT:
                    output = {'exists': False}
                    module.exit_json(changed=False, stat=output)

        return result
