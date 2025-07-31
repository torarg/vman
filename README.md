# vman
vman manages OpenBSD vms.

## features
- create and delete vms
- vms are autoinstalled with the configured OpenBSD release
- vms are owned by the executing user
- locally managed vm configuration to include in /etc/vm.conf

## requirements
- vmd
- web server serving the configured web root

## quick start

For the sake of this tutorial we'll assume that your executing
user will be `_vman` with the primary group `_vman`.

Configure httpd for autoinstall (as root)
```
# mkdir /var/www/htdocs/vman
# chown www:_vman
# cat > /etc/httpd.conf <<EOF
server "default" {
        listen on * port 80
        location "/*install.conf" {
                root "/htdocs/vman"
                pass
        }
}
# rcctl enable httpd && rcctl start httpd
```


Setup doas.conf (as root)
```
# cat >> /etc/doas.conf <<EOF
permit nopass _vman as root cmd /usr/sbin/vmctl args load
permit nopass _vman as root cmd /usr/sbin/vmctl args reload
EOF
```

Setup bridge interface (as root)
```
# cat > /etc/hostname.vport0 <<EOF
inet 192.168.10.254/24
description "veb0 host port"
up
EOF

# cat > /etc/hostname.veb0 <<EOF
add vport0
description "vm network bridge"
up
EOF

# sh /etc/netstart vport0 veb0
```

Initialize vman (as user)
```
$ vman init
Setting up base directory (/home/_vman/vman)...
Writing default config to /home/_vman/.vmanrc
Fetching installsets...
Initialization finished.

To get started, please do the following:
  - define a switch named 'vm-network' in /etc/vm.conf
  - include /home/_vman/vman/vm.conf in /etc/vm.conf
  - check configuration in /home/_vman/.vmanrc
  - create and serve /var/www/htdocs/vman on port 80
  - ensure you got write access to /var/www/htdocs/vman
  - ensure you got doas permissions for vmctl load|reload
```

The init command created a base directory, fetched the latest install set
for -current and setup some default configuration files.

Have a look at the generated config files and adapt them to your needs:

autoinstall config
```
$ cat ~/vman/install.conf
Which network interface = vio0
Which disk is the root disk = sd0
IPv4 address = dhcp
IPv6 address = autoconf
Password for root = *************
Allow root ssh login = prohibit-password
Setup a user = no
What timezone are you in = Europe/Berlin
Location of sets = disk
Is the disk partition already mounted = no
Continue without verification = yes
```

vman config
```
$ cat ~/.vmanrc
WEBROOT="/var/www/htdocs/vman"
BASE_DIR="/home/_vman/vman"
VM_SWITCH="vm-network" # default vm network, can be overriden via cli
OWNER="_vman"
INSTALLSET_URL="https://ftp.spline.de/pub/OpenBSD/snapshots/amd64"
SSH_PUBKEY="/home/_vman/.ssh/id_ed25519.pub"
```


Configure vmd (as root)
```
# cat > /etc/vm.conf <<EOF
switch "vm-network" {
        interface veb0
}

include "/home/_vman/vman/vm.conf"
EOF

# rcctl enable vmd && rcctl start vmd
```

Create vm (as user)
```
$ vman add -s 10g -m 2g new-vm
```
