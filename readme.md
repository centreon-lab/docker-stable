Docker using canary repository
==============================

Prerequisites:

- Docker-compose: <https://docs.docker.com/compose/>
- [ssh key](#create-a-key-to-use-with-ssh)
- [License modules](#using-licenses-module)

Using licenses module
---------------------

Create a directory at the root of this repository named `licenses` (or customize it in the `docker-compose.yml` file) and place the license files in this directory. This directory will be automatically mounted on the container in `/etc/centreon/license.d`.

Create a key to use with SSH
----------------------------

Create a key using this command:

```bash
mkdir ssh
ssh-keygen -t rsa -f ssh/id_rsa
```

Change the file `docker-compose`, in entry `- ./ssh/id_rsa:/var/spool/centreon/.ssh/id_rsa` with you ssh key path.

How to use
----------

```bash
docker-compose up
```

To always force build of containers, use the command:

```bash
docker-compose up --build
```

For clean all enviorement:

```bash
docker-compose down -v --rmi local
```