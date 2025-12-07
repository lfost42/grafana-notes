# CKA Practice Lab 1: IT KIDDIE

This is among the most highly recommended [Youtube playlist](https://www.youtube.com/playlist?list=PLkDZsCgo3Isr4NB5cmyqG7OZwYEx5XOjM) for CKA. 

If you're using the sailor-sh environment, you won't be able to copy/paste these commands unless you navigate to this github within the testing environment. 

-1- (no setup needed)

### Question ArgoCD

Install Argo CD in a Kubernetes cluster using Helm while ensuring that CRDs are not installed (as they are pre-installed). Follow the steps below:

Requirements:
Add the official Argo CD Helm repository with the name argo:
[https://argoproj.github.io/argo-helm](https://argoproj.github.io/argo-helm)

Generate a Helm template from the Argo CD chart version `7.7.3` for the `acgod` namespace.

Ensure that CRDs are not installed by configuring the chart accordingly.

Save the generated YAML manifest to `/home/argo/argo-helm.yaml`.

Video link: [https://www.youtube.com/watch?v=8GzJ-x9ffE0](https://www.youtube.com/watch?v=8GzJ-x9ffE0)

#### Solution
<details>
```# Step one add the repo
helm repo add argocd https://argoproj.github.io/argo-helm
```

```# Check the repo is there
helm repo list
```

```# Step two get the template using the parameters given
mkdir /root/argo
cat /root/argo/argo-helm.yaml
helm template argocd argocd/argo-cd --version 7.7.3 --set crds.install=false --namespace argocd > /root/argo-helm.yaml
```

```#Step three verfiy
cat /root/argo-helm.yaml
```
</details>

-2-
```chmod +x Question-2/LabSetUp.bash
./Question-2/LabSetUp.bash
```

WordPress deployment created in the default namespace. Edit the deployment to add a sidecar container with shared volume.

#### Question SideCar

Task:
Update the existing wordpress deployment adding a sidecar container named sidecar using the busybox:stable
image to the existing pod
The new sidecar container has to run the following command
"/bin/sh -c tail -f /var/log/wordpress.log"
Use a volume mounted at /var/log to make the log file wordpress.log available to the co-located container

Video link: https://youtu.be/2diUcaV5TXw?si=ftqiW_E-4kswuis1

-3-
```chmod +x Question-3/LabSetUp.bash
./Question-3/LabSetUp.bash
```

You have an existing web application deployed in a Kubernetes cluster using an Ingress resource named web.
You must migrate the existing Ingress configuration to the new Kubernetes Gateway API, maintaining the
existing HTTPS access configuration

Task:s
1. Create a Gateway Resource named web-gateway with hostname gateway.web.k8s.local that maintains the
exisiting TLS and listener configuration from the existing Ingress resource named web
2. Create a HTTPRoute resource named web-route with hostname gateway.web.k8s.local that maintains the
existing routing rules from the current Ingress resource named web.
Note: A GatewayClass named nginx-class is already installed in the cluster

Video lnk: https://youtu.be/W-Rt_U8any4?si=KD_6oVewmhPgu1NZ

-4-
chmod +x Question-4/LabSetUp.bash
./Question-4/LabSetUp.bash

### Question
You are managing a WordPress application running in a Kubernetes cluster
Your Task: is to adjust the Pod resource requests and limits to ensure stable operation

Task:s
1. Scale down the wordpress deployment to 0 replicas
2. Edit the deployment and divide the node resource evenly across all 3 pods
3. Assign fair and equal CPU and memory to each Pod
4. Add sufficient overhead to avoid node instability
Ensure both the init containers and the main containers use exactly the same resource requests and limits
After making the changes scale the deployment back to 3 replicas

Video lnk: https://youtu.be/Hkl9XgMKxic?si=v9yI1Rz10DELN4Mf

-5-
chmod +x Question-5/LabSetUp.bash
./Question-5/LabSetUp.bash

### Question Storage Class

Task:s
1. Create a new StorageClass named local-storage with the provisioner rancher.io/local-path. Set
the VolumeBindingMode to WaitForFirstCustomer. Do not make the SC default
2. Patch the StorageClass to make it the default StorageClass
3. Ensure local-storage is the only default class
Do not modify any existing Deployments or PersistentVolumeClaims

Video lnk: https://youtu.be/WmbIrlbqjPw?si=bYSf9dDtb4hIfKG4

-6-
```chmod +x Question-6/LabSetUp.bash
./Question-6/LabSetUp.bash
```

### Question
You're working in a kubernetes cluster with an existing deployment named busybox-logger running
in the priority namespace.
The cluster already has at least one user defined Priority Class

Task:
1. Create a new Priority Class named high-priority for user workloads. The value of this class should
be exactly one less than the highest existing user-defined priority class
2. Patch the existing deployment busybox-logger in the priority namespace to use the newly created
high-priority class

Video lnk: https://youtu.be/wiL_M9qbPX4?si=rOIyX45i5kON8Xr7

-7-
```chmod +x Question-7/LabSetUp.bash
./Question-7/LabSetUp.bash
```

### Question Ingress

Task:
1. Expose the existing deployment with a service called echo-service
using Service Port 8080 type=NodePort
2. Create a new ingress resource named echo in the echo-sound namespace for http://example.org/echo
3. The availability of the Service echo-service can be checked using the following command
curl NODEIP:NODEPORT/echo

In the exam it may give you a command like curl -o /dev/null -s -w "%{http_code}\n" http://example.org/echo
This requires an ingress controller, to get this to work ensure your /etc/hosts file has an entry for your NodeIP
pointing to example.org

Video lnk: https://youtu.be/mtORnV8AlI4?si=6fZq-yd8Sezg0a7v

-8-
```chmod +x Question-8/LabSetUp.bash
./Question-8/LabSetUp.bash
```

### Question CRDs

Task: 
1. Create a list of all cert-manager [CRDs] and save it to /root/resources.yaml
2. Using kubectl extract the documentation for the subject specification field of the Certifciate
Custom Resource and save it to /root/subject.yaml
You may use any output format that kubectl supports

Video lnk: https://youtu.be/mKvkcjoYzOc?si=53ob4__-b242y4K_

-9-
```chmod +x Question-9/LabSetUp.bash
./Question-9/LabSetUp.bash
```

### Question
There are two deployments, Frontend and Backend
Frontend is in the frontend namespace, Backend is in the backend namespace

Task:
Look at the Network Policy YAML files in /root/network-policies
Decide which of the policies provides the functionality to allow interaction between the
frontend and the backend deployments in the least permissive way and deploy that yaml

Video lnk: https://youtu.be/EIjpWA0AGG4?si=ih4IWm4wsDeIPzbM

-10-
```chmod +x Question-10/LabSetUp.bash
./Question-10/LabSetUp.bash
```

### Question HPA
Create a new HorizontalPodAutoScaler(HPA) named apache-server in the autoscale namespace

Task:
1. The HPA must target the existing deployment called apache-deployment in the autoscale namespace
2. Set the HPA to target for 50% CPU usage per Pod
3. Configure the HPA to have a minimum of 1 pod and a maximum of 4 pods
4. Set the downscale stabilization window to 30 seconds

Video lnk: https://youtu.be/X0ISIy9Bd7U?si=h-GydG4EzPTug6Jt

-11-
```chmod +x Question-11/LabSetUp.bash
./Question-11/LabSetUp.bash
```

### Question
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

Video lnk: https://youtu.be/SV3V5VwR2sk?si=47uiyuvMD1Vpqbm1

-12-
```chmod +x Question-12/LabSetUp.bash
./Question-12/LabSetUp.bash
```

### Question
A user accidentally deleted the MariaDB Deployment in the mariadb namespace. The deployment
was configured with persistent storage. Your responsibility is to re-establish the deployment
while ensuring data is preserved by reusing the available PersistentVolume

Task: 
A PersistentVolume already exists and is retained for reuse. Only one PV exists
Create a Persistent Volume Claim (PVC) named mariadb in the mariadb namespace with the spec
Access Mode = ReadWriteOnce
Storage = 250Mi
Edit the MariaDb Deployment file located at ~/mariadb-deploy.yaml to use the PVC created in the previous step
Apply the updated Deployment file to the cluster
Ensure the MariaDB Deployment is running and Stable

Video lnk: https://youtu.be/0h2Dik_OTvw?si=9hU6-xzCW7AUsmEj

-13-
```chmod +x Question-13/LabSetUp.bash
./Question-13/LabSetUp.bash
```

### Question Cri-Dockerd

Task:
Set up cri-dockerd
Install the debian package ~/cri-dockerd.deb using dpkg
Enable and start the cri-docker service
Configure these parameters:
1. Set net.bridge.bridge-nf-call-iptables to 1
2. Set net.ipv6.conf.all.forwarding to 1
3. Set net.ipv4.ip_forward to 1
4. Set net.netfilter.nf_conntrack_max to 131072

Video lnk: https://youtu.be/u3kUI9lFPWE?si=Pkq74-rfFEp6dmfd

-14-
```chmod +x Question-14/LabSetUp.bash
./Question-14/LabSetUp.bash
```

### Question
After a cluster migration, the controlplane kube-apiserver is not coming up
Before the migration, the etcd was external and in HA, after migration the kube-api server was pointing to etcd peer port 2380

Task:
Fix it

Video lnk: https://youtu.be/p1vNc1GacpI?si=lbUxoj5jOeruLy7B

-15-
```chmod +x Question-15/LabSetUp.bash
./Question-15/LabSetUp.bash
```

### Question Taints & Tolerances

Task:
1. Add a taint to node01 so tht no normal pods can be scheduled in this node. key=PERMISSION, value=granted, Type=NoSchedule
2. Schedule a Pod on node01 adding the correct toleration to the spec so it can be deployed

Video lnk: https://youtu.be/-rs3AoAVyXE?si=nACYrGA5h_4WL-og

-16-
```chmod +x Question-16/LabSetUp.bash
./Question-16/LabSetUp.bash
```

### Question
There is a deployment named nodeport-deployment in the relative namespace

Task:
1. Configure the deployment so it can be exposed on port 80, name=http, protocol TCP
2. Create a new Service named nodeport-service exposing the container port 80, protocol TCP, Node Port 30080
3. Configure the new Service to also expose the individual pods using NodePort

Video lnk: https://youtu.be/t1FxX3PmYDQ?si=ryASL-G9X2FCVApQ

-17-
```chmod +x Question-17/LabSetUp.bash
./Question-17/LabSetUp.bash
```

### Question
There is an existing deployment in the nginx-static namespace. The deployment contains a ConfigMap that supports
TLSv1.2 and TLSv1.3 as well as a Secret for TLS.

There is a service called nginx-service in the nginx-static namespace that is currently exposing the deployment.

Task:
1. Configure the ConfigMap to only support TLSv1.3
2. Add the IP address of the service in /etc/hosts and name it ckaquestion.k8s.local
3. Verify everything is working using the following commands
    curl -vk --tls-max 1.2 https://ckaquestion.k8s.local # should fail
    curl -vk --tlsv1.3 https://ckaquestion.k8s.local # should work

Video lnk: https://youtu.be/-6QTAhprvTo?si=Rx81y2lHvK2Y_jBF