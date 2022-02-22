#!/usr/bin/env bash

# USAGE: bash run.sh servers setup

hosts_available=(servers workstations)
tags_available=(setup update)

function usage() {
    printf '%s\n' \
"Usage:

bash run.sh [host tag] [--deploy-ssh] [--debug] [--step] [--start-at-task task]

bash run.sh
    Will return list of hosts, tags, and tasks

bash run.sh workstation setup
    Will run: ansible-playbook playbook.yml --limit workstations --tags setup

"
}

while [[ "$#" -gt 0 ]]; do
    [[ " ${hosts_available[*]} " =~ " ${1} " ]] && limit="--limit ${1}"
    [[ " ${tags_available[*]} "  =~ " ${1} " ]] && tags="--tags ${1}"
    case "${1-}" in
        --deploy-ssh)       limit="--limit servers"; tags="--tags ssh" ;;
        --debug)            debug="--check -vvv" ;;
        --step)             step="--step" ;;
        --start-at-task)    start_at_task="--start-at-task ${2-}"; shift ;;
        --help|-h|/h)       usage; exit 0 ;;
    esac
    shift
done

clear
if [[ -n ${limit} && -n ${tags} ]]; then
    set -x
    ansible-playbook ${debug} ${step} ${start_at_task} \
    playbook.yml \
    ${limit} \
    ${tags}
    set +x
else
    set -x
    ansible-playbook playbook.yml --list-hosts
    ansible-playbook playbook.yml --list-tags
    ansible-playbook playbook.yml --list-tasks
    set +x
fi
