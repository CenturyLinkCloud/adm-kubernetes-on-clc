# Log Aggregration

A few quick notes about the log aggregation installation.

The ELK tools are not installed by default.  There's a playbook in the _ansible_
directory which will set up an elasticsearch cluster within kubernetes, install
_fluentd_ to feed all of the container logs into elasticsearch, and install a
_kibana_ service to provide the user interface.

```
cd ansible
ansible-playbook -i hosts-${CLC_CLUSTER_NAME} install_log_aggregation.yml
```

### Elasticsearch

Semi-pro setup.  One master, two clients, three data nodes.

Client service is exposed via a NodePort at 30092. http://[ANY_NODE_IP]:30092
should return something like

```
{
    "name": "Misfit",
    "cluster_name": "es_in_k8s",
    "version":
    {
        "number": "2.1.1",
        "build_hash": "40e2c53a6b6c2972b3d13846e450e66f4375bd71",
        "build_timestamp": "2015-12-15T13:05:55Z",
        "build_snapshot": false,
        "lucene_version": "5.3.1"
    },
    "tagline": "You Know, for Search"
}
```

Data nodes store data in an _emptyDir_ volume.  This is probably reasonable for
small amounts of data which are replicated across other nodes.  Otherwise a
persistent volume is highly recommended.

Elasticsearch currently lives within the _kube-system_ namespace.  Other uses
of elasticsearch besides logs are possible, and having the cluster inside the
_kube-system_ namespace may not be appropriate in that case.

For reasonable log searching, we need a template for the _logstash-_ index which
does not analyze fields by default.  Once the elasticsearch cluster is up, there's
a kubernetes job (see _roles/kubernetes-manifest/templates/job-es-template.yml.j2_)
which posts the correct template to the service.  This can be invoked with either
```
kubectl create -f roles/kubernetes-manifest/templates/job-es-template.yml.j2
```
if _kubectl_ is correctly set up on the local machine, or with ansible
```
ansible-playbook -i hosts-${CLC_CLUSTER_NAME}  -e k8s_apps=job-es-template deploy_kube_applications.yml
```

### Fluentd

The _fluentd_ pod is run as a DaemonSet so that it runs once and once only on
each minion node. Container log directories on the node are automatically
mounted into the _fluentd_ container, and the logs parsed and sent to the
elasticsearch instance at
http://elasticsearch-logging:9200

### Kibana

_Kibana_ also communicates with http://elasticsearch-logging:9200.  It is exposed as a
NodePort at port 30056, so the UI can be accessed at http://[ANY_NODE_IP]:30056

Please note, it is _not_ possible to access the kibana UI from the proxy-api.
Although (a) _cluster-info_ will report something like
*kibana-logging is running at https://10.141.117.29:6443/api/v1/proxy/namespaces/kube-system/services/kibana-logging*
and (b) running `kubectl proxy -p 8001` should expose that on localhost without
need for client certificates, it doesn't work.  Why?  Because kibana is a nodejs
app and uses redirects to urls like `/apps/kibana` not handled nicely by
kubernetes proxy-api.
