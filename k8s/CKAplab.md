# CKA Practice Lab

The CK-X provides the full remote desktop you will use on PSI, similar to killer.sh so you get very comfortable with navigation. 

### Setting up CK-X

If on Windows, check instructions on GitHub: https://github.com/sailor-sh/CK-X

The following is for MacOS:

`curl -fsSL https://raw.githubusercontent.com/nishanb/ck-x/master/scripts/install.sh | bash`

Navigate to `http://localhost:30080` if the page doesn’t load automatically. Click `Start Exam` and `Start Exam`. It will default to the CKAD practice exam but it doesn’t really matter since we're loading our own labs!

Click `Start` 3 times. 

Note: You won't be booted once the exam timer runs out. 

```ssh ckad9999
apt-get update```

That's it, you have unlimited use to this environment!

It uses docker compose so you can navigate with the following commands:

To stop CK-X  `docker compose down --volumes --remove-orphans --rmi all`
To Restart CK-X: `docker compose restart`
To clean up all containers and images: `docker system prune -a`
To remove only CK-X images: `docker compose down --rmi all`
To access CK-X Simulator locally navigate to: `http://localhost:30080/`
