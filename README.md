# nexus

This repository is used as a starting point for collaboration on the nexus, a new architecture for owncloud. It integrates
- [phoenix](https://github.com/owncloud/phoenix), the new ownCloud vue.js web ui 
- [reva](https://github.com/cernbox/reva), the new [CS3](https://github.com/cernbox/cs3apis/) based storage layer, written in golang
- [konnect](https://github.com/Kopano-dev/konnect), an OpenID Connect capable identity provider (IdP) from Kopano (also golang)
- [caddy](https://github.com/mholt/caddy/) as a reverse proxy
- and further services like [OpenLDAP](https://github.com/openldap/openldap) and [EOS](https://github.com/cern-eos/eos)

# TL;dr

To check out the development environment for the future owncloud file sync and share platform run

- get the sources with `git clone git@github.com:owncloud/nexus.git`
- Run `cd nexus && make future`
- Point your browser to https://owncloud.localhost:8443/ or
- Point your desktop client to https://owncloud.localhost:8444/ (note the different port)
- Log in as `aaliyah_abernathy` with password `secret`

**Welcome to the nexus!** Have a look around and try syncing!

If you find something to work on you can hack on `./build/src/reva` or  `./build/src/phoenix`.

Changes to reva can be built and redeployed with `make reva-rebuild` or only for specific services.

FIXME Changes to phoenix are automatically redeployed by the `yarn run watch` inside the phoenix container.

When you are done, commit the changes in `./build/src/*` to a feature or bugfix branch (as in prefix it with `feature/` or `bugfix/`)

To clean up run

```
make down
make clean
```

Happy coding! If you want to know more have a look at the Makefile!

# Docker compose

We are currently using docker-compose to set up a development environment. Run `make future` to get:
1. a caddy server, used as reverse proxy
2. kopanod as IdP
3. phoenix es web interface
4. openldap as user database with example users
5. revad as webdav service and storag provider
   - oidc based auth is provided on port 8443 by
     - the ocdavsvc webdav api service
     - the authsvc authentication service
   - basic auth is provided on port 8444
     - the ocdavsvc-basic webdav api service
     - the authsvc-ldap authentication service
   - storageprovidersvc sits on top of eos

6. eos as the underlying storage technology

The `Makefile` has help:
```
✗ make help
sage: make [target]

cleanup:
  clean                           Cleanup sources and containers
  clean-containers                Stop and cleanup containers
  clean-src                       Cleanup sources

containers:
  future                          Start a development environment
  up                              docker-compose up all containers
  down                            docker-compose down all containers

other:
  help                            Show this help

phoenix:
  phoenix-container               Build a docker container for phoenix, the web frontend
  phoenix-src                     Get phoenix sources

reva:
  reva-container                  Build a docker container for reva, the storage
  reva-src                        Get reva sources

```

Have a look at the `Makefile` for how things are done exactly.

# Repository layout

1. `./build/*` contains `Dockerfile`s and a `src` folder for additional components, eg. reva and phoenix
2. `./configs` contains all the configuration files for started services
3. `./docs`
4. `./examples` contains example data, eg. ldap users and a reva `data` folder

While phoenix has a `Dockerfile` we use `./build/phoenix/Dockerfile` to start a container for development.

# Testing

1. point your browser to https://owncloud.localhost:8443/
2. you should be redirected to https://owncloud.localhost:8443/phoenix/ and see an authorize button, click it
3. you should be redirected to kopano, log in as aaliyah_abernathy:secret
4. you should be redirected back to phoenix and see the welcome.txt file

## reva / webdav with curl

After `make future` you should be able to run a propfind

```
curl 'https://owncloud.localhost:8443/reva/ocdav/remote.php/webdav' -X PROPFIND -H 'Depth: 1' --data-binary $'<?xml version="1.0"?>\n<d:propfind  xmlns:d="DAV:" xmlns:oc="http://owncloud.org/ns">\n  <d:prop>\n   <d:getetag />\n    <oc:fileid />\n    <oc:permissions />\n    <oc:size />\n  </d:prop>\n</d:propfind>' --compressed -k -u aaliyah_adams:secret
```

## kopano

note: currently oidc is broken

For now you can go to https://owncloud.localhost:8443/signin/v1/identifier/_/authorize?audience=test&scope=openid%20profile&response_type=code&client_id=ownCloud&redirect_uri=https%3A%2F%2Fowncloud.localhost%3A8443%2Fphoenix%2F&state=YOUR_OPAQUE_VALUE to initialize an authorization code flow.

Alternatively, use curl:
```
https://owncloud.localhost:8443/signin/v1/identifier/_/authorize\?audience\=test\&scope\=openid%20profile\&response_type=code\&client_id=ownCloud\&redirect_uri=https%3A%2F%2Fowncloud.localhost%3A8443%2Fphoenix%2F\&state=YOUR_OPAQUE_VALUE -v -k
```
It will forward you to https://owncloud.localhost:8443/signin/v1/identifier?flow=oidc&audience=test&scope=openid%20profile&response_type=code&client_id=ownCloud&redirect_uri=https%3A%2F%2Fowncloud.localhost%3A8443%2Fphoenix%2F&state=YOUR_OPAQUE_VALUE

- [ ] check client_id param, AFAICT it corresponds to `etc/kopano/identifier-registration.yaml:L6`

# Development

reva and phoenix are both build inside docker containers. You can use them for development.

## reva

The idea is to have a docker container for development and another one for building the release.

## phoenix

The idea is to have a docker container for development that monitors changes and automatically rebuilds the web ui and another one for building the release.

## EOS

EOS is a software solution for central data recording, user analysis and data processing. https://eos.web.cern.ch/
