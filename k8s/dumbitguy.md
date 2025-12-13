# CKA Practice Lab 2: DumbItGuy

This is another highly recommended [Youtube playlist](https://www.youtube.com/playlist?list=PLkDZsCgo3Isr4NB5cmyqG7OZwYEx5XOjM) for CKA. 

## Setup for sailor-sh
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
and `apt-get install -y tmux`

Now we need to do something about that timer ...

Navigate to `Exam Controls` and click `End Exam` and `End Exam` (we're not using this!). 

In the Evaluation page, click `Current Exam` and `Connect to Session`. 

You are now free to use this environment uninterrupted!

I am tinkering with the idea of loding these labs into CK-X. I just need a little more free time than I do right now!

</details>

In your lab terminal, run the following to download lab files:

```bash
git clone https://github.com/vj2201/CKA-PREP-2025-v2.git
cd CKA-PREP
```

`cd https://github.com/vj2201/CKA-PREP-2025-v2.git`
`vim notes`

```bash
chmod +x Question-0*/LabSetUp.bash
./Question-0*/LabSetUp.bash

ls Question-0*/ #in case you need to view the question directory
cat Question-0*/SolutionNotes.bash # to view solution notes

%s/old_number/0/g
```

Be sure to save this file!

The above includes common commands you will or may need and the last line can be used to update the question.

For example, to update the above to Question 1 you would use the following in VIM (be sure you are not in insert mode):

```bash
:%s/0/1/g
```

Once you hit enter, the page will be ready to copy/paste for use in the question. 

To create your working tab: `[ctrl + b] c`
To toggle back and forth between tabs, `[ctrol + b] l`

</details>

### Question-1 MariaDB-Persistent volume

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

Step 1: create PVC with no storageClass (PV is pre-reset by LabSetUp.bash)

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
EOF
```

`k apply -f pvc.yaml`
`k -n mariadb` get pvc mariadb
`k get pv mariadb-pv`     # should show Bound to mariadb

Step 2: ensure deployment uses the PVC
mariadb-deploy.yaml should mount claimName: mariadb
(LabSetUp.bash leaves claimName blank for practice)
`k apply -f mariadb-deploy.yaml`
`k -n mariadb get pods`

