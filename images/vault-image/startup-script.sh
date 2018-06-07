#/bin/bash -e

set -o errexit
set -o xtrace
set -o pipefail


function initialize_vault {
  export VAULT_ADDR=http://127.0.0.1:8200
  cd /home/packer/
}
function get_Token {
  echo $(cat vault_tokens | sed -n $1p | cut -d ':' -f 2 | cut -d ' ' -f 2)
}
function unseal_vault {
  echo "--- Unsealing Vault Server ---"

  vault operator unseal $(get_Token 1)
  vault operator unseal $(get_Token 3)
  vault operator unseal $(get_Token 4)
}
function generate_new_token {
  echo $(vault token create -policy=mrm-policy | sed -n 3p | cut -d' ' -f 15)
}

function update_token {
  gcloud beta compute project-info add-metadata --metadata mrm_vault_auth_token=$(generate_new_token)
}
function auth_vault {
  echo "--- Authentication Vault Server ---"
  vault login $(get_Token 7)
  echo ">>> Vault Server Authenticated---"
}

function main {
  initialize_vault
  unseal_vault
  auth_vault
  update_token
}

main "$@"
