> While nexus documents how to run reva with docker compose in a distributed way, integrating it with an OpenID COnnect Provider, LDAP and EOS as the storage layer, the focus in the last weeks has been or making development easier. Have a look at these central posts for what has been going on:
> 
> - [**Nexus is hard, reva is easy … or it should be!**](https://central.owncloud.org/t/nexus-is-hard-reva-is-easy-or-it-should-be/21027)
> - [Nexus progress as Easter present!](https://central.owncloud.org/t/nexus-progress-as-easter-present/19760)
> - [Digging into the reva “Hello World!” example.md](https://central.owncloud.org/t/digging-into-the-reva-hello-world-example-md/19896)
> - [Supporting s3 in reva](https://central.owncloud.org/t/supporting-s3-in-reva/19512)
> - [MOVE: ownClouds worst nightmare!](https://central.owncloud.org/t/move-ownclouds-worst-nightmare/19388)
> - [**What is nexus? And where did it come from?**](https://central.owncloud.org/t/what-is-nexus-and-where-did-it-come-from/19270)
> - [Interesting problems that need to be solved](https://central.owncloud.org/t/interesting-problems-that-need-to-be-solved/19154)
> 
> The recommended way to get started with OCIS development is currently to run reva and phoenix locally, which is now possible. If you are interested in large scale deployments the nexis makefile in this repo is still the best starting point.
> 
> Cheers
> 
> Jörn

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
- Log in as `aaliyah_abernathy`, `aaliyah_adams` or `aaliyah_anderson` with password `secret`


**Welcome to the nexus!** Have a look around and try syncing!

If you find something to work on you can hack on `./build/src/reva` or  `./build/src/phoenix`.

Changes to reva can be built and redeployed with `make reva-rebuild` or only for specific services.

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
  - openldap as user database with example users
  - `aaliyah_abernathy`, `aaliyah_adams`,`aaliyah_anderson` and all other users have the password `secret`
3. revad as webdav service and storag provider
   - oidc based auth is provided on port 8443 by
     - the ocdavsvc webdav api service
     - the authsvc authentication service
   - basic auth is provided on port 8444
     - the ocdavsvc-basic webdav api service
     - the authsvc-ldap authentication service
   - storageprovidersvc talks to eos

4. phoenix as web interface
5. eos as the underlying storage technology with home dirs precreated for `aaliyah_abernathy`, `aaliyah_adams` and `aaliyah_anderson`

The `Makefile` has help:
```
✗ make help
usage: make [target]

cleanup:
  clean                           Cleanup containers, network and sources
  clean-containers                Stop and cleanup containers
  clean-src                       Cleanup sources

containers:
  demo                            bring up a demo system
  future                          Start a development environment
  up                              docker-compose up all containers
  down                            docker-compose down all containers
  logs                            show and follow nexus container logs

eos:
  start-eos                       Start EOS services
  stop-eos                        Stop EOS services
  eos-src                         Get EOS docker sources

other:
  help                            Show this help

phoenix:
  phoenix-up                      Up phoenix
  phoenix-down                    Down phoenix
  phoenix-restart                 Restart phoenix
  phoenix-rebuild                 Rebuild and restart phoenix
  phoenix-src                     Get phoenix sources

reva:
  reva-up                         Up all reva based containers
  reva-rebuild                    Rebuild and restart all reva based containers
  reva-authsvc-up                 Up the authsvc
  reva-authsvc-rebuild            Rebuild and restart the authsvc
  reva-authsvc-restart            Restart the authsvc
  reva-authsvc-down               Down the authsvc
  reva-ocdavsvc-up                Up the ocdavsvc
  reva-ocdavsvc-rebuild           Rebuild and restart the ocdavsvc
  reva-ocdavsvc-restart           Restart the ocdavsvc
  reva-ocdavsvc-down              Down the ocdavsvc
  reva-ocssvc-up                  Up the ocssvc
  reva-ocssvc-rebuild             Rebuild and restart the ocssvc
  reva-ocssvc-restart             Restart the ocssvc
  reva-ocssvc-down                Down the ocssvc
  reva-storageprovidersvc-up      Up the storageprovidersvc
  reva-storageprovidersvc-rebuild Rebuild and restart the storageprovidersvc
  reva-storageprovidersvc-restart Restart the storageprovidersvc
  reva-storageprovidersvc-down    Down the storageprovidersvc
  reva-src                        Get reva sources

tests:
  test-litmus                     run litmus tests - requires an instance with basic auth credential strategy

```

Have a look at the `Makefile` for how things are done exactly.

# Repository layout

1. `./build/*` contains `Dockerfile`s and a `src` folder for additional components, eg. reva and phoenix
2. `./configs` contains all the configuration files for started services
3. `./deploy`  contains all docker compose yml files
4. `./docs`
5. `./examples` contains example data, eg. ldap users and a reva `data` folder

# Testing

1. point your browser to https://owncloud.localhost:8443/
2. you should be redirected to https://owncloud.localhost:8443/phoenix/ and see an authorize button, click it
3. you should be redirected to kopano, log in as `aaliyah_adams:secret`
4. you should be redirected back to phoenix and see the welcome.txt file

## reva / webdav with curl

After `make future` you should be able to run a propfind using basic auth against the 8444 port:

```
curl 'https://owncloud.localhost:8444/remote.php/webdav' -X PROPFIND -H 'Depth: 1' --data-binary $'<?xml version="1.0"?>\n<d:propfind  xmlns:d="DAV:" xmlns:oc="http://owncloud.org/ns">\n  <d:prop>\n   <d:getetag />\n    <oc:fileid />\n    <oc:permissions />\n    <oc:size />\n  </d:prop>\n</d:propfind>' --compressed -k -u aaliyah_adams:secret
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

FIXME reva and phoenix are both built inside docker containers. You can use them for development.

## reva

The idea is to have a docker container for development and another one for building the release.

## phoenix

The idea is to have a docker container for development that monitors changes and automatically rebuilds the web ui and another one for building the release.

## EOS

EOS is a software solution for central data recording, user analysis and data processing. https://eos.web.cern.ch/
