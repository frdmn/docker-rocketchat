# docker-rocketchat

My `docker-compose.yml` file/setup to run [Rocket.Chat](https://rocket.chat) in production.

## Installation

1. Make sure you've installed Docker including `docker-compose` support.
2. Clone this repository:

	```shell
	git clone https://github.com/frdmn/docker-rocketchat /opt/Rocket.Chat-docker
	cd /opt/Rocket.Chat-docker
	```

4. Read the Usage instructions in case you need to customize the default setup/stack.
3. Create and start up containers using `docker-compose`:

	```
	docker-compose up -d
	```

## Usage

### Why port 3000? How to add SSL?

Port 3000, because we have our own dedicated load balancer container in this stack which is exposed on port 3000. This load balancer manages the traffic between our application containers, no matter how many we scale up.

In production you probably want to use the default HTTP/HTTPS ports, to do that simply add your reverse proxy by choice and redirect the traffic to the _traeffik_ listener. This reverse proxy can also be used to terminate your SSL connections.

### Scaling in case of performance issues

This service file supports the `docker-compose` builtin scaling. For example to add 3 additional application containers you can simply invoke:

```
$ docker-compose scale rocketchat=4
Creating and starting dev_rocketchat_2 ... done
Creating and starting dev_rocketchat_3 ... done
Creating and starting dev_rocketchat_4 ... done
```

Last but not least restart your stack to let _traeffik_ (our load balancer container) know about the newly added application containers:

```
$ docker-compose restart
```

### Hubot

#### Installation / Setup

If you want to use Hubot, you can use the provided container in the `docker-compose.yml`:

1. Create a new user in your Rocket.Chat instance which Hubot can use to sign in.
2. Go to your `docker-compose.yml` and comment out the Hubot service at the very bottom. (Remove the `#` signs)
3. Adjust the `ROCKETCHAT_USER` and `ROCKETCHAT_PASSWORD` environment variables to match your previously created user credentials.
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

You can use the provided backup script (`opt/mongo-backup-rotate.sh`) to periodically backup your MongoDB:

```
$ DAYS_TO_KEEP=7 MONGO_CONTAINER=rocketchatdocker_mongo_1 BACKUP_DIR=/opt/Rocket.Chat-docker/data/backups /opt/Rocket.Chat-docker/opt/mongo-backup-rotate.sh
```

You can use the following environment variables:

- `DAYS_TO_KEEP`: Days to keep backup dumps, then starts recyling them
- `MONGO_CONTAINER`: The exact name of the mongo container (use `docker ps` to find out)
- `BACKUP_DIR`: The directory to write the dumps to

##### Restore a backup dump

To restore a backup dump, pick one from `data/backups` and run the following Docker exec command:

```
$ docker exec -it rocketchatdocker_mongo_1 mongorestore --archive=/dump/<FILENAME> --gzip
```

Where `<FILENAME>` is the filename of the dump you want to restore.

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
