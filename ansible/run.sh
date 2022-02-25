#!/usr/bin/env bash

# USAGE: bash run.sh --debug
#   bash run.sh servers setup
#   bash run.sh --deploy-ssh
#

hosts_available=(servers workstations)
tags_available=(setup update)

function usage() {
    printf '%s\n' \
"Usage:

bash run.sh [<HOST> <TAG>] [--deploy-ssh] [--debug] [--step] [--start-at-task TASK] [--args ARGUMENTS] [-h | --help]

bash run.sh
    Will return list of hosts, tags, and tasks

bash run.sh workstations setup
    Will run: ansible-playbook playbook.yml --limit workstations --tags setup

bash run.sh --deploy-ssh
    Will run: ansible-playbook deploy_ssh.yml --limit localhost
              ansible-playbook deploy_ssh.yml --ask-pass --limit 'all:!localhost'

bash run.sh workstations setup --debug --step --start-at-task 'here is a task' --args --ask-pass
    Will run: ansible-playbook playbook.yml --limit workstations --tags setup --chech -vvv --step
              --start-at-task 'here is a task' --args --ask-pass

"
}

while [[ "$#" -gt 0 ]]; do
    [[ " ${hosts_available[*]} " =~ " ${1} " ]] && limit="--limit ${1}"
    [[ " ${tags_available[*]} "  =~ " ${1} " ]] && tags="--tags ${1}"
    case "${1-}" in
        --debug)            debug="--check -vvv" ;;
        --step)             step="--step" ;;
        --deploy-ssh)       deploy=true ;;
        --args)             args="${2-}"; shift ;;
        --start-at-task)    start_at_task="--start-at-task ${2-}"; shift ;;
        --help|-h|/h)       usage; exit 0 ;;
    esac
    shift
done

clear
if [[ -n ${limit} && -n ${tags} ]]; then
    set -x
    ansible-playbook playbook.yml ${debug} ${step} ${opt} ${start_at_task} ${limit} ${tags} ${args}
    set +x
elif [[ ${deploy} ]]; then
    set -x
    ansible-playbook deploy_ssh.yml --limit localhost ${args}
    ansible-playbook deploy_ssh.yml --ask-pass --limit "all:!localhost" ${args}
    set +x

else
    set -x
    ansible-playbook playbook.yml --list-hosts
    ansible-playbook playbook.yml --list-tags
    ansible-playbook playbook.yml --list-tasks
    set +x
fi
