# Website back-end written in Swift.

This is a back-end project that written in Swift. for it's front-end see [Website](https://github.com/littlerkie/website) for more information.

## Get started

This app is built with Swift. It use MySQL for db. If you have docker installed, it will be simple to launch a new service. otherwise you need make sure you have Swift and MySQL installed, so we recommended you to use docker to deploy you own service.

### Database

There are several environment variable required by project. the hostname  `MYSQL_HOST` of database username  `MYSQL_USER` password `MYSQL_PASSWORD` and database name  `MYSQL_DATABASE`.  you can update those variable in `docker-compose.test.yml`.    
To launch db just run:
```shell
docker-compose -f docker/docker-compose.test.yml up -d db
```

### App
To launch app run:
```shell
docker-compose -f docker/docker-compose.test.yml up app
```
