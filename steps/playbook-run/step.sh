#!/bin/bash
set -euo pipefail

mkdir -p /root/.ssh /etc/ansible
cat >/etc/ansible/ansible.cfg <<'EOF'
[defaults]
host_key_checking = False

[ssh_connection]
control_path_dir=/dev/shm/ansible_control_path
EOF

directory="$(ni get -p '{ .directory }')"

git="$(ni get -p '{ .git }')"
if [[ -n "${git}" ]]; then
  ni git clone
  directory="/workspace/$(ni get -p '{ .git.name }')/${directory}"
fi

declare -a galaxy_collections="( $(ni get | jq -r 'try .galaxy.collections[] | @sh') )"

declare -a playbook_args

ni get -p '{ .ssh.connection.sshKey }' >/workspace/id_rsa
if [[ "$( wc -c </workspace/id_rsa )" -gt 0 ]]; then
  chmod 0400 /workspace/id_rsa
  playbook_args+=( --private-key /workspace/id_rsa )
fi

declare -a inventories="( $(ni get | jq -r 'try .inventories[] | ["-i", .] | @sh') )"
[[ ${#inventories[@]} -gt 0 ]] && playbook_args+=( "${inventories[@]}" )

extra_vars="$( ni get | jq -c 'try .extraVars // empty' )"
[[ -n "${extra_vars}" ]] && playbook_args+=( -e "${extra_vars}" )

declare -a playbooks="( $(ni get | jq -r 'try .playbooks[] | @sh' ) )"
[[ ${#playbooks[@]} -gt 0 ]] && playbook_args+=( "${playbooks[@]}" )

cd "${directory}"

for galaxy_collection in "${galaxy_collections[@]}"; do
  ansible-galaxy collection install "${galaxy_collection}"
done

exec ansible-playbook "${playbook_args[@]}"
