# Role Name
A role to create a group of servers in a CenturyLink Cloud datacenter.  Creates a set of servers in a specified group.  Copies ssh-keys and writes an ansible hosts file for those servers so that they can be accessed directly for additional provisioning.  Runs only on localhost, making web service calls to the CenturyLink Cloud API.

## Requirements
The role uses the [clc-ansible-module](https://github.com/CenturyLinkCloud/clc-ansible-module)

## Role Variables
Please define these variables:
- _server_group_: a group name for these servers
- _datacenter_: desired datacenter location, VA1, WA1, etc
- _server_tag_: 4-character tag used by CLC in generating the hostname

Optionally:
- _server_parent_group_: defaults to "Default Group"   

Other variables are found in _defaults/mail.yml_ and _vars/main.yml_

## Example Playbook

```
---
- name: Get machine resources for web servers
  hosts: localhost
  gather_facts: False
  connection: local

  vars:
    - server_parent_group: provisioning_test
    - ansible_hosts_directory: "{{ server_parent_group }}.d"
    - server_group: test_servers
    - datacenter: VA1
    - server_tag: web
    - server_count: 3
    - server_memory: 2
    - server_cpu: 1

  roles:
    - clc-provisioning
```

## Author Information
The Admiral group, CenturyLink Cloud
