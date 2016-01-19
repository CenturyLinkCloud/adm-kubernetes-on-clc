Role Name
=========

A role to create a group of servers in a CenturyLink Cloud datacenter.

Requirements
------------

Any pre-requisites that may not be covered by Ansible itself or the role should be mentioned here. For instance, if the role uses the EC2 module, it may be a good idea to mention in this section that the boto package is required.

Role Variables
--------------

Please define these variables:
   * server_group: a group name for these servers
   * datacenter: desired datacenter location, VA1, WA1, etc
   * server_tag: 4-character tag used by CLC in generating the hostname

Optionally:
   * server_parent_group: defaults to "Default Group"   


Dependencies
------------

A list of other roles hosted on Galaxy should go here, plus any details in regards to parameters that may need to be set for other roles, or variables that are used from other roles.

Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

    - hosts: servers
      roles:
         - { role: username.rolename, x: 42 }

License
-------

BSD

Author Information
------------------

An optional section for the role authors to include contact information, or a website (HTML is not allowed).
