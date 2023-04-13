#!/usr/bin/env sh

#
# This is a wrapper for devshop-ansible-playbook.sh.
#
# Create a symlink to this file in your platform codebase.
# 

# Support bash to support `source` with fallback on $0 if this does not run with bash
# https://stackoverflow.com/a/35006505/6512
selfArg="$BASH_SOURCE"
if [ -z "$selfArg" ]; then
    selfArg="$0"
fi
self=$(realpath $selfArg 2> /dev/null)
if [ -z "$self" ]; then
    self="$selfArg"
fi

dir=$(cd "${self%[/\\]*}" > /dev/null; cd './scripts' && pwd)

echo $dir
bash "${dir}/devshop-ansible-playbook.sh" "$@"
