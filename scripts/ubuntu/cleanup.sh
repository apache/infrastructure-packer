#!/bin/sh -eux

# Delete all Linux headers
dpkg --list \
  | awk '{ print $2 }' \
  | grep 'linux-headers' \
  | xargs apt-get -y purge;

# Remove specific Linux kernels, such as linux-image-3.11.0-15-generic but
# keeps the current kernel and does not touch the virtual packages,
# e.g. 'linux-image-generic', etc.
dpkg --list \
    | awk '{ print $2 }' \
    | grep 'linux-image-3.*-generic' \
    | grep -v `uname -r` \
    | xargs apt-get -y purge;

# Delete Linux source
dpkg --list \
    | awk '{ print $2 }' \
    | grep linux-source \
    | xargs apt-get -y purge;

# Delete development packages
dpkg --list \
    | awk '{ print $2 }' \
    | grep -- '-dev$' \
    | xargs apt-get -y purge;

# Delete compilers and other development tools
apt-get -y purge cpp gcc g++;

# Delete X11 libraries
apt-get -y purge libx11-data xauth libxmuu1 libxcb1 libx11-6 libxext6;

# Delete obsolete networking
apt-get -y purge ppp pppconfig pppoeconf;

# Delete oddities
apt-get -y purge popularity-contest;

apt-get -y autoremove;
apt-get -y clean;

# clean up lingering cache files
rm -f /etc/apt/apt.conf.d/01proxy

# Cleanup puppet certs
find /etc/puppet -iname "*base*" -delete
find /var/lib/puppet/ -iname "*apache.org*" -type f -delete

# Finally, enable puppet
puppet agent --enable

# Make sure ssh host keys get regen'd at instance startup
cat > /etc/dhcp/dhclient-exit-hooks.d/sethostname <<'EOM'
#!/bin/sh
# dhclient change hostname script for Ubuntu
# /etc/dhcp/dhclient-exit-hooks.d/sethostname
# logs in /var/log/upstart/network-interface-eth0.log

# for debugging:
echo "cloudstack-sethostname BEGIN"
export
set -x

if [ $reason = "BOUND" ]; then
    echo new_ip_address=$new_ip_address
    echo new_host_name=$new_host_name
    echo new_domain_name=$new_domain_name

    oldhostname=$(hostname -s)
    if [ $oldhostname != 'localhost' ]; then

        # Rename Host
        echo $new_host_name > /etc/hostname
        hostname -F /etc/hostname

        # Update /etc/hosts if needed
        TMPHOSTS=/etc/hosts.dhcp.new
        if ! grep "$new_ip_address $new_host_name.$new_domain_name $new_host_name" /etc/hosts; then
            # Remove the 127.0.1.1 put there by the debian installer
            grep -v '127\.0\.1\.1 ' < /etc/hosts > $TMPHOSTS
            # Add the our new ip address and name
            echo "$new_ip_address $new_host_name.$new_domain_name $new_host_name" >> $TMPHOSTS
            mv $TMPHOSTS /etc/hosts
        fi

        # Recreate SSH2 keys
        export DEBIAN_FRONTEND=noninteractive 
        dpkg-reconfigure openssh-server
    fi
fi
echo "cloudstack-sethostname END"
EOM

# set perms on script
chmod 774  /etc/dhcp/dhclient-exit-hooks.d/sethostname

# Reset hostname
hostname localhost
echo "localhost" > /etc/hostname

cat << \EOF > /etc/hosts
127.0.0.1   localhost

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters

EOF

# Cleanup log files
cat /dev/null > /var/log/wtmp 2>/dev/null
logrotate -f /etc/logrotate.conf 2>/dev/null
find /var/log -type f -delete
rm -f /var/lib/dhcp/dhclient.*
