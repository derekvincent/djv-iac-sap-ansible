#/bin/bash

  ssm_key="$1"; shift
  ssh-agent bash -o pipefail -c '
    if aws ssm get-parameter \
         --with-decryption \
         --name "'$ssm_key'" \
         --output text \
         --query Parameter.Value |
       ssh-add -
    then
      ansible-playbook "$@"
    else
      echo >&2 "ERROR: Failed to get or add key: '$ssm_key'"
      exit 1
    fi
  ' bash "$@"