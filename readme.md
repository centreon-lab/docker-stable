Docker using canary repository
==============================

Prerequisites:

Docker-compose: <https://docs.docker.com/compose/>

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