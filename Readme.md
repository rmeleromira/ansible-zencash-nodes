# Description

This repo is comprised of several ansible roles that will configure a VPS to be a host of lxc containers that will each run an instance of the zend daemon and the secure node tracker client. Supernodes v1 are supported.

This is written for and tested against Ubuntu Xenial 16.04 and the [Contabo VPS instances](https://contabo.com/?show=vps).

This playbook is written to host securenodes and supernodes as securely as possible.

I've been able to fit 15 containers on a single contabo VPS instance that costs $8.99 EUR a month. It's fairly profitable.

I Currently have 3 super nodes and 1 secure node on the 24 GB RAM VPS from contabo.
# Warning
This is a non-standard installation of zend and the nodetracker client. Don't ask for help regarding installation using this playbook in the official #securenodes channel. This playbook is targeted towards experts or people willing to learn how to manage their deployments using ansible in exchange for reducing your average cost per node.
# Security
Since the crypto space is full of scammers and hackers, security on your nodes is absolutely necessary. I've tried to make this playbook as secure as possible. If you see any possible improvements, open an issue or message on @techistheway in the Zencash Discord.
1. Uses LXC to seperate the namespace
2. LXC containers are unpriviledged (WIP)
3. SSH is disabled to save ram. Consoles are possible with lxc-attach, or you can restart ssh using the utility playbooks.
4. [ansible-hardening](https://github.com/openstack/ansible-hardening) role applies all applicable [STIGs](https://iase.disa.mil/stigs/Pages/index.aspx)
5. UFW firewall is configured to block everything except the ssh port
6. Fail2ban is installed and enabled
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
| swap_size_gb | 60 | Size of swap file to add
| public_ipv4_netmask | 24 | Subnet size
| public_ipv4_address | 1.1.1.1 | IPv4 address used by super node. supernode01 should use the included IP, the rest can be assigned randomly
| private_ipv4_address | 10.0.3.201 | Private IP of the container tied to public address. These can be left alone unless your instance uses a different DHCP range
# Install
## Since this uses ansible, install it
```
# Instructions for ubuntu 16.04
apt-get update
apt-get install python3 python3-pip python-lxc libssl-dev git -y
pip3 install --upgrade setuptools
pip3 install ansible
pip3 install -U cryptography
```
## ssh to your VPS with default root credentials provided in email
```
ssh root@1.1.1.1
```
## Create user and populate populate key.
```
export user=your_user
# quotes are important here
export ssh_pub_key="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC12Zn+Xbnw..."
```
## Create user and set a strong password
```
adduser $user
```
## Give user sudo access, make ssh directory, populate key
```
usermod -aG sudo $user
mkdir /home/$user/.ssh
echo $ssh_pub_key >> /home/$user/.ssh/authorized_keys
chown $user:$user -R /home/$user/
```
### You can run the playbook locally on the node, or preferably from a remote host.
## Clone the repo
```
# Don't remove the --recurse-submodules
git clone --recurse-submodules https://github.com/rmeleromira/ansible-zencash-nodes/
cd ansible-zencash-nodes/
```
### Fill out the values in the inventory.yml file and uncomment the nodes that you're going to deploy. Make sure your DNS matches.
### Adjust the ansible_fqdn and secure_nodes_prefix/super_nodes_prefix variables to match your naming scheme. There's variables so you don't have to fill out each value manually.
## Set swap size
Configure the `swap_size_gb` variable to the size of swap you want. The default is 60 GB. The VPS M instance can host about 12-15 secure nodes or 2-4 supernodes with 60 GB swap. The VPS L can host 25-30 secure nodes or 4-8 supernodes with 90 GB swap.
## For supernodes
Make sure you fill out supnode01 as the host that uses the default IP that came with your VPS.
Each supernode will require an additional IPv4 address that will need to be entered in the corresponding public_ipv4_address field. Contabo charges 2 EUR per IP per month.
## Run the playbook
```
ansible-playbook nodes.yml
```
## After nodes are created, generate and view the z addresses to send the challenge balances
```
ansible-playbook get-addresses.yml
```
### Send 3 transactions of .01 zen to the z addresses and restart nodetracker. With the 3 day challenge interval, this will last for a long time.
You can use one of the zend instances to send the challenge balance to the z address without a swing wallet.
```
zen-cli z_sendmany from_address '[{"address": "1st_to_address" ,"amount": 0.01},{"address": "2nd_to_address" ,"amount": 0.01}]'
```
## Attach to container console
```
root@master:/# lxc-attach -n sn1.example.com
```
## after transactions confirm, restart the tracker client to register your node and follow the logs
```
root@sn1:/# systemctl restart nodetracker
root@sn1:/# journalctl -f
```
# Adding a new host
Uncomment the appropriate section in the inventory and re-run the `nodes.yml` playbook. It'll only touch the things it needs to for the new nodes.
```
ansible-playbook nodes.yml
```
# Seeding block chain
Create a folder that contains the `blocks` and `chainstate` folders inside it and set it in the `blocks_directory` variable in your `inventory.yml`.
```
root@master:/home/rmelero/nodes# ls /root/chain/
blocks  chainstate
```
# Encrypting vault & using password.sh
Once you've set up everyhthing inside your inventory.yml , you should encrypt it so that it's not just plaintext on the server.
```
ansible-vault encrypt inventory.yml
```
Save that password as you'll need it to run the playbooks.
So you don't have to continuously enter your password, you can set it in your environment variable.
```
source password.sh
```
# Failed run destroy container
```
lxc-stop -n container_name ; lxc-destroy -n container_name
```
# Stopping/Starting ssh
### In an effort to save on ram and increase security slightly, I've set ssh to be disabled on startup.
## To start ssh on the containers
```
ansible-playbook start-ssh.yml
```
## To stop ssh on the containers
```
ansible-playbook stop-ssh.yml
```
# Logging
zend is configured for syslog, and the containers are configured to send all their logs through syslog to the host.
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
# systemd (system services)
I created systemd unit files for all service instead of using third party management tools.
## Restarting Services
### Restart zend
```
systemctl restart zend
```
### Restart nodetracker
```
systemctl restart nodetracker
```
# Nodes command
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
ansible master -m shell -a "hostname"
```
```
master01 | SUCCESS | rc=0 >>
Tue Jun 19 02:08:55 CEST 2018
```
# Get z addresses
Run the `get-addresses.yml` playbook to generate and display the z addresses to send the challenge balance.
# Get z address balances
Run the `get-balances.yml` playbook to display the z address balances for each of the nodes.
# Get private z addresses
Run the `dump-keys.yml` playbook to display the private z addresses so you can save them to a wallet.
# Upcoming features
* Read logs through journal
  * Currently, logs only end up in /var/log/syslog. The need to be piped to the journal somehow.

# Donations
If you used this and saved a bunch of money, send me some zen or eth!
## Zen
znZ2zopm9VuAKxXxjRpygwoqSNEffQp1iYx
## Ethereum
0xC720c150Bb757978Ba565912B891312190E6e9B4
