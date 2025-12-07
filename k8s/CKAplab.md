# CKA Practice Lab

The CK-X provides the full remote desktop you will use on PSI, similar to killer.sh so you get very comfortable with navigation. 

They started a [hosted version](https://sailor.sh/) but I haven't touched it. We'll be running this locally.

GitHub: https://github.com/sailor-sh/CK-X

### Setup for CK-X

If on Windows, enable WSL2 in docker destop and run:
`irm https://raw.githubusercontent.com/nishanb/ck-x/master/scripts/install.ps1 | iex`

Linux & macOS:

`curl -fsSL https://raw.githubusercontent.com/nishanb/ck-x/master/scripts/install.sh | bash`

Navigate to `http://localhost:30080` if the page doesn’t load automatically. Click `Start Exam` and `Start Exam`. It will default to the CKAD practice exam but it doesn’t really matter since we're loading our own labs!

Click `Start` 3 times. 

Note: You won't be booted once the exam timer runs out. You can end the exam and navigate back to the session if you find it distracting but it's fine to just run it from here. 

```
ssh ckad9999
apt-get update
```

That's it, you have unlimited use to this environment! It's open source so if you have the time to load these labs into CK-X, I'm sure the community would be very grateful! I would love to contribute in this way but work is pretty intense right now. Maybe after I've completed Kubstronaut!

It uses docker compose so you can navigate with the following commands:

To stop CK-X  `docker compose down --volumes --remove-orphans --rmi all`
To Restart CK-X: `docker compose restart`
To clean up all containers and images: `docker system prune -a`
To remove only CK-X images: `docker compose down --rmi all`
To access CK-X Simulator locally navigate to: `http://localhost:30080/`
