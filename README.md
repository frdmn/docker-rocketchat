# docker-rocketchat

My `docker-compose.yml` file/setup to run [Rocket.Chat](https://rocket.chat) in production. Optional containers for Hubot and a complete application monitoring stack available as well.

## Installation

1. Make sure you've installed Docker including `docker-compose` support.
2. Clone this repository:

    ```shell
    git clone https://github.com/frdmn/docker-rocketchat /opt/docker/Rocket.Chat
    cd /opt/docker/Rocket.Chat
    ```

3. Copy and adjust the default environment variables from `.env.sample`:

    ```shell
    cp .env.sample .env
    vi .env
    ```

4. In case you want to use Traefik as reverse proxy with built-in LetsEncrypt TLS support:

    ```shell
    cp docker-compose.override.https+letsencrypt.yml docker-compose.override.yml
    ```

5. Create and start up containers using `docker-compose`:

    ```
    docker-compose up -d
    ```

6. Access your Rocket.Chat instance via `http://${HOST_IP}:3000`.

## Usage

### Choosing the right reverse proxy

To allow realtime scaling of Rocket.Chat application containers, we need a reverse proxy that supports Docker-based container load balancing. Traefik is the one that Rocket.Chat recommends for such purposes. Traefik supports LetsEncrypt out of the box, which can be used to automatically issue and configure a free SSL certificate for your Rocket.Chat server. If you rather want to use your own reverse proxy solution, take a look at the chapter below "External (Nginx, Apache, Caddy)".

#### Traefik (built-in)

If you decide for the built-in Traefik proxy, copy the `docker-compose.override.https+letsencrypt.yml` to `docker-compose.override.yml`. This will make Traefik listen on TCP 80 and 443 (default HTTP and HTTPS ports) while trying to request a certificate for the hostname in question (`$ROCKETCHAT_HOST`).

#### External (Nginx, Apache, Caddy)

If you rather want to use your own reverse proxy, like Nginx, Apache or Caddy, you can use skip the inclusion of the override file (`docker-compose.override.https+letsencrypt.yml`) and use just the regular `docker-compose.yml`. This makes Traefik listen only on the HTTP port specified via `${ROCKETCHAT_PORT}` (3000 by default, can be changed by adjusting accordingly in the `.env` file).

### Upgrade to a new Rocket.Chat version

To update your Rocket.Chat server you simply need to make sure the `docker-compose.yml` reflects the version you're trying to update to (\*),  pull the new image from Docker hub, stop and destroy your existing application container and recreate them:

```
git pull
docker-compose up -d rocketchat
```

<sub>_(* I will update this (git tracked) `docker-compose.yml` file according to new Rocket.Chat releases.)_</sub>

### Scaling in case of performance issues

This service file supports the `docker-compose` builtin scaling. For example to add 3 additional application containers you can simply invoke:

```
$ docker-compose up -d --scale rocketchat=4
Starting 185_docker-rocketchat_traefik_1            ... done
Starting 185_docker-rocketchat_mongo_1              ... done
Starting 185_docker-rocketchat_mongo-init-replica_1 ... done
Starting 185_docker-rocketchat_rocketchat_1         ... done
Creating 185_docker-rocketchat_rocketchat_2         ... done
Creating 185_docker-rocketchat_rocketchat_3         ... done
Creating 185_docker-rocketchat_rocketchat_4         ... done
```

Last but not least restart _traefik_ (the load balancer) to make sure it knows about the newly added application containers:

```
$ docker-compose restart traefik
```

### MongoDB

#### Backup and restore

##### Create a backup

You can use the provided backup script (`./scripts/export-mongo-dump.sh`) to export (and compress if passing `GZIP` environment variable) your MongoDB:

```
$ GZIP=true ./scripts/export-mongo-dump.sh
```

You can also make use of the following environment variables:

- `MONGO_CONTAINER`: The exact name of the mongo container (defaults to `mongo`)
- `GZIP`: Set to `true` if you want to compress your export

```
$ MONGO_CONTAINER=mongo \
  GZIP=true \
  ./scripts/export-mongo-dump.sh
```

The backups will be written to the `./data/backups` directory.

##### Restore a backup dump

To restore a backup dump, pick or place one in `data/backups` and run the following script:

```
$ IMPORTFILE=<FILENAME> \
  GZIP=true \
  ./scripts/import-mongo-dump.sh
```

You can also make use of the following environment variables:

- `IMPORTFILE`: The filename of the dump that you want to import
- `GZIP`: Set to `true` if you want to compress your export

### Monitoring

![](https://i.imgur.com/lghiEqB.png)

If you want to monitor Rocket.Chat on application level, you can make use of the preconfigured stack from the `docker-compose.monitoring.yml` file. To spin up the necessary containers (Grafana, Prometheus, cAdvisor and node-exporter), take a look into the Rocket.Chat.Metrics repository:

https://github.com/RocketChat/Rocket.Chat.Metrics

## Troubleshooting

### `Error: $MONGO_OPLOG_URL must be set to the 'local' database of a Mongo replica set`

This message will be thrown by the application container, if you initially start up (and create) the containers but the replica set was not yet fully configured. Just wait a bit until the replica set was setup in the background. The application will retry the connection periodically and will succeed once the replica set is up.

### `MongoError: not master and slaveOk=false`

The initial database seed is probably not yet fully imported into your MongoDB. As above, wait a bit until it's processed in the background.

## Contributing

1. Fork it
2. Create your feature branch:

    ```shell
    git checkout -b feature/my-new-feature
    ```

3. Commit your changes:

    ```shell
    git commit -am 'Add some feature'
    ```

4. Push to the branch:

    ```shell
    git push origin feature/my-new-feature
    ```

5. Submit a pull request

## Requirements / Dependencies

* Docker

## Version

1.0.0

## License

[MIT](LICENSE)
