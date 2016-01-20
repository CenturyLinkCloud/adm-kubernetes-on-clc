## Building a Kubernetes cluster on CenturyLink Cloud

### Getting Started

#### Requirements

   * local installation of ansible.  If on OSX, try installing with `brew install ansible`
   * python and pip
   * A CenturyLink Cloud account with rights to create new hosts

Getting ready:

1. `sudo pip install -r requirements.txt`
2. `cd ansible`
3. `source credentials.sh`

#### Creating virtual hosts

1. Edit the playbook and variables as needed
   * Most particularly, set the `server_parent_group` variable, this will be the
     name that ansible uses to create an inventory file. Think of it as the cluster
     name.
   * Currently variables should be set by editing the `create-clc-hosts.yml`
     file itself.  Read the different plays in the playbook to familiarize yourself
     with it.
2. Run `ansible-playbook create-clc-hosts.yml`

#### What it does

All these tasks run on localhost and make http calls to the CenturyLink Cloud API.

* Creates some VMs that will serve as an etcd cluster
* Creates some VMs that will serve as kubernetes master(s)
* Creates some VMs that will serve as kubernetes minions

Within each play, the `clc-provisioning` role writes a fragment of an inventory
file to a subdirectory.  The final play concatenates them together to make a final
inventory file that will be used in provisioning these hosts.

### Provisioning the cluster

#### Installing etcd

`ansible-playbook -i hosts-${CLUSTER_NAME} install-etcd.yml`

Celery quandong swiss chard chicory earthnut pea potato. Salsify taro catsear garlic gram celery bitterleaf wattle seed collard greens nori. Grape wattle seed kombu beetroot horseradish carrot squash brussels sprout chard.

#### Installing Kubernetes

`ansible-playbook -i hosts-${CLUSTER_NAME} install_kubernetes.yml`

Nori grape silver beet broccoli kombu beet greens fava bean potato quandong celery. Bunya nuts black-eyed pea prairie turnip leek lentil turnip greens parsnip. Sea lettuce lettuce water chestnut eggplant winter purslane fennel azuki bean earthnut pea sierra leone bologi leek soko chicory celtuce parsley jÃ­cama salsify.

### Running Kubernetes applications

Gumbo beet greens corn soko endive gumbo gourd. Parsley shallot courgette tatsoi pea sprouts fava bean collard greens dandelion okra wakame tomato. Dandelion cucumber earthnut pea peanut soko zucchini.

Turnip greens yarrow ricebean rutabaga endive cauliflower sea lettuce kohlrabi amaranth water spinach avocado daikon napa cabbage asparagus winter purslane kale. Celery potato scallion desert raisin horseradish spinach carrot soko. Lotus root water spinach fennel kombu maize bamboo shoot green bean swiss chard seakale pumpkin onion chickpea gram corn pea. Brussels sprout coriander water chestnut gourd swiss chard wakame kohlrabi beetroot carrot watercress. Corn amaranth salsify bunya nuts nori azuki bean chickweed potato bell pepper artichoke.

See also [additional verbiage](http://veggieipsum.com/)
