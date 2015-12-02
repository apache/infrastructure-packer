#!/bin/bash -eux

PUPPET_REPO='https://github.com/stumped2/infrastructure-puppet.git'
PUPPET_BRANCH='packer'

# bake backup of current puppet folder
mv /etc/puppet /etc/puppet.bak

# Check out infrastructure-puppet repo
git clone $PUPPET_REPO --branch $PUPPET_BRANCH --single-branch /etc/puppet

# install this gem for bootstrapping
gem install --no-ri --no-rdoc r10k

# Grab all 3rdParty puppet modules
cd /etc/puppet
bin/pull $PUPPET_BRANCH

# Link all the 3rdParty modules for apply
for i in $(ls /etc/puppet/3rdParty);
do
    ln -s /etc/puppet/3rdParty/$i /etc/puppet/modules/
done

# bootstrap puppet
puppet apply /etc/puppet/manifests/site.pp --modulepath=/etc/puppet/modules --manifestdir=/etc/puppet/manifests --hiera_config=/etc/puppet/hiera.yaml

# run it again to make sure everything applied cleanly
puppet apply /etc/puppet/manifests/site.pp --modulepath=/etc/puppet/modules --manifestdir=/etc/puppet/manifests --hiera_config=/etc/puppet/hiera.yaml

# remove installed gems
for i in colored cri log4r multi_json multipart faraday faraday_middleware semantic_puppet minitar puppet_forge faraday_middleware r10k;
do
    gem uninstall $i
done

# restore puppet dir but save puppet.conf
cp -vf /etc/puppet/puppet.conf /tmp/puppet.conf
rm -rf /etc/puppet
mv /etc/puppet.bak /etc/puppet
cp -vf /tmp/puppet.conf /etc/puppet/puppet.conf
