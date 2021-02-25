#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ANSIBLE_DIR="$( cd "$SCRIPT_DIR/../ansible" && pwd )"
VALUES_DIR="$(cd "$SCRIPT_DIR/../values" && pwd)"

ZAUTH_CONTAINER="${ZAUTH_CONTAINER:-quay.io/wire/zauth:latest}"

zrest="$(tr -dc A-Za-z0-9 </dev/urandom | head -c 64)"

minio_access_key="$(tr -dc A-Za-z0-9 </dev/urandom | head -c 20)"
minio_secret_key="$(tr -dc A-Za-z0-9 </dev/urandom | head -c 42)"

zauth="$(sudo docker run $ZAUTH_CONTAINER -m gen-keypair -i 1)"

zauth_public=$(echo "$zauth" | awk '{ print $2}')
zauth_private=$(echo "$zauth" | awk '{ print $2}')


if [[ ! -f $VALUES_DIR/wire-server/secrets.yaml ]]; then
  echo "Writing $VALUES_DIR/wire-server/secrets.yaml"
  cat <<EOF > $VALUES_DIR/wire-server/secrets.yaml
brig:
  secrets:
    smtpPassword: dummyPassword
    zAuth:
      publicKeys: "$zauth_public"
      privateKeys: "$zauth_private"
    turn:
      secret: "$zrest"
    awsKeyId: dummykey
    awsSecretKey: dummysecret
cargohold:
  secrets:
    awsKeyId: "$minio_access_key"
    awsSecretKey: "$minio_secret_key"
galley:
  secrets:
    awsKeyId: dummykey
    awsSecretKey: dummysecret
gundeck:
  secrets:
    awsKeyId: dummykey
    awsSecretKey: dummysecret
nginz:
  secrets:
    zAuth:
      publicKeys: "$zauth_public"
EOF

fi

if [[ ! -f $ANSIBLE_DIR/inventory/offline/group_vars/all/secrets.yaml ]]; then
  echo "Writing $ANSIBLE_DIR/inventory/offline/group_vars/all/secrets.yaml"
  cat << EOT > $ANSIBLE_DIR/inventory/offline/group_vars/all/secrets.yaml
restund_zrest_secret: "$zrest"
minio_access_key: "$minio_access_key"
minio_secret_key: "$minio_secret_key"
EOT
fi
