# Description

[Horizen](https://www.horizen.io/) (formerly known as Zencash) is a fork of [Zcash](https://z.cash) which is a fixed supply digital currency that uses [zk-SNARKs](https://z.cash/technology/zksnarks/) to provide strong on-chain privacy for digital payments.

This repo provides ansible roles that will configure a VPS or bare metal machine to host lxc containers that will each run an instance of the zend daemon and the secure node tracker client.

This was originally written for and tested against Ubuntu Xenial 16.04 and the [Contabo VPS instances](https://contabo.com/?show=vps), but has 
recently been updated to support Debian 11 "Bullseye" and tested on [Proxmox](https://pve.proxmox.com/)

# Requirements
* [Securenodes](https://securenodes2.na.zensystem.io/about)
* [Supernodes](https://supernodes1.na.zensystem.io/about)

Note that Supernodes must be publicly reachable via both IPv4 and IPv6.  Securenodes must be reachable via either IPv4 or IPv6.

All nodes must have a valid public SSL certificate.  These playbooks leverage [acme.sh](https://github.com/acmesh-official/acme.sh) to request free public TLS certificates.  Note that rather than expose TCP/80 to the Internet for TLS issuance, we are now leveraging the DNS API, and AWS Route53 is the first provider implemented.

Note also that any upstream firewalls / security groups will need to permit TCP/9033 to the nodes.

# Warning
This is a non-standard installation of zend and the nodetracker client. Don't ask for help regarding installation using this playbook in the official #securenodes channel. This playbook is targeted towards experts or people willing to learn how to manage their deployments using ansible in exchange for reducing your average cost per node.

# Security
Since the crypto space is full of scammers and hackers, security on your nodes is absolutely necessary. I've tried to make this playbook as secure as possible. If you see any possible improvements, open an issue or message on @techistheway in the Zencash Discord.
1. Uses LXC to separate the namespace
2. LXC containers are unpriviledged (WIP)
3. SSH is disabled to save ram. Consoles are possible with lxc-attach, or you can restart ssh using the utility playbooks.
4. ~~[ansible-hardening](https://github.com/openstack/ansible-hardening) role applies all applicable [STIGs](https://iase.disa.mil/stigs/Pages/index.aspx)~~
5. UFW firewall is configured to block everything except the ssh port and the zend port
6. ~~Fail2ban is installed and enabled~~
7. root login and password authentication is disabled
8. apparmor is enabled
9. If you use the vault to encrypt your inventory.yml as documented, all sensitive information in the playbook will be encrypted so your credentials are secure

# Configuration values
| Configuration Item | Example | Description |
| ----- | ------ | -----
| global_tracker_email | your_email@gmail.com | Email to receiver tracker alerts
| global_domain | your-nodes-address.com | The top level domain of your nodes
| secure_nodes_prefix | sec | Prefix for your secure nodes
| super_nodes_prefix | sup | Prefix for your super nodes.
| ipv6_subnet | 2a45:c456:4493:5534:c:c:c: | /64 subnet from your provider configured to a /112 . You can use any subnet other than 2a45:c456:4493:5534::1 . You can use any IP for your nodes except  2a45:c456:4493:5534:c:c:c:1
| ipv6_interface | eth0 | Public interface used for container network bridge
| ssh_public_key | ssh-rsa AAAAB3Nz..K7n8DX5dBeEQlEBN6fcVN your_user@ansible_controler | Public ssh key that will be used for connecting to the nodes
| blocks_directory | /root/chain | Directory containing seed of the blockchain
| ansible_become_pass | "super_secret_password" | ssh sudo password
| ansible_user | your_user | Username used for the ssh connection
| ansible_host | 173.1.1.1  or your-nodes-address.com| Address used to connect to master
| stake_address | znTyzLKM4VrWjSt8... | Transparent wallet address where ZEN used for nodes is staked from
| tracker_region | eu or na | Tracker server region to connect nodes to
| swap_size_gb | 0 | Size of swap file to add
| public_ipv4_netmask | 24 | Subnet size
| public_ipv4_address | 1.1.1.1 | IPv4 address used by super node. supernode01 should use the included IP, the rest can be assigned randomly
| private_ipv4_address | 10.0.3.201 | Private IP of the container tied to public address. These can be left alone unless your instance uses a different DHCP range
| private_ipv4_subnet |  10.0.3.0/24 | Private IP subnet 
| announce_ipv4_address|  1.2.3.4 | Public IP to announce to the p2p network. Required for AWS and other providers that do not assign a routable public IP to your instances.
| aws_access_key | AKIA.... | Your AWS access key with permissions to create records in Route53 for the global_domain.  Used by acme.sh
| aws_secret_access_key |  p/vfqt... | Your AWS seret access key.  Do NOT check these into a public repo

# Install instructions for Debian 11 hypervisor host
## Clone the repo
```
git clone https://github.com/alchemydc/ansible-zencash-nodes/
cd ansible-zencash-nodes/
```
## Install dependencies
`./install_host_deps.sh`
## Generate an SSH key to use for authenticating to the ansible controller
```
ssh-keygen -t id25519
cat ~/.ssh/id25519.pub >> ~/.ssh/authorized_keys
chmod 640 ~/.ssh/authorized_keys
```
## Edit inventory.yml
Be sure to set the stake addresses properly for each node

Fill out the values in the inventory.yml file and uncomment the nodes that you're going to deploy. Make sure your DNS matches.
Adjust the ansible_fqdn and container_fqdn and secure_nodes_prefix/super_nodes_prefix variables to match your naming scheme. These are variables so you don't have to fill out each value manually.
## Set swap size
Configure the `swap_size_gb` variable to the size of swap you want. The default is 0 GB.
## For supernodes
Each supernode require an additional publicly routable IPv4 address that will need to be entered in the corresponding public_ipv4_address field. Adjust announce_ipv4_address for each node as required.

## Run the playbook
```
ansible-playbook nodes.yml
```
## After nodes are created, generate and view the z addresses to send the challenge balances
```
ansible-playbook get-addresses.yml
```
## Send 3 transactions of .01 zen to the z addresses and restart nodetracker. With the 3 day challenge interval, this will last for a long time.
You can use one of the zend instances to send the challenge balance to the z address without a swing wallet.
```
zen-cli z_sendmany from_address '[{"address": "1st_to_address" ,"amount": 0.01},{"address": "2nd_to_address" ,"amount": 0.01}]'
```
## Attach to container console
```
dc@controller:/# lxc-attach -n sn1.example.com
```
## after transactions confirm, restart the tracker client to register your node and follow the logs
```
root@sn1:/# systemctl restart nodetracker
root@sn1:/# journalctl -f
```
# Maintenance procedures
## Adding a new host
Uncomment the appropriate section in the inventory and re-run the `nodes.yml` playbook. It'll only touch the things it needs to for the new nodes.
```
ansible-playbook nodes.yml
```
## Seeding block chain (to avoid p2p sync which is slow)
Create a folder that contains the `blocks` and `chainstate` folders inside it and set it in the `blocks_directory` variable in your `inventory.yml`.
```
dc@controller:/home/dc/nodes# ls /root/chain/
blocks  chainstate
```
## Encrypting vault & using password.sh
Once you've set up everyhthing inside your inventory.yml , you should encrypt it so that it's not just plaintext on the server.
```
ansible-vault encrypt inventory.yml
```
Save that password as you'll need it to run the playbooks.
So you don't have to continuously enter your password, you can set it in your environment variable.
```
source password.sh
```
## Failed run destroy container
```
lxc-stop -n container_name ; lxc-destroy -n container_name
```
## Stopping/Starting ssh
In an effort to save on ram and increase security slightly, I've set ssh to be disabled on startup.
To start ssh on the containers
```
ansible-playbook start-ssh.yml
```
## To stop ssh on the containers
```
ansible-playbook stop-ssh.yml
```
## Logging
zend is configured for syslog, and the containers are configured to send all their logs through syslog to the controller host.
## Inspecting logs
watching logs on the host:
```
tail -f /var/log/syslog | grep sn10
```
You can also just use `less` and use the "follow" feature by pressing `Shift+F`
```
less /var/log/syslog
# on keyboard press Shift+F
```
Getting all logs from a container
```
grep "sn1 " /var/log/syslog | less
```
Getting all nodetracker logs from a container
```
grep "sn1 " /var/log/syslog | less
```
getting all logs from a container
```
grep "sn1 " /var/log/syslog | less
```
## Logs inside container
View all zend, nodetracker and system logs from this boot
```
journalctl -b
```
Follow real time logs
```
journalctl -f
```
## systemd (system services)
I created systemd unit files for all service instead of using third party management tools.
### Restart zend
```
systemctl restart zend
```
### Restart nodetracker
```
systemctl restart nodetracker
```
## Nodes command
I added a `nodes-command` alias that basically performs a command through lxc on all the containers.
```
root@master:~# nodes-command "ps -ef"
Container:monitoring.zennodes.com
UID        PID  PPID  C STIME TTY          TIME CMD
root         1     0  0 00:09 ?        00:00:00 /sbin/init
root        37     1  0 00:09 ?        00:00:00 /lib/systemd/systemd-journald
syslog      88     1  0 00:09 ?        00:00:00 /usr/sbin/rsyslogd -n
root        92     1  0 00:09 ?        00:00:00 /usr/sbin/cron -f
root       165     1  0 00:09 ?        00:00:00 /usr/sbin/sshd -D
root       167     1  0 00:09 pts/0    00:00:00 /sbin/agetty --noclear --keep-baud pts/0 115200 38400 9600 vt220
root       168     1  0 00:09 pts/3    00:00:00 /sbin/agetty --noclear --keep-baud pts/3 115200 38400 9600 vt220
root       169     1  0 00:09 pts/1    00:00:00 /sbin/agetty --noclear --keep-baud pts/1 115200 38400 9600 vt220
root       170     1  0 00:09 pts/2    00:00:00 /sbin/agetty --noclear --keep-baud pts/2 115200 38400 9600 vt220
root       171     1  0 00:09 lxc/console 00:00:00 /sbin/agetty --noclear --keep-baud console 115200 38400 9600 vt220
root       281     1  0 00:09 ?        00:00:00 /sbin/dhclient -1 -v -pf /run/dhclient.eth0.pid -lf /var/lib/dhcp/dhclient.eth0.leases -I -df /var/lib/dhcp/dhclient6.e
grafana   4086     1  0 00:21 ?        00:00:02 /usr/sbin/grafana-server --config=/etc/grafana/grafana.ini --pidfile=/var/run/grafana/grafana-server.pid cfg:default.pa
root      4605     0  0 01:32 pts/1    00:00:00 ps -ef
Container:sec01.zennodes.com
UID        PID  PPID  C STIME TTY          TIME CMD
root         1     0  0 00:08 ?        00:00:01 /sbin/init
root        36     1  0 00:08 ?        00:00:02 /lib/systemd/systemd-journald
root        80     1  0 00:08 ?        00:00:00 /usr/sbin/cron -f
root       182     1  0 00:08 ?        00:00:00 /usr/sbin/sshd -D
root       185     1  0 00:08 pts/1    00:00:00 /sbin/agetty --noclear --keep-baud pts/1 115200 38400 9600 vt220
root       186     1  0 00:08 lxc/console 00:00:00 /sbin/agetty --noclear --keep-baud console 115200 38400 9600 vt220
root       187     1  0 00:08 pts/0    00:00:00 /sbin/agetty --noclear --keep-baud pts/0 115200 38400 9600 vt220
root       189     1  0 00:08 pts/3    00:00:00 /sbin/agetty --noclear --keep-baud pts/3 115200 38400 9600 vt220
root       191     1  0 00:08 pts/2    00:00:00 /sbin/agetty --noclear --keep-baud pts/2 115200 38400 9600 vt220
root       281     1  0 00:08 ?        00:00:00 /sbin/dhclient -1 -v -pf /run/dhclient.eth0.pid -lf /var/lib/dhcp/dhclient.eth0.leases -I -df /var/lib/dhcp/dhclient6.e
syslog    8070     1  0 00:16 ?        00:00:00 /usr/sbin/rsyslogd -n
zend      9247     1  0 00:20 ?        00:00:04 /usr/local/bin/node app.js
zend     13221     1  0 01:13 ?        00:00:37 /usr/bin/zend -printtoconsole -logtimestamps=0
root     13743     0  0 01:32 pts/1    00:00:00 ps -ef
```
You could also use ansible ad-hoc commands, so this is more of a convenience.
```
ansible controller -m shell -a "hostname"
```
```
controller01 | SUCCESS | rc=0 >>
Tue Jun 19 02:08:55 CEST 2018
```
## Get z addresses
Run the `get-addresses.yml` playbook to generate and display the z addresses to send the challenge balance.
## Get z address balances
Run the `get-balances.yml` playbook to display the z address balances for each of the nodes.
## Get private z addresses
Run the `dump-keys.yml` playbook to display the private z addresses so you can save them to a wallet.

# Donations
If you used this and saved a bunch of money, send the [original author](https://github.com/rmeleromira) of these tools some zen or eth!
## Zen
znZ2zopm9VuAKxXxjRpygwoqSNEffQp1iYx
## Ethereum
0xC720c150Bb757978Ba565912B891312190E6e9B4
