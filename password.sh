#!/bin/bash
if [[ -v ANSIBLE_VAULT_PASS ]]
#if ${ANSIBLE_VAULT_PASS+"false"}
then
  echo $ANSIBLE_VAULT_PASS
else
  read -p "enter vault password:" password
  echo $password
  export ANSIBLE_VAULT_PASS="$password"
fi
