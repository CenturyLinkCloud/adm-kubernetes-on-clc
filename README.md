# Building a Kubernetes cluster on CenturyLink Cloud
## Getting Started
### Requirements
- local installation of ansible _version 2.0_ or newer.  If on OSX, try
- installing with `brew install ansible`
- python and pip
- A CenturyLink Cloud account with rights to create new hosts

Getting ready:

Clone this repository and cd into it.
- `sudo pip install -r requirements.txt`
- `cd ansible`
- Create the credentials file from the template, and `source credentials.sh`

### Creating virtual hosts
- Edit the playbook and variables as needed
  - Most particularly, set the `clc_cluster_name` variable, which will be incorporated in the name of the CenturyLink Cloud groups and in the name of the ansible inventory file.  It's not necessary to set this as a local environment variable, although you could for convenience.
  - Currently variables should be set by editing the `create-clc-hosts.yml` file itself.  Read the different plays in the playbook to familiarize yourself with it.

- Run `ansible-playbook create-clc-hosts.yml`

### What it does
All these tasks run on localhost and make http calls to the CenturyLink Cloud API.
- Creates some VMs that will serve as an etcd cluster
- Creates some VMs that will serve as kubernetes master(s)
- Creates some VMs that will serve as kubernetes minions

Within each play, the `clc-provisioning` role writes a fragment of an inventory file to a subdirectory.  The final play concatenates them together to make a final inventory file (named _hosts-${CLC_CLUSTER_NAME}_ that will be used in provisioning these hosts.

## Provisioning the cluster
### Installing etcd
`ansible-playbook -i hosts-${CLC_CLUSTER_NAME} install_etcd.yml`

Celery quandong swiss chard chicory earthnut pea potato. Salsify taro catsear garlic gram celery bitterleaf wattle seed collard greens nori. Grape wattle seed kombu beetroot horseradish carrot squash brussels sprout chard.

### Installing Kubernetes
`ansible-playbook -i hosts-${CLC_CLUSTER_NAME} install_kubernetes.yml`

Nori grape silver beet broccoli kombu beet greens fava bean potato quandong celery. Bunya nuts black-eyed pea prairie turnip leek lentil turnip greens parsnip. Sea lettuce lettuce water chestnut eggplant winter purslane fennel azuki bean earthnut pea sierra leone bologi leek soko chicory  parsley jicama salsify.

## Running Kubernetes applications
There are templates in the role _kubernetes-application_ already written for several applications.  These can be applied with the _install_kubernetes.yml_ playbook

`my_app=guestbook-all-in-one` # for example

`ansible-playbook -i hosts-${CLC_CLUSTER_NAME} -e kubernetes_applications=${my_app} kubernetes-apps.yml`

Gumbo beet greens corn soko endive gumbo gourd. Parsley shallot courgette tatsoi pea sprouts fava bean collard greens dandelion okra wakame tomato. Dandelion cucumber earthnut pea peanut soko zucchini.

Turnip greens yarrow ricebean rutabaga endive cauliflower sea lettuce kohlrabi amaranth water spinach avocado daikon napa cabbage asparagus winter purslane kale. Celery potato scallion desert raisin horseradish spinach carrot soko. Lotus root water spinach fennel kombu maize bamboo shoot green bean swiss chard seakale pumpkin onion chickpea gram corn pea. Brussels sprout coriander water chestnut gourd swiss chard wakame kohlrabi beetroot carrot watercress. Corn amaranth salsify bunya nuts nori azuki bean chickweed potato bell pepper artichoke.

See also [additional verbiage](http://veggieipsum.com/)

