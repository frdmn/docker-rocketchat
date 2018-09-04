# docker-rocketchat

My `docker-compose.yml` file/setup to run [Rocket.Chat](https://rocket.chat) in production.

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

## Usage

### Why port 3000? How to add SSL?

Port 3000, because this project comes with a load balancer container which is exposed on port 3000. This load balancer manages the traffic between our application containers, no matter how many we scale up.

In production you probably still want to use the default HTTP/HTTPS ports, right? To do that simply add your reverse proxy by choice and redirect the traffic to the _traefik_ listener. This reverse proxy can also be used to terminate your SSL connections.

### Upgrade to a new Rocket.Chat version

To update your Rocket.Chat server you simply need to make sure the `docker-compose.yml` reflects the version you're trying to update to (\*),  pull the new image from Docker hub, stop and destroy your existing application container and recreate them:

```
git pull
docker-compose pull rocketchat
docker-compose stop rocketchat
docker-compose rm rocketchat
docker-compose up -d rocketchat
```

<sub>_(* I will update this (git tracked) `docker-compose.yml` file according to new Rocket.Chat releases.)_</sub>

### Scaling in case of performance issues

This service file supports the `docker-compose` builtin scaling. For example to add 3 additional application containers you can simply invoke:

```
$ docker-compose scale rocketchat=4
Creating and starting dev_rocketchat_2 ... done
Creating and starting dev_rocketchat_3 ... done
Creating and starting dev_rocketchat_4 ... done
```

Last but not least restart _traefik_ (the load balancer) to make sure it knows about the newly added application containers:

```
$ docker-compose restart traefik
```

### Hubot

#### Installation / Setup

If you want to use Hubot, you can use the provided container in the `docker-compose.yml`:

1. Create a new user in your Rocket.Chat instance which Hubot can use to sign in.
2. Open the `docker-compose.yml` and uncomment the Hubot service at the very bottom. (Remove the `#` signs)
3. Adjust the related environment variables in your `.env` file to match your previously created user credentials.
4. Save the file and create the Hubot container:

```
docker-compose up -d hubot
```

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

##### Skip installation wizard

You can skip the initial installation wizard/guide by adding the following environment variables to your application container:

```
- ADMIN_USERNAME=${USERNAME}
- ADMIN_PASS=${PASSWORD}
- ADMIN_EMAIL=${EMAIL}
- OVERWRITE_SETTING_Show_Setup_Wizard=completed
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
