Docker using canary repository
==============================

Prerequisites:

Docker-compose: <https://docs.docker.com/compose/>

Licenses
--------

create a directory at the root of this repository named `licenses` (or customize it in the `docker-compose.yml` file) and place the license files in this directory. This directory will be automatically mounted on the container in `/etc/centreon/license.d`.

How to use:

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