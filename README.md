# Windows Image Builder

Deploy this role to a Microsoft Windows Server to build custom Windows WIM images. The images can be used with Foreman, MDT, SCCM, and good old fashioned commandline favorite - DISM. The ClusterApps systems leverage Katello. The roles and instructions will be written based on Foreman as the provisioning enginge. Future updates may include output files for other provisioners and installation media.

A web server is required before running this role. Some software used in the role has a license that prohibits redistribution. You will need to upload your licensed media to the web server for the role to use while running. After the inital Builder deployment and configuration, the web server downloads will no longer be needed and could be removed. It is recommended to use a private web server and keep the file for future use.

## Usage

* Prepare the Windows target for Ansible management.
* Download the role. (git or Galaxy)
* Create a playbook and inventory (See examples in Private Data System)
* Run playbook

## Settings

There are a set of variables that must be defined for the environment. 

win_build_base: Z:\source # location of builder source files
win_build_deploy: Z:\Deploy # location of finished output
win_build_wsusRoot: Z:\wsusoffline # location of WSUS Offline Updater root
win_build_katello: katello.example.com # FQDN of Katello server or proxy. 
win_build_share_iis: true # Set to false to not deploy local web server
win_build_share_cifs: true # Set to false to skip share creation. NOTE: The share is required for MDT and SCCM like deployments.
win_build_shareuser: windeploy # Local Windows user the share will be mounted read-only as
win_build_sharepass: ThisI5abAdPaSSwd # Local Windows user's password
win_build_ws2016_iso: https://download.example.com/iso/server16.iso # Location of Windows Server installation ISO. NOTE: Only test with 2016. Server 2019 will build images, but not be updated.
win_build_wimbooturl: https://git.ipxe.org/release/wimboot/wimboot-1.0.5.zip

## Example Playbook

- name: Configure ClusterApps Windows Build Server 
  hosts: winbuilder
  vars:
    win_build_ws2016_iso: https://download.internalweb.com/iso/server16.iso
    win_build_sharepass: NotBett3rButDiffer3nt
  roles:
    - win_builder


    