#!/bin/bash
set -x

# whole script should run as root, and be chmod 750 root:root

# split acme cert chain into individual certs and write to /usr/local/share/ca-certificates
cat /home/zend/.acme.sh/{{container_fqdn}}/fullchain.cer \
| awk 'split_after==1{n++;split_after=0} /-----END CERTIFICATE-----/ {split_after=1} {print > "/usr/local/share/ca-certificates/le-intermediate-cert" n ".crt"}'

# update CA certs to pickup the new ones
/usr/sbin/update-ca-certificates --fresh

# restart zend
systemctl restart zend
