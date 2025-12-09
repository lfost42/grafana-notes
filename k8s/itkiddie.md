# CKA Practice Lab 1: IT KIDDIE

This is among the most highly recommended [Youtube playlist](https://www.youtube.com/playlist?list=PLkDZsCgo3Isr4NB5cmyqG7OZwYEx5XOjM) for CKA. 

Setup for sailor-sh
</details>

CK-X started a [hosted version](https://sailor.sh/) but I haven't touched it. These are instructions to run this on your local machine. 

GitHub: https://github.com/sailor-sh/CK-X

### Setup for CK-X

If on Windows, enable `WSL2` in `docker destop` and run:

```bash
irm https://raw.githubusercontent.com/nishanb/ck-x/master/scripts/install.ps1 | iex`
```

Linux & macOS:

```bash
curl -fsSL https://raw.githubusercontent.com/nishanb/ck-x/master/scripts/install.sh | bash
```

`http://localhost:30080` should load automatically. 

Click `Start Exam` and `Start Exam`. It will default to the CKAD practice exam which is fine, we're not using it anyway. 

Wait until environment loads (will take a few minutes).

Click `Start` until the exam starts. 

On the left side panel, click `ssh ckad9999` to copy and [ctrl+shift+v to] paste in a terminal. 

Run `apt-get update`

Now we need to do something about that timer ...

Navigate to `Exam Controls` and click `End Exam` and `End Exam` (we're not using this!). 

In the Evaluation page, click `Current Exam` and `Connect to Session`. 

You are now free to use this environment uninterrupted!

I am tinkering with the idea of loding these labs into CK-X. I just need a little more free time than I do right now!

</details>

In your lab terminal, run the following to download lab files:

```bash
git clone https://github.com/CameronMetcalfe22/CKA-PREP.git
cd CKA-PREP
```

## -1- ArgoCD (no setup needed)

### Question

Install `Argo CD` in a Kubernetes cluster using Helm while ensuring that CRDs are not installed (as they are pre-installed). 

Task:
1. Add the official Argo CD Helm repository with the name argo: https://argoproj.github.io/argo-helm
2. Generate a Helm template from the Argo CD chart version `7.7.3` for the `acgocd` namespace.
3. Ensure that CRDs are not installed by configuring the chart accordingly.
4. Save the generated YAML manifest to `/home/argo/argo-helm.yaml`.

Video link: https://www.youtube.com/watch?v=8GzJ-x9ffE0

#### Solution
<details>

Step one: add the repo

```bash
helm repo add argocd https://argoproj.github.io/argo-helm
```

Check the repo is there  
`helm repo list`

```bash
# Step two get the template using the parameters given
mkdir /root/argo
cat /root/argo/argo-helm.yaml
k create ns argocd
```

`helm -n argocd template argocd argocd/argo-cd --version 7.7.3 --set crds.install=false > /root/argo-helm.yaml`

Step three: verify  
`cat /root/argo-helm.yaml`

</details>

## -2- Sidecar

```bash
chmod +x Question-2/LabSetUp.bash
./Question-2/LabSetUp.bash
```

WordPress deployment created in the `default` namespace. Edit the deployment to add a sidecar container with shared volume.

### Question

Task:
1. Update the existing wordpress deployment adding a sidecar container named `sidecar` using the `busybox:stable` image to the existing pod. 
2. The new sidecar container has to run the following command `"/bin/sh -c tail -f /var/log/wordpress.log"`
3. Use a volume mounted at `/var/log` to make the log file `wordpress.log` available to the co-located container. 

Video link: https://youtu.be/2diUcaV5TXw?si=ftqiW_E-4kswuis1

#### Solution

<details>

Step 1: Verify secret and ingress exist and describe them

```
k get secret -n web-app
k describe secret -n web-app web-tls
```

```
k get ingress -n web-app
k describe ingress -n web-app web
```

Step 2: Create the Gateway (use the docs)
`vim gw.yaml`

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: web-gateway
  namespace: web-app
spec:
  gatewayClassName: nginx-class
  listeners:
  - name: https
    protocol: HTTPS
    port: 443
    hostname: gateway.web.k8s.local
    tls:                              # This is the section we need to add to maintain the existing config
      mode: Terminate                 # for the ingress resource
      certificateRefs:
       - kind: Secret
         name: web-tls
```

Apply it
`k apply -f gw.yaml`

Verify it is there
`k get gateway -n web-app`

Step 3: create the HTTPRoute
`vim http.yaml`

Use the docs for reference

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: web-route
spec:
  parentRefs:
  - name: web-gateway
  hostnames:
  - "gateway.web.k8s.local"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /                  # We see the path from the ingress description
    backendRefs:
    - name: web-service           # Name and port need to match the service we have
      port: 80.
```

apply it. 
`k apply -f http.yaml`

```bash
# Check
k describe gateway, httproute -n web-app
```

Check all fields match as expected. In the exam you may be given a curl to run to check this


</details>

## -3- Gateway API

```bash
chmod +x Question-3/LabSetUp.bash
./Question-3/LabSetUp.bash
```
### Question 

You have an existing web application deployed in a Kubernetes cluster using an Ingress resource named `web`. Migrate the existing Ingress configuration to the new Kubernetes Gateway API, maintaining the existing HTTPS access configuration. 

Task:
1. In the `web-app` namespace, create a Gateway Resource named `web-gateway` with hostname `gateway.web.k8s.local ` that maintains the exisiting TLS and listener configuration from the existing Ingress resource named `web`. 
2. Create a HTTPRoute resource named `web-route` with hostname `gateway.web.k8s.local` that maintains the existing routing rules from the current Ingress resource named web.

Note: A GatewayClass named `nginx-class` is already installed in the cluster. 

Video lnk: https://youtu.be/W-Rt_U8any4?si=KD_6oVewmhPgu1NZ

Solution:
<details>

Step 1: Verify secret and ingress exist and describe them. 

```bash
k get secret -n web-app
k describe secret -n web-app
k get ingress -n web-app
k describe ingress -n web-app
k get svc -n web-app
k describe svc -n web-app
```

Step 2: Create the Gateway (use the docs)
`vim gw.yaml`

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: web-gateway
  namespace: web-app
spec:
  gatewayClassName: nginx-class # in question details
  listeners:
  - name: https # tls is only possible in https
    protocol: HTTPS
    port: 443 
    hostname: gateway.web.k8s.local # from question details
    tls:                            # This is the section we need to add to maintain the existing config
      mode: Terminate                # for the ingress resource
      certificateRefs:
       - kind: Secret
         name: web-tls
```

Apply it. 
`k apply -f gw.yaml`

Verify it's there.
`k get gateway -n web-app`

Step 3: create the HTTPRoute

`vim http.yaml`

Use the docs for reference

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: web-route
  namespace: web-app
spec:
  parentRefs:
  - name: web-gateway
  hostnames:
  - "gateway.web.k8s.local"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /                  # We see the path from the ingress description
    backendRefs:
    - name: web-service           # Name and port need to match the service we have
      port: 80
```

apply it. 
`k apply -f http.yaml`

Check
`k describe gateway,httproute -n web-app`

Check all fields match as expected. In the exam you may be given a curl to run to check this. 

</details>

## -4- CPU and Memory

```bash
chmod +x Question-4/LabSetUp.bash
./Question-4/LabSetUp.bash
```

### Question

You are managing a WordPress application running in a Kubernetes cluster. Adjust the Pod resource requests and limits to ensure stable operation. 

Task:
1. Scale down the wordpress deployment to 0 replicas
2. Edit the deployment and divide the node resource evenly across all 3 pods
3. Assign fair and equal CPU and memory to each Pod
4. Add sufficient overhead to avoid node instability
5. Ensure both the init containers and the main containers use exactly the same resource requests and limits. 
6. After making the changes scale the deployment back to 3 replicas. 

Video lnk: https://youtu.be/Hkl9XgMKxic?si=v9yI1Rz10DELN4Mf

Solution:
<details>

The CK-X environment is huge so any number would work. I recommend trying this one at [killercoda]()

Step 1: Check the deployment and scale it down to 0  
`k get deploy`

Scale it down
`k scale deployment wordpress --replicas 0`

Check it has scaled  
`k get deploy`

Should see 0 replicas

Step 2: Find the allocatable CPU and memory on the node and decide how to split it between the 3 pods  
`k describe node node01`

Look at the memory and CPU that is allocatable (I will be using example numbers here, yours will be different)

> cpu: 1  
> memory: 1846652Ki


Firstly we want memory in Mi so divide the Ki by 1024

`expr 1846652 / 1024`
> 1803

Next we want to look at memory already in use. 

`k describe node node01`

Look in the Memory Requests Column

> kube-system  canal-tqknq               25m (2%)  0 (0%)      0 (0%)   0 (0%)      2d23h  
> kube-system  coredns-6ff97d97f9-h59nk  50m (5%)  0 (0%)   50Mi (2%)   170Mi (9%)  2d23h  
> kube-system  coredns-6ff97d97f9-rpmqd  50m (5%)  0 (0%)    50Mi (2%)  170Mi (9%)  2d23h  

We have 100Mi already requested so we need to take this out of our calculation
`expr 1803 - 100`
> 1703

We now need to leave ~ 10% Head room
`expr 1703 - 170`
> 1533

We now need to share this between 3 pods
`expr 1533 / 3`
> 511Mi

Looking at this a 500Mi request looks reasonable with a 600Mi limit. We now need to do the same for CPU:  
> 1 CPU = 1000m

Check CPU usage from the table we see it is 125m. 
`expr 1000 - 125`
> 875

Get ~10% headroom. 
`875 - 87`
> 788

Share this between 3 pods. 
`expr 788 / 3` 
> ~262

Looking at this a 250m request with a 300m limit looks reasonable

Step 3: Edit the deployment with the new requests and limits

`k edit deploy wordpress`

```yaml
# ensure you add the limits to containers AND init containers
        resources:
          limits:
            cpu: 300m
            memory: 600Mi
          requests:
            cpu: 250m
            memory: 500Mi
```

Step 4: Scale the deployment back to 3 replicas  
`k scale deploy wordpress --replicas 3`

Describe the deployment and ensure you see the requests/limits there  
`k describe deploy wordpress`

Once the pods are up and running describe one of the pods and make sure you see the requests/limits there  
`k describe po wordpress-xxx-xxx-xxx`

</details>

## -5- Storage Class

```bash
chmod +x Question-5/LabSetUp.bash
./Question-5/LabSetUp.bash
```

### Question

Task:
1. Create a new StorageClass named `local-storage` with the provisioner `rancher.io/local-path`. Set the VolumeBindingMode to `WaitForFirstCustomer`. Do not make the SC default.
2. Patch the StorageClass to make it the default StorageClass.
3. Ensure `local-storage` is the only default class.

Do not modify any existing Deployments or PersistentVolumeClaims.

Video link: https://youtu.be/WmbIrlbqjPw?si=bYSf9dDtb4hIfKG4

Solution

<details>

Step 1 Create the storage class
`vim sc.yaml`

Use the docs to create the yaml as per your spec

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-storage
  annotations:
    storageclass.kubernetes.io/is-default-class: "false"
provisioner: rancher.io/local-path
volumeBindingMode: WaitForFirstConsumer
```

apply
`k apply -f sc.yaml`

Check
`k get sc`

You should see your SC there and it isn't the default class

Step 2 patch your SC: Check where we need to patch by using
`k get sc local-storage -oyaml`

Find the default setting

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  annotations:
  ....
    storageclass.kubernetes.io/is-default-class: "false" # This is what we want to change to true
```

We can see this is under metadata.annotations.storageclass.kubernetes.io/is-default-class we can
# now build our patch command

```bash
k patch storageclasses.storage.k8s.io local-storage -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

Check
`k get sc`

We should see our sc is now labelled as default

Step 3 remove other default: We can also see the local-path SC is labelled as default, we don't want two defaults so we need to remove this. Use the command we built above to remove this editing it for the local-path SC and setting default to false. 

```bash
k patch storageclasses.storage.k8s.io local-path -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
```

Check
`k get sc`

We should now only see local-storage as the default

</details>

## -6- Priority Class

```bash
chmod +x Question-6/LabSetUp.bash
./Question-6/LabSetUp.bash
```

### Question
You're working in a kubernetes cluster with an existing deployment named `busybox-logger` running in the `priority` namespace. The cluster already has at least one user defined Priority Class. 

Task:
1. Create a new Priority Class named `high-priority` for user workloads. The value of this class should be exactly one less than the highest existing user-defined priority class. 
2. Patch the existing deployment `busybox-logger` in the `priority` namespace to use the newly created `high-priority` class

Video lnk: https://youtu.be/wiL_M9qbPX4?si=rOIyX45i5kON8Xr7

## -7- Ingress

```bash
chmod +x Question-7/LabSetUp.bash
./Question-7/LabSetUp.bash
```

### Question

Task:
1. Expose the existing deployment with a service called echo-service using Service Port `8080` `type=NodePort`
2. Create a new ingress resource named echo in the echo-sound namespace for `http://example.org/echo`
3. The availability of the Service echo-service can be checked using the following command
`curl NODEIP:NODEPORT/echo`

In the exam it may give you a command like `curl -o /dev/null -s -w "%{http_code}\n" http://example.org/echo`
This requires an ingress controller, to get this to work ensure your `/etc/hosts` file has an entry for your NodeIP pointing to example.org

Video lnk: https://youtu.be/mtORnV8AlI4?si=6fZq-yd8Sezg0a7v

## -8- CRDs

```bash
chmod +x Question-8/LabSetUp.bash
./Question-8/LabSetUp.bash
```

### Question CRDs

Task: 
1. Create a list of all `cert-manager` CRDs and save it to `/root/resources.yaml`
2. Using `kubectl` extract the documentation for the subject specification field of the Certifiate Custom Resource and save it to `/root/subject.yaml`

You may use any output format that `kubectl` supports

Video lnk: https://youtu.be/mKvkcjoYzOc?si=53ob4__-b242y4K_

## -9- Network Policy

```bash
chmod +x Question-9/LabSetUp.bash
./Question-9/LabSetUp.bash
```

### Question
There are two deployments, `Frontend` and `Backend`. `Frontend` is in the `frontend` namespace, Backend is in the `backend` namespace.

Task:
Look at the Network Policy YAML files in `/root/network-policies`. Decide which of the policies provides the functionality to allow interaction between the `frontend` and the `backend` deployments in the least permissive way and deploy that yaml.

Video lnk: https://youtu.be/EIjpWA0AGG4?si=ih4IWm4wsDeIPzbM

## -10- HPA

```bash
chmod +x Question-10/LabSetUp.bash
./Question-10/LabSetUp.bash
```

### Question
Create a new HorizontalPodAutoScaler(HPA) named apache-server in the autoscale namespace

Task:
1. The HPA must target the existing deployment called `apache-deployment` in the `autoscale` namespace
2. Set the HPA to target for `50%` CPU usage per Pod
3. Configure the HPA to have a minimum of `1` pod and a maximum of `4` pods
4. Set the downscale stabilization window to `30` seconds

Video lnk: https://youtu.be/X0ISIy9Bd7U?si=h-GydG4EzPTug6Jt

## -11- CNI

```bash
chmod +x Question-11/LabSetUp.bash
./Question-11/LabSetUp.bash
```

### Question
Install and configure a CNI of your choice tht meets the specified requirements,
Choose one of the following:

Flannel (v0.26.1) using the manifest kube-flannel.yml
https://github.com/flannel-io/flannel/releases/download/v0.26.1/kube-flannel.yml

or

Calico (v3.28.2) using the manifest tigera-operator.yaml
https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/tigera-operator.yaml

The CNI you choose must
1. Let pods communicate with each other
2. Support network policy enforcement
3. Install from manifest

Video lnk: https://youtu.be/SV3V5VwR2sk?si=47uiyuvMD1Vpqbm1

## -12- Persistent Volume

```bash
chmod +x Question-12/LabSetUp.bash
./Question-12/LabSetUp.bash
```

### Question
A user accidentally deleted the MariaDB Deployment in the mariadb namespace. The deployment was configured with persistent storage. Your responsibility is to re-establish the deployment while ensuring data is preserved by reusing the available PersistentVolume.

Task: 
A PersistentVolume already exists and is retained for reuse. Only one PV exists
Create a Persistent Volume Claim (PVC) named mariadb in the mariadb namespace with the spec:

Access Mode = ReadWriteOnce  
Storage = 250Mi

- Edit the MariaDb Deployment file located at `~/mariadb-deploy.yaml` to use the PVC created in the previous step.
- Apply the updated Deployment file to the cluster
- Ensure the MariaDB Deployment is running and Stable

Video lnk: https://youtu.be/0h2Dik_OTvw?si=9hU6-xzCW7AUsmEj

## -13- Cri-Dockerd

```bash
chmod +x Question-13/LabSetUp.bash
./Question-13/LabSetUp.bash
```

### Question

Task:  
- Set up `cri-dockerd`
- Install the debian package `~/cri-dockerd.deb` using `dpkg`
- Enable and start the `cri-docker` service
- Configure these parameters:
1. Set `net.bridge.bridge-nf-call-iptables` to 1
2. Set `net.ipv6.conf.all.forwarding` to 1
3. Set `net.ipv4.ip_forward` to 1
4. Set `net.netfilter.nf_conntrack_max` to 131072

Video lnk: https://youtu.be/u3kUI9lFPWE?si=Pkq74-rfFEp6dmfd

## -14- Kube-apiserver

```bash
chmod +x Question-14/LabSetUp.bash
./Question-14/LabSetUp.bash
```

### Question
After a cluster migration, the controlplane kube-apiserver is not coming up. Before the migration, the etcd was external and in HA, after migration the kube-api server was pointing to etcd peer port `2380`.

Task:
- Fix it

Video lnk: https://youtu.be/p1vNc1GacpI?si=lbUxoj5jOeruLy7B

## -15- Taints and Tolerations

```bash
chmod +x Question-15/LabSetUp.bash
./Question-15/LabSetUp.bash
```

### Question 

Task:
1. Add a taint to node01 so that no normal pods can be scheduled in this node. `key=PERMISSION`, `value=granted`, `Type=NoSchedule`
2. Schedule a Pod on `node01` adding the correct toleration to the spec so it can be deployed.

Video lnk: https://youtu.be/-rs3AoAVyXE?si=nACYrGA5h_4WL-og

## -16- NodePort

```bash
chmod +x Question-16/LabSetUp.bash
./Question-16/LabSetUp.bash
```

### Question
There is a deployment named nodeport-deployment in the relative namespace

Task:
1. Configure the deployment so it can be exposed on port `80`, `name=http`, protocol `TCP`
2. Create a new Service named nodeport-service exposing the container port `80`, protocol `TCP`, Node Port `30080`
3. Configure the new Service to also expose the individual pods using NodePort

Video lnk: https://youtu.be/t1FxX3PmYDQ?si=ryASL-G9X2FCVApQ

## -17- TLS

```bash
chmod +x Question-17/LabSetUp.bash
./Question-17/LabSetUp.bash
```

### Question
There is an existing deployment in the nginx-static namespace. The deployment contains a ConfigMap that supports `TLSv1.2` and `TLSv1.3` as well as a `Secret` for `TLS`.

There is a service called `nginx-service` in the `nginx-static` namespace that is currently exposing the deployment.

Task:
1. Configure the ConfigMap to only support `TLSv1.3`
2. Add the IP address of the service in `/etc/hosts` and name it `ckaquestion.k8s.local`
3. Verify everything is working using the following commands
    `curl -vk --tls-max 1.2 https://ckaquestion.k8s.local` # should fail
    `curl -vk --tlsv1.3 https://ckaquestion.k8s.local` # should work

Video lnk: https://youtu.be/-6QTAhprvTo?si=Rx81y2lHvK2Y_jBF
