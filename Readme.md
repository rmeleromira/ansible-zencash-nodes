# Description

This repo is comprised of two ansible roles that will configure a VPS to be a host of lxc containers that will each run an instance of the zen daemon and the secure node tracker client.

This is written for and tested against Ubuntu Xenial 16.04.

I've been able to fit 15 containers on a single contabo VPS instance that costs $8.99 EUR a month. It's fairly profitable.


# Install

Since this uses ansible, install it

```
apt-get update
apt-get install python3-pip python-lxc libssl-dev git -y
pip3 install ansible
pip3 install -U cryptography
```

Copy the example inventory and secrets file and fill out the values in the secrets file and uncomment the nodes that you're going to deploy in the inventory .yml. Make sure your DNS matches

Run the playbook

```
ansible-playbook nodes.yml
```


```
# attach to container console
root@master:/# lxc-attach -n sn1.example.com

# generate new address and send 2-4 transactions of .1 zen
root@sn1:/# zen-cli z_getnewaddress
zcDuCXD92GEzQWoRXGbk9Dd8ttDXsRnCgCECau3rqfixQYokYxZqew41LXfU93Cyjv2T42KULD3ufvCGUrpiUNPWNfSouKh

# Dump and save private key for challenges
root@sn1:/# zen-cli z_exportkey zcDuCXD92GEzQWoRXGbk9Dd8ttDXsRnCgCECau3rqfixQYokYxZqew41LXfU93Cyjv2T42KULD3ufvCGUrpiUNPWNfSouKh
SKxszF9NLXBUh5i8vzcjze6aJ1NS7kbyuZbvmFgCm9EUBjQo6tFL

# after transactions confirm, restart the tracker client to register your node
root@sn1:/# systemctl restart secnodetracker
```

# Adding a new host

Uncomment the appropriate section in the inventory



# Seeding block chain

Create a folder that contains the `blocks` and `chainstate` folders inside it and set it in the `vault_blocks_directory` variable in your `secrets.yml`.

```
root@master:/home/rmelero/nodes# ls /root/chain/
blocks  chainstate
```

# Upcoming features

## Read logs through journal

Currently, logs only end up in /var/log/syslog. The need to be piped to the journal somehow.

## ability to migrate using priv

Given a private key or wallet.dat stake address and nodeid, add the ability to migrate hosts.

## handle z_getnewaddress and dumping private key

Currently, the automation gets you to the point where you can get a new z address

# encrypting vault & using password.sh

Once you've set up everyhting inside your secrets.yml , you should encrypt it so that it's not just plaintext on the server.

```
ansible-vault encrypt secrets.yml
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

In an effort to save on ram and increase security slightly, I've set ssh to be disabled on startup.

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

watching logs the host:

```

tail -f /var/log/syslog | grep sn10
```

You can also just use `less and use the "follow" feature by pressing `Shift+F`


getting all logs from a container 

```
grep "sn1 " /var/log/syslog | less
```
getting all secnodetracker
logs from a container 

```
grep "sn1 " /var/log/syslog | less
```
getting all logs from a container 

```
grep "sn1 " /var/log/syslog | less
```

# systemd (system services)

I created systemd unit files for all service instead of using third party management tools.

## Service

### Restart zend



# Nodes command

I have added a `nodes-command` alias that basically performs a command through lxc on all the containers.


