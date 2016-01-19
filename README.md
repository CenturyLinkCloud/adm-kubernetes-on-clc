## Building a Kubernetes cluster on CenturyLink Cloud

### Getting Started

#### Requirements

   * local installation of ansible.  Try installing with `brew install ansible`
   * python and pip
   * A CenturyLink Cloud account with rights to create new hosts

1. `sudo pip install -r requirements.txt`
2. `cd ansible`
3. `source credentials.sh`
4. Edit the playbook and variables as needed, `ansible-playbook create-clc-hosts.yml`
