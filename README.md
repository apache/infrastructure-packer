Apache Infrastructure Packer
============================

[Packer](https://www.packer.io) is a tool for building virtual machines.  Our
team has used this to provide both vagrant images for local testing and cloud
images for our production virtual machines.

Here's a quick run down of what it works.

## How to build virtual machines and influence people
First you'll need to download [packer](https://www.packer.io/downloads.html).
Once you've got that you'll need a solution for virtualizing to build the VM.
On Debian I installed `qemu-kvm` and needed to add my user to the `kvm` group.
Once that was done it was just a matter of making tweaks: adding packages,
changing the resources to fit your local system, or playing with ponies.
`PACKER_LOG=1 /where/is/packer build ubuntu-16.04.json` will start blazing.
Currenly the VM uses 3gb RAM, 3 vCPU a 10GB disk to build and headless qemu as
pono was the last person to commit.

This particular .json is currently being debugged :)

