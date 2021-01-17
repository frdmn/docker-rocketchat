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

4. Create and start up containers using `docker-compose`:

    ```
    docker-compose up -d
    ```

5. Access your Rocket.Chat instance via `http://${HOST_IP}:3000`.

## Usage

### Why port 3000? How to add SSL?

Port 3000, because this project comes with a load balancer container which is exposed on port 3000. This load balancer manages the traffic between our application containers, no matter how many we scale up.

In production you probably still want to use the default HTTP/HTTPS ports, right? To do that simply add your reverse proxy by choice and redirect the traffic to the _traefik_ listener. This reverse proxy can also be used to terminate your SSL connections.

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

### Hubot

#### Installation / Setup

If you want to use Hubot, you can use the provided container in the `docker-compose.hubot.yml`:

1. Create a new user in your Rocket.Chat instance which Hubot can use to sign in.
2. Adjust the related environment variables in your `.env` file to match your previously created user credentials.
3. Save the file and create the Hubot container, make sure to include _both_ the regular `docker-compose.yml` and the `docker-compose.hubot.yml` file into your command:

```
docker-compose -f docker-compose.yml -f docker-compose.hubot.yml up -d hubot
```

> Note: If you decide to use Hubot and include it's `docker-compose.hubot.yml`, make sure to use the `$ docker-compose -f docker-compose.yml -f docker-compose.hubot.yml ...` command syntax from now on for any other task, to make sure your container stack always includes all containers - including Hubot!

#### Custom Hubot scripts

Right now you can either use the `EXTERNAL_SCRIPTS` environment variable within the Hubot Docker container to install NPM-registered scripts or you can use the mounted `./data/hubotscripts` volume to load your local scripts.

### MongoDB

#### Replica set?

You probably already noticed the `mongo-init-replica` container. It is necessary to create the replica set in your MongoDB container and executed only once when you spin up the `docker-compose.yml` file initially. The replica set is necessary to run Rocket.Chat across several instances. (see [Scaling](#scaling-in-case-of-performance-issues))

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

### `MongoError: Can’t find migration version 202`

Downgrade db migrations version to 197.

 ```shell
 docker exec -i -t CONTAINER_MONGODB_NAME bash
 mongo
 use admin
 db.migrations.update({}, {$set: {version: 197, locked: false}})
 exit
 exit
 ```

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
