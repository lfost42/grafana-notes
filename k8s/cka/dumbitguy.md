# CKA Practice Lab 2: DumbItGuy

This is another highly recommended [Youtube playlist](https://www.youtube.com/playlist?list=PLkDZsCgo3Isr4NB5cmyqG7OZwYEx5XOjM) for CKA. 

### Lab Setup

```bash
git clone https://github.com/vj2201/CKA-PREP-2025-v2.git
chmod +x CKA-PREP-2025-v2/scripts/run-question.sh`
cd CKA-PREP-2025-v2
chmod +x scripts/run-question.sh
```

## Question-1 MariaDB-Persistent volume

```bash
./scripts run-question.sh Question-1\ *
```

A user accidentally deleted the MariaDB Deployment in the mariadb namespace. The deployment was configured with persistent storage. Your responsibility is to re-establish the deployment while ensuring data is preserved by reusing the available PersistentVolume

#### Task
A PersistentVolume already exists and is retained for reuse. Only one PV exists
Create a Persistent Volume Claim (PVC) named mariadb in the mariadb namespace with the specs: 

Access Mode = ReadWriteOnce
Storage = 250Mi

Edit the MariaDb Deployment file located at ~/mariadb-deploy.yaml to use the PVC created in the previous step

Apply the updated Deployment file to the cluster
Ensure the MariaDB Deployment is running and Stable

Video Link - https://youtu.be/aXvvc1EB1zg

#### Solution-1

<details>

Step 1: create PVC with no storageClass (PV is pre-reset by LabSetUp.bash)

Review pv to determine storage class.
`k -n mariadb describe pv mariadb-pv`

```bash
cat <<'EOF' > pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mariadb
  namespace: mariadb
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 250Mi
  storageClassName: standard
EOF
```

`k apply -f pvc.yaml`
`k -n mariadb get pvc mariadb`
`k get pv mariadb-pv`     # should show Bound to mariadb

Step 2: ensure deployment uses the PVC
mariadb-deploy.yaml should mount claimName: mariadb
(LabSetUp.bash leaves claimName blank for practice)
`vim mariadb-deploy.yaml`

Add claimName and apply
`k apply -f mariadb-deploy.yaml`
`k -n mariadb get pods`

</details>

## Question-2 ArgoCD

```bash
./scripts run-question.sh Question-2\ *
```

Install Argo CD in a kubernetes cluster using helm while ensuring the CRDs are not installed (as they are pre installed)  
1. Add the official Argo CD Helm repository with the name argocd (https://argoproj.github.io/argo-helm)
2. Generate a Helm template from the Argo CD chart version 7.7.3 for the argocd namespace
3. Ensure that CRDs are not installed by configuring the chart accordingly
4. Save the generated YAML manifest to /root/argo-helm.yaml

Video link - https://youtu.be/e0YGRSjb8CU

#### Solution-2

<details>

`helm repo add argocd https://argoproj.github.io/argo-helm`  
`helm repo update`  
`helm template argocd argo/argo-cd --version 7.7.3 --set crds.install=false -n argocd > /root/argo-helm.yaml`  
`cat /root/argo-helm.yaml   # confirm output ` 

</details>

## Question-3 Sidecar

```bash
./scripts run-question.sh Question-3\ *
```

Update the existing wordpress deployment adding a sidecar container named sidecar using the `busybox:stable` image to the existing pod. The new sidecar container has to run the following command `/bin/sh -c tail -f /var/log/wordpress.log`. Use a volume mounted at /var/log to make the log file wordpress.log available to the co-located container.

Video link - https://youtu.be/3xraEGGQJDY


#### Solution-3

<details>

Add shared volume + sidecar to deployment  
`kubectl edit deployment wordpress   # add emptyDir volume and mounts below`
```yaml
spec.template.spec.volumes:
- name: log
  emptyDir: {}
main container volumeMounts:
- mountPath: /var/log
  name: log
add sidecar:
- name: sidecar
  image: busybox:stable
  command: ["/bin/sh","-c","tail -f /var/log/wordpress.log"]
  volumeMounts:
  - mountPath: /var/log
    name: log
```
`kubectl rollout status deployment wordpress`  
`kubectl get pods -l app=wordpress`

</details>

## Question-4 Resource-Allocation

```bash
./scripts run-question.sh Question-4\ *
```

You are managing a WordPress application running in a Kubernetes cluster. Your task is to adjust the Pod resource requests and limits to ensure stable operation

1. Scale down the wordpress deployment to 0 replicas
2. Edit the deployment and divide the node resource evenly across all 3 pods
3. Assign fair and equal CPU and memory to each Pod
4. Add sufficient overhead to avoid node instability

Ensure both the init containers and the main containers use exactly the same resource requests and limits. After making the changes scale the deployment back to 3 replicas

Video link - https://youtu.be/ZqGDdETii8c


#### Solution-4

<details>

Step 1: pause workload  
`kubectl scale deployment wordpress --replicas 0`

Step 2: set requests/limits (e.g., 250m/300m CPU, 500Mi/600Mi mem). 
```
kubectl patch deployment wordpress -p '{
  "spec":{"template":{"spec":{
    "containers":[{
      "name":"wordpress",
      "resources":{
        "requests":{"cpu":"250m","memory":"500Mi"},
        "limits":{"cpu":"300m","memory":"600Mi"}
      }
    }]
  }}}}'
```
Step 3: resume replicas  
`kubectl scale deployment wordpress --replicas 3`
`kubectl get pods -l app=wordpress`

</details>

## Question-5 HPA

```bash
./scripts run-question.sh Question-5\ *
```

Create a new HorizontalPodAutoScaler(HPA) named apache-server in the autoscale namespace

1. The HPA must target the existing deployment called apache-deployment in the autoscale namespace
2. Set the HPA to target for 50% CPU usage per Pod
3. Configure the HPA to have a minimum of 1 pod and a maximum of 4 pods
4. Set the downscale stabilization window to 30 seconds

Video Link - https://youtu.be/YGkARVFKtmM


#### Solution-5

<details>

Create HPA for apache-deployment in autoscale namespace  
`kubectl get deploy -n autoscale`  
```bash
cat <<'EOF' > hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: apache-server
  namespace: autoscale
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: apache-deployment
  minReplicas: 1
  maxReplicas: 4
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 30
EOF
```
`kubectl apply -f hpa.yaml`. 
`kubectl get hpa -n autoscale`

</details>

## Question-6 CRDs

```bash
./scripts run-question.sh Question-6\ *
```

1. Create a list of all cert-manager [CRDs] and save it to /root/resources.yaml
2. Using kubectl extract the documentation for the subject specification field of the Certifciate Custom Resource and save it to `/root/subject.yaml`. You may use any output format that kubectl supports

Video Link - https://youtu.be/SA1DzLQaDJs


#### Solution-6

<details>

`kubectl get crd | grep cert-manager | tee /root/resources.yaml`
Save spec subject explain output  
`kubectl explain certificate.spec.subject | tee /root/subject.yaml`

</details>

## Question-7 PriorityClass

```bash
./scripts run-question.sh Question-7\ *
```

You're working in a kubernetes cluster with an existing deployment named busybox-logger running in the priority namespace. The cluster already has at least one user defined Priority Class. 

1. Create a new Priority Class named high-priority for user workloads. The value of this class should be exactly one less than the highest existing user-defined priority class. 
2. Patch the existing deployment busybox-logger in the priority namespace to use the newly created high-priority class.

Video Link - https://youtu.be/CZzxGyF6OHc


#### Solution-7

<details>

Create PriorityClass just below existing max (e.g., 999)
`kubectl create priorityclass high-priority --value=999 --description="high priority"`  
`kubectl get pc`

Patch deployment to use it. 
`kubectl patch deployment busybox-logger -n priority -p '{"spec":{"template":{"spec":{"priorityClassName":"high-priority"}}}}'`  
`kubectl describe deployment busybox-logger -n priority | grep -i "Priority Class"`

</details>

## Question-8 CNI & Network Policy

```bash
./scripts run-question.sh Question-8\ *
```

Install and configure a CNI of your choice tht meets the specified requirements,
Choose one of the following:

Flannel (v0.26.1) using the manifest kube-flannel.yml
(https://github.com/flannel-io/flannel/releases/download/v0.26.1/kube-flannel.yml)

or

Calico (v3.28.2) using the manifest tigera-operator.yaml
(https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/tigera-operator.yaml)

The CNI you choose must
1. Let pods communicate with each other
2. Support network policy enforcement
3. Install from manifest

Video Link - https://youtu.be/Uc04Ui4x3EM


#### Solution-8

<details>

Install Calico (supports NetworkPolicy). 
`kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/tigera-operator.yaml`  
`kubectl get all -n tigera-operator`

</details>

## Question-9 Cri-Dockerd

```bash
./scripts run-question.sh Question-9\ *
```

Set up cri-dockerd.  
Install the debian package ~/cri-dockerd.deb using dpkg.  
Enable and start the cri-docker service.  
Configure these parameters:

Set net.bridge.bridge-nf-call-iptables to 1  
Set net.ipv6.conf.all.forwarding to 1  
Set net.ipv4.ip_forward to 1  
Set net.netfilter.nf_conntrack_max to 131072

Video Link - https://youtu.be/ybzo1vXiqjU


#### Solution-9

<details>

Install and run cri-dockerd  
`sudo dpkg -i cri-dockerd.deb`
`sudo systemctl enable --now cri-docker.service`  
`sudo systemctl status cri-docker.service`. 

Set sysctl (make persistent)
```bash
sudo tee /etc/sysctl.d/kube.conf >/dev/null <<'EOF'
net.bridge.bridge-nf-call-iptables=1
net.ipv6.conf.all.forwarding=1
net.ipv4.ip_forward=1
net.netfilter.nf_conntrack_max=131072
EOF
sudo sysctl --system
```

</details>

## Question-10 Taints-Tolerations

```bash
./scripts run-question.sh Question-10\ *
```

1. Add a taint to node01 so tht no normal pods can be scheduled in this node. key=PERMISSION, value=granted, Type=NoSchedule
2. Schedule a Pod on node01 adding the correct toleration to the spec so it can be deployed

Video Link - https://youtu.be/oy6Mdqt1-jk

#### Solution-10

<details>

Taint node01  
`kubectl taint nodes node01 PERMISSION=granted:NoSchedule`

Pod that tolerates the taint. 
```bash
cat <<'EOF' > pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - name: nginx
    image: nginx
  tolerations:
  - key: PERMISSION
    operator: Equal
    value: granted
    effect: NoSchedule
EOF
```
`kubectl apply -f pod.yaml`. 
`kubectl get pods`

Negative test (optional) — should stay Pending  
```bash
cat <<'EOF' > podfailure.yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-fail
spec:
  containers:
  - name: nginx
    image: nginx
EOF
```
`kubectl apply -f podfailure.yaml`  
`kubectl describe pod nginx-fail`

</details>

## Question-11 Gateway-API

```bash
./scripts run-question.sh Question-11\ *
```

You have an existing web application deployed in a Kubernetes cluster using an Ingress resource named web. You must migrate the existing Ingress configuration to the new Kubernetes Gateway API, maintaining the existing HTTPS access configuration. 

1. Create a Gateway Resource named web-gateway with hostname gateway.web.k8s.local that maintains the
exisiting TLS and listener configuration from the existing Ingress resource named web
2. Create a HTTPRoute resource named web-route with hostname gateway.web.k8s.local that maintains the
existing routing rules from the current Ingress resource named web.
Note: A GatewayClass named nginx-class is already installed in the cluster

Video link - https://youtu.be/G9zispvOCHE

#### Solution-11

<details>



</details>

## Question-12 Ingress

```bash
./scripts run-question.sh Question-12\ *
```

1. Expose the existing deployment with a service called echo-service
using Service Port 8080 type=NodePort
2. Create a new ingress resource named echo in the echo-sound namespace for http://example.org/echo
3. The availability of the Service echo-service can be checked using the following command curl NODEIP:NODEPORT/echo

In the exam it may give you a command like `curl -o /dev/null -s -w "%{http_code}\n" http://example.org/echo`. This requires an ingress controller, to get this to work ensure your `/etc/hosts` file has an entry for your NodeIP pointing to example.org

Video Link - https://youtu.be/sy9zABvDedQ

#### Solution-12

<details>

Expose deployment as NodePort. 
`kubectl expose deployment echo -n echo-sound --name echo-service --type NodePort --port 8080 --target-port 8080`  
`kubectl get svc -n echo-sound echo-service`. 

Create ingress. 
```bash
cat <<'EOF' > ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: echo
  namespace: echo-sound
spec:
  rules:
  - host: example.org
    http:
      paths:
      - path: /echo
        pathType: Prefix
        backend:
          service:
            name: echo-service
            port:
              number: 8080
EOF
```
`kubectl apply -f ingress.yaml`  
`kubectl get ingress -n echo-sound`

Optional test (NodePort):  
`curl http://<nodeIP>:<nodePort>/echo`

</details>

## Question-13 Network-Policy

```bash
./scripts run-question.sh Question-13\ *
```

There are two deployments, Frontend and Backend. Frontend is in the frontend namespace, Backend is in the backend namespace. 

Look at the Network Policy YAML files in /root/network-policies. Decide which of the policies provides the functionality to allow interaction between the frontend and the backend deployments in the least permissive way and deploy that yaml.

Video Link - https://youtu.be/rA8mXYTU0W8


#### Solution-13

<details>

Compare provided policies and pick the least permissive that matches requirements  
`cat /root/network-policies/network-policy-1.yaml   # allows all ingress (too open)`  
`cat /root/network-policies/network-policy-2.yaml   # extra IP allowed (too open)`. 
`cat /root/network-policies/network-policy-3.yaml   # only frontend namespace/pods allowed`  
`kubectl get pods -n frontend --show-labels         # confirm app=frontend label`  
`kubectl apply -f /root/network-policies/network-policy-3.yaml`. 

</details>

## Question-14 Storage-Class

```bash
./scripts run-question.sh Question-14\ *
```

1. Create a new StorageClass named local-storage with the provisioner rancher.io/local-path. Set
the VolumeBindingMode to WaitForFirstCustomer. Do not make the SC default
2. Patch the StorageClass to make it the default StorageClass
3. Ensure local-storage is the only default class

Do not modify any existing Deployments or PersistentVolumeClaims

Video link - https://youtu.be/di7X7OHn2fc


#### Solution-14

<details>

Create StorageClass  
```bash
cat <<'EOF' > sc.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-storage
  annotations:
    storageclass.kubernetes.io/is-default-class: "false"
provisioner: rancher.io/local-path
volumeBindingMode: WaitForFirstConsumer
EOF
```
`kubectl apply -f sc.yaml`  
`kubectl get sc`  

Make it default, remove default from local-path  
`kubectl patch storageclass local-storage -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
kubectl patch storageclass local-path -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'`  
`kubectl get sc`  

</details>

## Question-15 Etcd-Fix

```bash
./scripts run-question.sh Question-15\ *
```

After a cluster migration, the controlplane kube-apiserver is not coming up
Before the migration, the etcd was external and in HA, after migration the kube-api server was pointing to etcd peer port 2380. Fix it. 

Video Link - https://youtu.be/IL448T6r8H4


#### Solution-15

<details>

Check apiserver logs, fix etcd endpoint  
`journalctl -u kube-apiserver | tail`  
`sudo sed -n '1,200p' /etc/kubernetes/manifests/kube-apiserver.yaml`  
Ensure flag uses correct etcd port  
`--etcd-servers=https://127.0.0.1:2379`  
`sudo vi /etc/kubernetes/manifests/kube-apiserver.yaml   # correct port/IP, save and wait for` `static pod restart`  

If scheduler also broken, verify its flags  
`kubectl -n kube-system get pods | grep kube-scheduler`  
`sudo vi /etc/kubernetes/manifests/kube-scheduler.yaml   # kubeconfig path, API server endpoint, cert refs`

</details>

## Question-16 NodePort

```bash
./scripts run-question.sh Question-16\ *
```

There is a deployment named nodeport-deployment in the relative namespace

1. Configure the deployment so it can be exposed on port 80, name=http, protocol TCP
2. Create a new Service named nodeport-service exposing the container port 80, protocol TCP, Node Port 30080
3. Configure the new Service to also expose the individual pods using NodePort

Video Link - https://www.youtube.com/watch?v=UT-RZCZlUiw

#### Solution-16

<details>

Add container port to deployment  

```bash
kubectl patch deployment nodeport-deployment -n relative -p '{
  "spec":{"template":{"spec":{"containers":[{
    "name":"nginx",
    "ports":[{"name":"http","containerPort":80,"protocol":"TCP"}]
  }]}}}}'
```

`kubectl get deploy nodeport-deployment -n relative -o wide`

Create NodePort service on 30080
```bash
cat <<'EOF' > svc.yaml
apiVersion: v1
kind: Service
metadata:
  name: nodeport-service
  namespace: relative
spec:
  type: NodePort
  selector:
    app: nodeport-deployment
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
    nodePort: 30080
EOF
```

`kubectl apply -f svc.yaml`  
`kubectl get svc nodeport-service -n relative -o wide`  
Test: `curl http://<nodeIP>:30080`  

</details>

## Question-17 TLS-Config

```bash
./scripts run-question.sh Question-17\ *
```

There is an existing deployment in the nginx-static namespace. The deployment contains a ConfigMap that supports TLSv1.2 and TLSv1.3 as well as a Secret for TLS.

There is a service called `nginx-service` in the `nginx-static` namespace that is currently exposing the deployment.

Task:
1. Configure the ConfigMap to only support `TLSv1.3`
2. Add the IP address of the service in `/etc/hosts` and name it `ckaquestion.k8s.local`
3. Verify everything is working using the following commands

curl -vk --tls-max 1.2 https://ckaquestion.k8s.local # should fail
curl -vk --tlsv1.3 https://ckaquestion.k8s.local # should work

Video Link - https://www.youtube.com/watch?v=WFTVTi8JhKc


#### Solution-17


<details>

Step one: We want to edit the config map to remove all references to tls v1.2  
`k edit cm -n nginx-static nginx-config`  
remove TLSv1.2 from SSL protocols (remove from last applied configuration for safety)

Step 2: We need to get the IP of the service  
`k get svc -n nginx-static`

We need to add this IP with the host name to /etc/hosts  
`sudo echo 'x.x.x.x ckaquestion.k8s.local' >> /etc/hosts`

Check the hosts file has been updated the IP and host should be added to the bottom of the file
`sudo cat /etc/hosts`

Step 3: If we run the check commands now we see v1.2 is still working, this is because we need to restart the deployment to use the new CM config
`k rollout restart -n nginx-static deployment nginx-static`

Test the commands again and the v1.2 should no longer work  
`curl -vk --tls-max 1.2 https://ckaquestion.k8s.local # should fail`  
`curl -vk --tlsv1.3 https://ckaquestion.k8s.local # should work`  

</details>

---

[back to main](../../README.md)