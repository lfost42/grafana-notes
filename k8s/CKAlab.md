# CKA Lab

I was following [FreeCodeCamp](https://www.youtube.com/watch?v=Fr9GqFwl6NM) and realized there is an insignificant number of people who will have a bad time trying to follow it. I'm hoping these instructions help more people create a CKA lab environment on a mac while following the video. 

The video uses Ubuntu but it was too big for my Macbook Air so I converted the instructions to use Debian. 

## Part 1.1: Lab VM Setup (Apple Silicon Mac)

This guide requires three virtual machines: `control`, `node01`, and `node02`.  
To practice the entire guide, you will need:

- 1 × Control Plane VM  
- 2 × Worker VMs (minimum)

You’ll create them on an ARM-based MacBook using the free UTM app.

---

### Step 1 – Install UTM and Get Linux

1. **Download UTM**

- Download and install the latest version of UTM from: 
<https://mac.getutm.app/>

2. **Download Ubuntu Server for ARM**

- Go to the [Debian arm64](https://cdimage.debian.org/debian-cd/current/arm64/iso-cd/) download page: 
- Download the **debian-xx.x.x-arm64-netinst.iso** image. 

---

### Step 2 – Create the `control` VM Template

1. **Create the VM**

- Open **UTM** and click the **+** icon to create a new virtual machine.
- Select **Virtualize**.
- Select **Linux**.
- Under **Boot ISO Image**, click **Browse** and select the Ubuntu Server ARM ISO you downloaded.

2. **Allocate Resources** (minimum recommended for CKA lab):

- CPUs: `2` or more 
- Memory: `4096 MB` (4 GB) or more 
- Storage: `20 GB` or more 

Click **Continue**, skip **Shared Directory**, and give your VM a name like `control`. 
Click **Save**.

3. **Configure Networking (Crucial)**

- In the UTM sidebar, right-click the `control` VM and select **Edit**.
- Go to the **Network** tab.
- Change **Network Mode** from `Shared` to **Bridged (Advanced)**. 
> This is essential so nodes can communicate directly on your local network.
- Click **Save**.

---

### Step 3 – Clone the VM Configurations

1. In the UTM sidebar, right-click the `control` VM and select **Clone...** 
2. Name the new VM **`node01`** and click **Clone**. 
3. Repeat the process, cloning `control` again to create **`node02`**.

You now have three identical VM configurations, all sharing the correct network setting.

---

## Part 1.2: Setting up OS and Hosts

---

### Step 1 – Install the OS and Set Hostnames

1. Start all three VMs: `control`, `node01`, `node02` (one by one).
2. Follow the Ubuntu Server installation prompts on each VM.
3. During installation, set a unique hostname for each:

- First VM: `control` 
- Second VM: `node01` 
- Third VM: `node02`

4. After installation, find the VM’s IP address on each node:

```bash
ip a
```

Note each IP somewhere safe.

---

### Step 2 – Install Essential Utilities

*Run on the Control Plane VM and all Worker VMs (via SSH).*

Install helpful tools such as Vim and Tmux:

```bash
sudo apt update
sudo apt install -y vim tmux
```

### Step 3 – Install Kubectl Alias

*Add the alias to your bash config, then reload your shell config.*

```bash
echo 'alias k=kubectl' >> ~/.bashrc
source ~/.bashrc
```

---

## Part 1.3: Kubernetes Setup

### Kubernetes Components Overview

| Component                 | Node Type              | Role & Function                                                                                          |
|---------------------------|------------------------|----------------------------------------------------------------------------------------------------------|
| `kube-apiserver`          | Control Plane          | Front-end for the Control Plane. Exposes the Kubernetes API, performs authentication, validates data.   |
| `etcd`                    | Control Plane          | Key-value store for cluster state, configuration data, and metadata. Critical for cluster health.       |
| `kube-scheduler`          | Control Plane          | Watches for new Pods and selects Nodes for them based on requirements, affinity, taints/tolerations.    |
| `kube-controller-manager` | Control Plane          | Runs controllers (Node, Replication, Endpoint) to reconcile actual vs desired cluster state.            |
| `kubelet`                 | Worker / Control Plane | Agent on each node. Ensures containers are running in Pods and talks to the API server.                 |
| `kube-proxy`              | Worker / Control Plane | Maintains network rules, implements Service abstraction for Pod networking.                             |
| Container Runtime         | Worker / Control Plane | (e.g., containerd) Pulls images and runs containers.                                                    |

---

### Step 1 – Install a Container Runtime

*Run on the Control Plane VM and all Worker VMs.*

1. **Load required kernel modules**  
(Required for Kubernetes networking and CNI functionality):

```bash
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter
```

2. **Configure sysctl for networking**  
(Enables IP forwarding and bridge settings needed by Kubernetes):

```bash
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
```

3. **Install containerd** (container runtime):

```bash
sudo apt update
sudo apt install -y containerd
```

4. **Configure containerd for `systemd` cgroup driver**  
> CKA Note: This is required for consistent resource management between Kubernetes and containerd.

```bash
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
```

5. **Restart and enable containerd**

```bash
sudo systemctl restart containerd
sudo systemctl enable containerd
```

---

### Step 2 – Install Kubernetes Binaries

*Run on the Control Plane VM and all Worker VMs.*

1. **Disable swap**  
> CKA Note: Kubernetes requires swap to be disabled.

```bash
sudo swapoff -a
# Comment out swap in fstab to make it persistent:
sudo sed -i '/\sswap\s/s/^/#/' /etc/fstab
```

2. **Add Kubernetes apt repository (for v1.33)**  

> Note: You will later practice upgrading to v1.34 in Part 2, Section 2.2.

```bash
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl gpg

sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key \
  | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /" \
  | sudo tee /etc/apt/sources.list.d/kubernetes.list
```

3. **Install and hold binaries (`kubelet`, `kubeadm`, `kubectl`)**

```bash
sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

---

### Step 3 – Configure a Single-Node Cluster

*Run on the Control Plane VM only.*

1. **Initialize the control-plane node**

`--pod-network-cidr=10.244.0.0/16` reserves IP range for Flannel CNI:

```bash
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
```

2. **Configure `kubectl` for the current user**

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

3. **Remove the control-plane taint**  
(So workloads can be scheduled on the control-plane node in this lab):

```bash
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
```

4. **Install the Flannel CNI plugin**

```bash
k apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```

5. **Verify the cluster**

```bash
k get nodes
k get pods -n kube-system
```

## Part 2: Cluster Architecture, Installation & Configuration (25%)

*All commands in this Part are run on the Control Plane VM unless otherwise noted.*

---

### Section 2.1: Bootstrapping a Multi-Node Cluster with kubeadm

#### Step 1 – Initializing the Control Plane

*Run on the Control Plane VM.*

1. Recall your kubeadm join command. 

```bash

```

2. **Save the join command**  
You’ll use it on the worker nodes.

3. **Install Calico CNI plugin**

```bash
k apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml
```

4. **Verify cluster and CNI**

```bash
k get pods -n kube-system
k get nodes
```

---

#### Step 2 – Joining Worker Nodes

*Run on each Worker VM (e.g., `node01`, `node02`).*

Use the exact `kubeadm join` command from the control plane output:

```bash
sudo kubeadm join <control-plane-private-ip>:6443 --token <token>   --discovery-token-ca-cert-hash sha256:<hash>
```

Then, on the Control Plane VM, verify:

```bash
k get nodes -o wide
```

---

### Section 2.2: Managing the Cluster Lifecycle  
**Example: Upgrade from 1.33.x to 1.34.0**

#### Step 1 – Upgrade Control Plane: `kubeadm` Binary

*Run on the Control Plane VM.*

```bash
sudo apt-mark unhold kubeadm
sudo apt update && sudo apt install -y kubeadm='1.34.0-1.1'
sudo apt-mark hold kubeadm
```

---

#### Step 2 – Plan and Apply the Upgrade

*Run on the Control Plane VM.*

- `kubeadm upgrade plan` – shows available upgrades.
- `kubeadm upgrade apply` – upgrades control-plane components.

```bash
sudo kubeadm upgrade plan
sudo kubeadm upgrade apply v1.34.0
```

---

#### Step 3 – Upgrade `kubelet` and `kubectl` (Control Plane)

*Run on the Control Plane VM.*

```bash
sudo apt-mark unhold kubelet kubectl
sudo apt update && sudo apt install -y kubelet='1.34.0-1.1' kubectl='1.34.0-1.1'
sudo apt-mark hold kubelet kubectl
sudo systemctl daemon-reload
sudo systemctl restart kubelet
```

---

#### Step 4 – Drain the Worker Node

*Run on the Control Plane VM.*

> CKA critical command for safe maintenance.

```bash
k drain node01 --ignore-daemonsets
```

---

#### Step 5 – Upgrade Binaries (Worker Node)

*Run on the Worker VM being upgraded (e.g., `node01`).*

```bash
sudo apt-mark unhold kubeadm kubelet
sudo apt update
sudo apt install -y kubeadm='1.34.0-1.1' kubelet='1.34.0-1.1'
sudo apt-mark hold kubeadm kubelet
```

---

#### Step 6 – Upgrade Node Configuration and Restart `kubelet`

*Run on the same Worker VM.*

```bash
sudo kubeadm upgrade node
sudo systemctl daemon-reload
sudo systemctl restart kubelet
```

---

#### Step 7 – Uncordon the Node

*Run on the Control Plane VM.*

```bash
k uncordon node01
```

---

### Section 2.2 (continued): Backing Up and Restoring etcd

*Run on the Control Plane VM.*

#### Perform a Backup (using host `etcdctl`)

> CKA Note: Always confirm API version, endpoints, and certificate paths.

```bash
# Create the backup directory first
sudo mkdir -p /var/lib/etcd-backup

sudo ETCDCTL_API=3 etcdctl snapshot save /var/lib/etcd-backup/snapshot.db   --endpoints=https://127.0.0.1:2379   --cacert=/etc/kubernetes/pki/etcd/ca.crt   --cert=/etc/kubernetes/pki/etcd/server.crt   --key=/etc/kubernetes/pki/etcd/server.key
```

#### Perform a Restore

```bash
# Stop kubelet to stop static pods
sudo systemctl stop kubelet

# Restore the snapshot to a new data directory
sudo ETCDCTL_API=3 etcdctl snapshot restore /var/lib/etcd-backup/snapshot.db   --data-dir=/var/lib/etcd-restored

# !! IMPORTANT: Manually edit /etc/kubernetes/manifests/etcd.yaml
# to point to the new data-dir /var/lib/etcd-restored !!

# Restart kubelet to pick up the manifest change
sudo systemctl start kubelet
```

---

### Section 2.3: Implementing a Highly-Available (HA) Control Plane

#### Step 1 – Initialize the First Control-Plane Node

*Run on the first Control Plane VM (e.g., `control`).*

- `--control-plane-endpoint` : Address of the external load balancer.
- `--upload-certs` : Uploads certs for additional control-plane nodes.

```bash
sudo kubeadm init --control-plane-endpoint "load-balancer.example.com:6443" --upload-certs
```

Save:

- The HA `kubeadm join` command for control-plane nodes  
- The `--certificate-key` printed in the output

---

#### Step 2 – Join Additional Control-Plane Nodes

*Run on the second and third Control Plane VMs.*

Use the HA join command from the previous step:

```bash
sudo kubeadm join load-balancer.example.com:6443 --token <token>   --discovery-token-ca-cert-hash sha256:<hash>   --control-plane --certificate-key <key>
```

---

### Section 2.4: Managing Role-Based Access Control (RBAC)

*All commands run on the Control Plane VM.*

#### Step 1 – Create Namespace and ServiceAccount

```bash
k create namespace rbac-test
k create serviceaccount dev-user -n rbac-test
```

---

#### Step 2 – Create Role (Read-Only Pod Access)

`role.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
namespace: rbac-test
name: pod-reader
rules:
- apiGroups: [""]
resources: ["pods"]
verbs: ["get", "list", "watch"]
```

Apply:

```bash
k apply -f role.yaml
```

---

#### Step 3 – Create RoleBinding

`rolebinding.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
name: read-pods
namespace: rbac-test
subjects:
- kind: ServiceAccount
name: dev-user
namespace: rbac-test
roleRef:
kind: Role
name: pod-reader
apiGroup: rbac.authorization.k8s.io
```

Apply:

```bash
k apply -f rolebinding.yaml
```

---

#### Step 4 – Verify Permissions

> CKA Note: `k auth can-i` is the definitive way to check effective permissions.

```bash
# Should be YES
k auth can-i list pods   --as=system:serviceaccount:rbac-test:dev-user -n rbac-test

# Should be NO
k auth can-i delete pods   --as=system:serviceaccount:rbac-test:dev-user -n rbac-test
```

---

### Section 2.5: Application Management with Helm and Kustomize

*All commands run on the Control Plane VM.*

---

#### Helm Demo – Installing an Application

1. **Add a Chart Repository**

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

2. **Install the NGINX Chart with Value Override**

```bash
helm install my-nginx bitnami/nginx --set service.type=NodePort
```

3. **Manage the Application**

```bash
helm upgrade my-nginx bitnami/nginx --set service.type=ClusterIP
helm rollback my-nginx 1
helm uninstall my-nginx
```

---

#### Kustomize Demo – Customizing a Deployment

1. **Create Base Deployment**

```bash
mkdir -p my-app/base
cat <<EOF > my-app/base/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
name: my-app
spec:
replicas: 1
selector:
matchLabels:
app: my-app
template:
metadata:
labels:
app: my-app
spec:
containers:
- name: nginx
image: nginx:1.25.0
EOF
```

2. **Create Base Kustomization**

```bash
cat <<EOF > my-app/base/kustomization.yaml
resources:
- deployment.yaml
EOF
```

3. **Create Production Overlay and Patch**

```bash
mkdir -p my-app/overlays/production
cat <<EOF > my-app/overlays/production/patch.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
name: my-app
spec:
replicas: 3
EOF
```

```bash
cat <<EOF > my-app/overlays/production/kustomization.yaml
bases:
- ../../base
patches:
- path: patch.yaml
EOF
```

4. **Apply the Overlay**

```bash
k apply -k my-app/overlays/production
```

5. **Verify**

```bash
k get deployment my-app
```

## Part 3: Workloads & Scheduling (15%)

*All commands in this Part are run on the Control Plane VM, unless stated otherwise.*

---

### Section 3.1: Mastering Deployments

#### Demo – Performing a Rolling Update

1. **Create a Deployment**

`deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
name: nginx-deployment
spec:
replicas: 3
selector:
matchLabels:
app: nginx
template:
metadata:
labels:
app: nginx
spec:
containers:
- name: nginx
image: nginx:1.24.0
ports:
- containerPort: 80
```

Apply:

```bash
k apply -f deployment.yaml
```

2. **Trigger a Rolling Update (change image)**

```bash
k set image deployment/nginx-deployment nginx=nginx:1.25.0
```

3. **Observe the Rollout**

```bash
k rollout status deployment/nginx-deployment
k get pods -l app=nginx -w
```

---

#### Demo – Executing and Verifying Rollbacks

1. **View Revision History**

```bash
k rollout history deployment/nginx-deployment
```

2. **Roll Back to Previous Version**

```bash
k rollout undo deployment/nginx-deployment
```

3. **Roll Back to a Specific Revision**

```bash
k rollout undo deployment/nginx-deployment --to-revision=1
```

---

### Section 3.2: Configuring Applications with ConfigMaps and Secrets

---

#### Creation Methods

**ConfigMap (Imperative)** – non-confidential key/value data:

```bash
# From literals
k create configmap app-config   --from-literal=app.color=blue   --from-literal=app.mode=production

# From a file
echo "retries = 3" > config.properties
k create configmap app-config-file --from-file=config.properties
```

**Secret (Imperative)** – sensitive data:

```bash
k create secret generic db-credentials   --from-literal=username=admin   --from-literal=password='s3cr3t'
```

---

#### Demo – Consuming ConfigMaps and Secrets as Environment Variables

`pod-config.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
name: config-demo-pod
spec:
containers:
- name: demo-container
image: busybox
command: ["/bin/sh", "-c", "env && sleep 3600"]
env:
- name: THEME
valueFrom:
configMapKeyRef:
name: app-config-declarative
key: ui.theme
- name: DB_PASSWORD
valueFrom:
secretKeyRef:
name: db-credentials
key: password
restartPolicy: Never
```

Apply and verify:

```bash
k apply -f pod-config.yaml
k logs config-demo-pod
```

---

#### Demo – Consuming ConfigMaps via Volumes

`pod-volume.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
name: volume-demo-pod
spec:
containers:
- name: demo-container
image: busybox
command: ["/bin/sh", "-c", "cat /etc/config/config.properties && sleep 3600"]
volumeMounts:
- name: config-volume
mountPath: /etc/config
volumes:
- name: config-volume
configMap:
name: app-config-file
restartPolicy: Never
```

Apply and verify:

```bash
k apply -f pod-volume.yaml
k logs volume-demo-pod
```

---

### Section 3.3: Implementing Workload Autoscaling

#### Demo – Installing and Verifying Metrics Server

1. **Install Metrics Server**

```bash
k apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

2. **Verify**

```bash
k top nodes
k top pods -A
```

---

#### Demo – Autoscaling a Deployment

1. **Create a Deployment with Resource Requests**

```bash
k create deployment php-apache --image=k8s.gcr.io/hpa-example --requests="cpu=200m"
k expose deployment php-apache --port=80
```

2. **Create an HPA**

```bash
k autoscale deployment php-apache --cpu-percent=50 --min=1 --max=10
```

3. **Generate Load**

```bash
k run -it --rm load-generator --image=busybox -- /bin/sh -c      "while true; do wget -q -O- http://php-apache; done"
```

4. **Observe Scaling**

```bash
k get hpa -w
```

Stop the load generator and observe scale down.

---

### Section 3.5: Advanced Scheduling

#### Demo – Node Affinity

1. **Label a Node**

```bash
k label node node01 disktype=ssd
```

2. **Create a Pod with Node Affinity**

> Assumes `affinity-pod.yaml` contains the appropriate `nodeAffinity` spec.

```bash
k apply -f affinity-pod.yaml
```

---

#### Demo – Taints and Tolerations

1. **Taint a Node (`NoSchedule`)**

```bash
k taint node node02 app=gpu:NoSchedule
```

2. **Create a Pod with Matching Toleration**

> Assumes `toleration-pod.yaml` contains the matching `tolerations` spec.

```bash
k apply -f toleration-pod.yaml
```

3. **Verify Scheduling**

```bash
k get pod gpu-pod -o wide
```

## Part 4: Services & Networking (20%)

*All commands in this Part are run on the Control Plane VM, unless specified otherwise.*

---

### Section 4.2: Kubernetes Services

#### Demo – Creating a ClusterIP Service

1. **Create a Deployment**

```bash
k create deployment my-app --image=nginx --replicas=2
```

2. **Expose as ClusterIP**

```bash
k expose deployment my-app --port=80 --target-port=80      --name=my-app-service --type=ClusterIP
```

3. **Verify Access from a Temporary Pod**

```bash
k run tmp-shell --rm -it --image=busybox -- /bin/sh
# Inside the shell:
# wget -O- my-app-service
```

---

#### Demo – Creating a NodePort Service

1. **Expose Deployment as NodePort**

```bash
k expose deployment my-app --port=80 --target-port=80      --name=my-app-nodeport --type=NodePort
```

2. **Get Service and Node IPs**

```bash
k get service my-app-nodeport
k get nodes -o wide
```

Access externally via: `http://<NodeIP>:<NodePort>`

---

### Section 4.3: Ingress and the Gateway API

#### Demo – Path-Based Routing with NGINX Ingress

1. **Install NGINX Ingress Controller**

```bash
k apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.1/deploy/static/provider/cloud/deploy.yaml
```

2. **Deploy Two Sample Apps and Services**

```bash
k create deployment app-one --image=k8s.gcr.io/echoserver:1.4
k expose deployment app-one --port=8080

k create deployment app-two --image=k8s.gcr.io/echoserver:1.4
k expose deployment app-two --port=8080
```

3. **Create an Ingress Resource**

> Assumes `ingress.yaml` defines path-based routing to `app-one` and `app-two`.

```bash
k apply -f ingress.yaml
```

4. **Test Ingress**

```bash
INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress.ip}')
curl http://$INGRESS_IP/app1
curl http://$INGRESS_IP/app2
```

---

### Section 4.4: Network Policies

> CKA Note: Requires a CNI plugin that supports NetworkPolicy (e.g., Calico).

#### Demo – Securing an Application with NetworkPolicies

1. **Create Default Deny-All Ingress Policy**

`deny-all.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
name: default-deny-ingress
spec:
podSelector: {}  # Matches all pods in the namespace
policyTypes:
- Ingress
```

Apply:

```bash
k apply -f deny-all.yaml
```

2. **Deploy a Web Server and Service**

```bash
k create deployment web-server --image=nginx
k expose deployment web-server --port=80
```

3. **Attempt Connection (should fail)**

```bash
k run tmp-shell --rm -it --image=busybox -- /bin/sh -c      "wget -O- --timeout=2 web-server"
```

4. **Create Allow Policy**

`allow-web-access.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
name: allow-web-access
spec:
podSelector:
matchLabels:
app: web-server
policyTypes:
- Ingress
ingress:
- from:
- podSelector:
matchLabels:
access: "true"
ports:
- protocol: TCP
port: 80
```

Apply:

```bash
k apply -f allow-web-access.yaml
```

5. **Test Allowed Access (should succeed)**

```bash
k run tmp-shell --rm -it --labels=access=true --image=busybox --      /bin/sh -c "wget -O- web-server"
```

---

### Section 4.5: CoreDNS

#### Demo – Customizing CoreDNS for an External Domain

1. **Edit CoreDNS ConfigMap**

```bash
k edit configmap coredns -n kube-system
```

2. **Add a New Server Block (inside `data.Corefile`)**

```text
my-corp.com:53 {
errors
cache 30
forward . 10.10.0.53 # Forward to your internal DNS server
}
```

This forwards `my-corp.com` queries to your internal DNS server (`10.10.0.53`).

## Part 5: Storage (10%)

*All commands in this Part are run on the Control Plane VM, unless specified otherwise.*

---

### Section 5.2: Volume Configuration – Static Provisioning Demo

#### Step 1 – Create a PersistentVolume

`pv.yaml`:

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
name: task-pv-volume
spec:
capacity:
storage: 10Gi
accessModes:
- ReadWriteOnce
persistentVolumeReclaimPolicy: Retain
storageClassName: manual
hostPath:
path: "/mnt/data"
```

Apply:

```bash
k apply -f pv.yaml
```

---

#### Step 2 – Create a PersistentVolumeClaim

`pvc.yaml`:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
name: task-pv-claim
spec:
storageClassName: manual
accessModes:
- ReadWriteOnce
resources:
requests:
storage: 3Gi
```

Apply:

```bash
k apply -f pvc.yaml
```

Verify binding:

```bash
k get pv,pvc
```

---

#### Step 3 – Create a Pod that Uses the PVC

`pod-storage.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
name: storage-pod
spec:
containers:
- name: nginx
image: nginx
volumeMounts:
- mountPath: "/usr/share/nginx/html"
name: my-storage
volumes:
- name: my-storage
persistentVolumeClaim:
claimName: task-pv-claim
```

Apply:

```bash
k apply -f pod-storage.yaml
```

---

### Section 5.3: StorageClasses and Dynamic Provisioning

#### Step 1 – Inspect StorageClasses

```bash
k get storageclass
```

#### Step 2 – Create a PVC Without a PV (Dynamic Provisioning)

`dynamic-pvc.yaml`:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
name: my-dynamic-claim
spec:
accessModes:
- ReadWriteOnce
resources:
requests:
storage: 1Gi
```

Apply:

```bash
k apply -f dynamic-pvc.yaml
```

Observe dynamic PV creation:

```bash
k get pv
```

## Part 6: Troubleshooting (30%)

*All commands in this Part are run on the Control Plane VM, unless specified otherwise.*

---

### Section 6.2: Troubleshooting Applications and Pods

1. **Describe a Pod** (first command for debugging):

```bash
k describe pod <pod-name>
```

2. **Check Current Container Logs**

```bash
k logs <pod-name>
```

3. **Check Logs from Previous Crashed Container**

```bash
k logs <pod-name> --previous
```

4. **Get a Shell Inside a Container**

```bash
k exec -it <pod-name> -- /bin/sh
```

---

### Section 6.3: Troubleshooting Cluster and Nodes

1. **Check Node Status**

```bash
k get nodes
```

2. **Describe a Node**

```bash
k describe node controlplane
```

3. **View Node Resource Capacity (for scheduling)**

```bash
k describe node controlplane | grep Allocatable
```

4. **Check `kubelet` Service (on Node VM via SSH)**

```bash
sudo systemctl status kubelet
sudo journalctl -u kubelet -f
```

5. **Re-enable Scheduling on a Cordoned Node**

```bash
k uncordon node01
```

---

### Section 6.5: Troubleshooting Services and Networking

1. **Check Service and Endpoints**

```bash
k describe service <service-name>
```

2. **Check DNS Resolution from a Client Pod**

```bash
k exec -it client-pod -- nslookup <service-name>
```

3. **Check Network Policies**

```bash
k get networkpolicy
```

---

### Section 6.6: Monitoring Cluster and Application Resource Usage

1. **Node Resource Usage (requires Metrics Server)**

```bash
k top nodes
```

2. **Pod Resource Usage**

```bash
k top pods -n <namespace>
```




