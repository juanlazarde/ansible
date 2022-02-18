#!/usr/bin/env bash

# USAGE: bash run.sh servers setup

hosts_available=(servers workstations)
tags_available=(setup update)

while [[ "$#" -gt 0 ]]; do
    for host in "${hosts_available[@]}"; do
        [[ "${1-}" == "--${host}" || "${1-}" == "${host}" ]] && limit="${host}"
    done
    for tag in "${tags_available[@]}"; do
        [[ "${1-}" == "--${tag}" || "${1-}" == "${tag}" ]] && tags="${tag}"
    done
    case "${1-}" in
        --deploy-ssh|deploy-ssh)    limit="servers"; tags="ssh" ;;
        --debug)                    debug="--check -vvv" ;;
        --step)                     step="--step" ;;
        --start-at-task)            start_at_task="--start-at-task '${2-}'"; shift ;;
    esac
    shift
done

clear
if [[ -n ${limit} && -n ${tags} ]]; then
    set -x
    ansible-playbook ${debug} ${step} ${start_at_task} \
    playbook.yml \
    --ask-become-pass --vault-password-file ~/.vault_key \
    --limit "${limit}" \
    --tags "${tags}"
    set +x
else
    set -x
    ansible-playbook playbook.yml --list-hosts
    ansible-playbook playbook.yml --list-tags
    ansible-playbook playbook.yml --list-tasks
    set +x
fi
