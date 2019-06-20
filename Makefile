# *****************************************************************************
# * W E L C O M E
# *****************************************************************************
#
# Congratulations, you have arrived at the ownCloud
#
#
#   _______  _______________  _______ ___  _________
#   \      \ \_   _____/\   \/  /    |   \/   _____/
#   /   |   \ |    __)_  \     /|    |   /\_____  \ 
#  /    |    \|        \ /     \|    |  / /        \
#  \____|__  /_______  //___/\  \______/ /_______  /
#          \/        \/       \_/                \/ 
#
#
# This makefile serves as a self documenting starting point for nexus driven
# tasks. If you just want to get an instance up and running do a
#
#    make future
#
# And point your browser to https://owncloud.localhost:8443
#
# Otherwise, read on ...
#
# *****************************************************************************
# * I N T R O D U C T I O N
# *****************************************************************************
#
# This makefile contains a few sections marked by two star rows. Each section
# is used to group related commands in the nexus. It helps to have a basic
# understanding of makefiles. A good starting point is
# https://medium.freecodecamp.org/want-to-know-the-easiest-way-to-save-time-use-make-eec453adf7fe
#
# TODO use eval to check if containers are up when rebuilding / restarting them?
#
# *****************************************************************************
# * E N V I R O N M E N T   V A R I A B L E S
# *****************************************************************************

# TODO get rid of CURRENT_UID, is only used by KOPANO AFAICT (jfd)
CURRENT_UID := $(shell id -u):$(shell id -g)

# *****************************************************************************
# * B R A N C H E S
# *****************************************************************************
# for easier switching between branches you can set the branches as as env vars
# by running `make REVA_BRANCH=bugfix/x PHOENIX_BRANCH=feature/y future`
# ?! allows 
# TODO use tags in those repos?
REVA_BRANCH ?= nexus
PHOENIX_BRANCH ?= nexus

# *****************************************************************************
# * H E L P   M E C H A N I S M
# *****************************************************************************
#
# Makefile help mechanism taken from from https://gist.github.com/prwhite/8168133#gistcomment-1727513
#
# And add help text after each target name starting with '\#\#'
# A category can be added with @category

#COLORS
GREEN  := $(shell tput -Txterm setaf 2)
WHITE  := $(shell tput -Txterm setaf 7)
YELLOW := $(shell tput -Txterm setaf 3)
RESET  := $(shell tput -Txterm sgr0)

HELP_FUN = \
	%help; \
	while(<>) { push @{$$help{$$2 // 'options'}}, [$$1, $$3] if /^([a-zA-Z\-]+)\s*:.*\#\#(?:@([a-zA-Z\-]+))?\s(.*)$$/ }; \
	print "usage: make [target]\n\n"; \
	for (sort keys %help) { \
	print "${WHITE}$$_:${RESET}\n"; \
	for (@{$$help{$$_}}) { \
	$$sep = " " x (32 - length $$_->[0]); \
	print "  ${YELLOW}$$_->[0]${RESET}$$sep${GREEN}$$_->[1]${RESET}\n"; \
	}; \
	print "\n"; }

# *****************************************************************************
# * G E N E R A L
# *****************************************************************************

# render a dynamically generated help
help: ##@other Show this help
	@perl -e '$(HELP_FUN)' $(MAKEFILE_LIST)

# by default show the help
default: help

# *****************************************************************************
# * N E T W O R K
# *****************************************************************************
# we create the ocis network manually so we can up and down services on the same network
network-up:
	docker network create ocis

network-down:
	docker network rm ocis

# *****************************************************************************
# * C O N T A I N E R S
# *****************************************************************************

demo: up ##@containers bring up a demo system



# *****************************************************************************
# * I D E N T I T Y   M A N A G A M E N T
# *****************************************************************************

idm-up:
	CURRENT_UID=$(CURRENT_UID) docker-compose \
	  -f deploy/network.yml \
	  -f deploy/idm/konnectd.yml \
	  -f deploy/idm/openldap.yml \
	  up -d

idm-down:
	CURRENT_UID=$(CURRENT_UID) docker-compose \
	  -f deploy/network.yml \
	  -f deploy/idm/konnectd.yml \
	  -f deploy/idm/openldap.yml \
	  down

idm-restart:
	CURRENT_UID=$(CURRENT_UID) docker-compose \
	  -f deploy/network.yml \
	  -f deploy/idm/konnectd.yml \
	  -f deploy/idm/openldap.yml \
	  restart

# to build the future we need to bring up a dev environment
future: up ##@containers Start a development environment
# TODO open the browser, but switch depending on linux (xdgopen) or mac env (open)
#    xdg-open "https://owncloud.localhost:8443"
#    open "https://owncloud.localhost:8443"

up: network-up storage-up reva-src phoenix-src ##@containers docker-compose up all containers
	CURRENT_UID=$(CURRENT_UID) docker-compose \
	  -f deploy/network.yml \
	  -f deploy/caddy.yml \
	  -f deploy/idm/konnectd.yml \
	  -f deploy/idm/openldap.yml \
	  -f deploy/reva/authsvc.yml \
	  -f deploy/reva/ocdavsvc.yml \
	  -f deploy/reva/ocssvc.yml \
	  -f deploy/reva/reva-basic.yml \
	  -f deploy/reva/storageprovidersvc-eos.yml \
	  -f deploy/phoenix/phoenix.yml \
	  up -d

down: stop-eos ##@containers docker-compose down all containers
	CURRENT_UID=$(CURRENT_UID) docker-compose \
	  -f deploy/network.yml \
	  -f deploy/caddy.yml \
	  -f deploy/idm/konnectd.yml \
	  -f deploy/idm/openldap.yml \
	  -f deploy/reva/authsvc.yml \
	  -f deploy/reva/ocdavsvc.yml \
	  -f deploy/reva/ocssvc.yml \
	  -f deploy/reva/reva-basic.yml \
	  -f deploy/reva/storageprovidersvc-eos.yml \
	  -f deploy/phoenix/phoenix.yml \
	  down
	docker network rm ocis

logs: ##@containers show and follow nexus container logs
	docker-compose \
	  -f deploy/network.yml \
	  -f deploy/caddy.yml \
	  -f deploy/idm/konnectd.yml \
	  -f deploy/idm/openldap.yml \
	  -f deploy/reva/authsvc.yml \
	  -f deploy/reva/ocdavsvc.yml \
	  -f deploy/reva/ocssvc.yml \
	  -f deploy/reva/reva-basic.yml \
	  -f deploy/reva/storageprovidersvc-eos.yml \
	  -f deploy/phoenix/phoenix.yml \
	  logs -f

# all steps are stateless, future is just an alias
.PHONY: up down logs

# *****************************************************************************
# * R E V A
# *****************************************************************************
#
# While reva can be used to start all reva services in one container we start
# individual containers to be able to only show u subset of the extensive
# logging generated by reva. Have a look at the deploy/*.yml docker-compose 
# files for more details on what config us used for which container.
reva-up: reva-src ##@reva Up all reva based containers
	docker-compose \
	  -f deploy/network.yml \
	  -f deploy/reva/authsvc.yml \
	  -f deploy/reva/ocdavsvc.yml \
	  -f deploy/reva/ocssvc.yml \
	  -f deploy/reva/reva-basic.yml \
	  -f deploy/reva/storageprovidersvc-eos.yml \
	  up -d

reva-rebuild: reva-src ##@reva Rebuild and restart all reva based containers
	docker-compose \
	  -f deploy/network.yml \
	  -f deploy/reva/authsvc.yml \
	  -f deploy/reva/ocdavsvc.yml \
	  -f deploy/reva/ocssvc.yml \
	  -f deploy/reva/reva-basic.yml \
	  -f deploy/reva/storageprovidersvc-eos.yml \
	  up -d --build --force-recreate

# *** authsvc *****************************************************************

reva-authsvc-up: reva-src ##@reva Up the authsvc
	docker-compose \
	  -f deploy/network.yml \
	  -f deploy/reva/authsvc.yml \
	  up -d

reva-authsvc-rebuild: reva-src ##@reva Rebuild and restart the authsvc
	docker-compose \
	  -f deploy/network.yml \
	  -f deploy/reva/authsvc.yml \
	  up -d --build --force-recreate authsvc

reva-authsvc-restart: reva-src ##@reva Restart the authsvc
	docker-compose \
	  -f deploy/network.yml \
	  -f deploy/reva/authsvc.yml \
	  restart

reva-authsvc-down: ##@reva Down the authsvc
	docker-compose \
	  -f deploy/network.yml \
	  -f deploy/reva/authsvc.yml \
	  down

# *** ocdavsvc ****************************************************************

reva-ocdavsvc-up: reva-src ##@reva Up the ocdavsvc
	docker-compose \
	  -f deploy/network.yml \
	  -f deploy/reva/ocdavsvc.yml \
	  up -d

reva-ocdavsvc-rebuild: reva-src ##@reva Rebuild and restart the ocdavsvc
	docker-compose \
	  -f deploy/network.yml \
	  -f deploy/reva/ocdavsvc.yml \
	  up -d --build --force-recreate ocdavsvc

reva-ocdavsvc-restart: reva-src ##@reva Restart the ocdavsvc
	docker-compose \
	  -f deploy/network.yml \
	  -f deploy/reva/ocdavsvc.yml \
	  restart

reva-ocdavsvc-down: ##@reva Down the ocdavsvc
	docker-compose \
	  -f deploy/network.yml \
	  -f deploy/reva/ocdavsvc.yml \
	  down

# *** ocssvc ******************************************************************

reva-ocssvc-up: reva-src ##@reva Up the ocssvc
	docker-compose \
	  -f deploy/network.yml \
	  -f deploy/reva/ocssvc.yml \
	  up -d

reva-ocssvc-rebuild: reva-src ##@reva Rebuild and restart the ocssvc
	docker-compose \
	  -f deploy/network.yml \
	  -f deploy/reva/ocssvc.yml \
	  up -d --build --force-recreate ocssvc

reva-ocssvc-restart: reva-src ##@reva Restart the ocssvc
	docker-compose \
	  -f deploy/network.yml \
	  -f deploy/reva/ocssvc.yml \
	  restart

reva-ocssvc-down: ##@reva Down the ocssvc
	docker-compose \
	  -f deploy/network.yml \
	  -f deploy/reva/ocssvc.yml \
	  down

# *** storageprovidersvc ******************************************************

reva-storageprovidersvc-up: reva-src ##@reva Up the storageprovidersvc
	docker-compose \
	  -f deploy/network.yml \
	  -f deploy/reva/storageprovidersvc-eos.yml \
	  up -d

reva-storageprovidersvc-rebuild: reva-src ##@reva Rebuild and restart the storageprovidersvc
	docker-compose \
	  -f deploy/network.yml \
	  -f deploy/reva/storageprovidersvc-eos.yml \
	  up -d --build --force-recreate storageprovidersvc

reva-storageprovidersvc-restart: reva-src ##@reva Restart the storageprovidersvc
	# TODO(jfd) the storageprovidersvc needs to be killed, that leaves the pid file so we down & up the container.
	docker-compose \
	  -f deploy/network.yml \
	  -f deploy/reva/storageprovidersvc-eos.yml \
	  down
	docker-compose \
	  -f deploy/network.yml \
	  -f deploy/reva/storageprovidersvc-eos.yml \
	  up -d

reva-storageprovidersvc-down: ##@reva Down the storageprovidersvc
	docker-compose \
	  -f deploy/network.yml \
	  -f deploy/reva/storageprovidersvc-eos.yml \
	  down

# *** sources *****************************************************************

reva-src: build/reva/src ##@reva Get reva sources
build/reva/src:
	git clone git@github.com:owncloud/reva.git build/reva/src 
	cd build/reva/src ; \
	  git checkout $(REVA_BRANCH) ; \
	  git remote add upstream git@github.com:cs3org/reva.git

# docker-compose leaves no files we could check, mark as stateless
.PHONY: reva-container

# *****************************************************************************
# * P H O E N I X
# *****************************************************************************
# Phoenix is the new web frontent

phoenix-up: phoenix-src ##@phoenix Up phoenix
	docker-compose \
	  -f deploy/network.yml \
	  -f deploy/phoenix/phoenix.yml \
	  up -d

phoenix-down: ##@phoenix Down phoenix
	docker-compose \
	  -f deploy/network.yml \
	  -f deploy/phoenix/phoenix.yml \
	  down

phoenix-restart: phoenix-src ##@phoenix Restart phoenix
	docker-compose \
	  -f deploy/network.yml \
	  -f deploy/phoenix/phoenix.yml \
	  restart

phoenix-rebuild: phoenix-src ##@phoenix Rebuild and restart phoenix
	docker-compose \
	  -f deploy/network.yml \
	  -f deploy/phoenix/phoenix.yml \
	  up -d --no-deps --build --force-recreate phoenix

phoenix-src: build/phoenix/src ##@phoenix Get phoenix sources
build/phoenix/src:
	git clone git@github.com:owncloud/phoenix.git build/phoenix/src
	cd build/phoenix/src ; \
	  git checkout $(PHOENIX_BRANCH)

# docker-compose leaves no files we could check, mark as stateless
.PHONY: phoenix-rebuild phoenix-container

# *****************************************************************************
# * S T O R A G E
# *****************************************************************************
# The currrent storage layer for the nexus is eos
#
# For more information go to https://eos.web.cern.ch/
# Technical docs can be found at http://eos-docs.web.cern.ch/eos-docs/

storage-up: start-eos
# TODO(jfd) allow using local storage

start-eos: eos-src ##@eos Start EOS services
	# TODO find a way to properly inject the following env vars into the container:
	# EOS_UTF8=1 enables utf8 filenames
	# EOS_NS_ACCOUNTING=1 enables dir size propagation
	# EOS_SYNCTIME_ACCOUNTING=1 enables mtime propagation
	#  - needs the sys.mtime.propagation=1 on a home dir, see below
	#  - sys.allow.oc.sync=1 is not needed, it is an option for the eos built in webdav endpoint
	# for now, we patch the start_servicas.sh and use that
	sed -e "s/--name eos-mgm-test --net/--name eos-mgm-test --env EOS_UTF8=1 --env EOS_NS_ACCOUNTING=1 --env EOS_SYNCTIME_ACCOUNTING=1 --net/" ./build/eos-docker/src/scripts/start_services.sh > ./build/eos-docker/src/scripts/start_services_nexus.sh
	chmod +x ./build/eos-docker/src/scripts/start_services_nexus.sh
	# TODO update eos to 4.4.47 ... or whatever is up to date: see https://gitlab.cern.ch/dss/eos/tags
	./build/eos-docker/src/scripts/start_services_nexus.sh -i gitlab-registry.cern.ch/dss/eos:4.4.25 -n 1

	# Allow resolving uids against ldap
	docker exec -i eos-mgm-test yum install -y nss-pam-ldapd nscd authconfig
	docker exec -i eos-mgm-test authconfig --enableldap --enableldapauth --ldapserver="openldap" --ldapbasedn="dc=owncloudqa,dc=com" --update
	docker exec -i eos-mgm-test sed -i "s/#binddn cn=.*/binddn cn=admin,dc=owncloudqa,dc=com/" /etc/nslcd.conf
	docker exec -i eos-mgm-test sed -i "s/#bindpw .*/bindpw admin/" /etc/nslcd.conf
	docker exec -i eos-mgm-test nslcd

	# TODO allow creating homes on the fly?
	docker exec -i eos-mgm-test eos mkdir eos/dockertest/aaliyah_abernathy
	docker exec -i eos-mgm-test eos mkdir eos/dockertest/aaliyah_adams
	docker exec -i eos-mgm-test eos mkdir eos/dockertest/aaliyah_anderson
	
	# make daemon the owner of the file?
	# TODO clarify: the sss auth seems to force user daemon to do everything, eos -r 0 0 or eos -r 1500 1500 does not change the actual user
	# make users own the dirs
	docker exec -i eos-mgm-test eos chown 10003:1000 eos/dockertest/aaliyah_abernathy
	docker exec -i eos-mgm-test eos chown 10004:1000 eos/dockertest/aaliyah_adams
	docker exec -i eos-mgm-test eos chown 10009:1000 eos/dockertest/aaliyah_anderson

	# set sticky bit so new files are owned by the users group
	docker exec -i eos-mgm-test eos chmod 2775 eos/dockertest/aaliyah_abernathy
	docker exec -i eos-mgm-test eos chmod 2775 eos/dockertest/aaliyah_adams
	docker exec -i eos-mgm-test eos chmod 2775 eos/dockertest/aaliyah_anderson

	# enable mtime propagation for home dirs
	docker exec -i eos-mgm-test eos attr set sys.mtime.propagation=1 eos/dockertest/aaliyah_abernathy
	docker exec -i eos-mgm-test eos attr set sys.mtime.propagation=1 eos/dockertest/aaliyah_adams
	docker exec -i eos-mgm-test eos attr set sys.mtime.propagation=1 eos/dockertest/aaliyah_anderson

	# allow storageprovidersvc to set acls on behalf of users
	docker exec -i eos-mgm-test eos vid add gateway storageprovidersvc
	#TODO(jfd) this needs proper auth check
	docker exec -i eos-mgm-test eos vid set membership 0 +sudo

stop-eos: eos-src ##@eos Stop EOS services
	./build/eos-docker/src/scripts/shutdown_services.sh

eos-src: build/eos-docker/src ##@eos Get EOS docker sources
build/eos-docker/src: 
	git clone https://gitlab.cern.ch/eos/eos-docker.git build/eos-docker/src

# eos keeps track of itself using custom scripts. Don't touch it, mark as stateless
.PHONY: start-eos stop-eos

# *****************************************************************************
# * R E V E R S E   P R O X Y
# *****************************************************************************
# We currently use caddy a sa reverse proxy
# TODO(jfd) allow swapping out services with local running ones

proxy-up: 	
	docker-compose \
	  -f deploy/network.yml \
	  -f deploy/caddy.yml \
	  up -d

proxy-down: 	
	docker-compose \
	  -f deploy/network.yml \
	  -f deploy/caddy.yml \
	  down

proxy-restart:	
	docker-compose \
	  -f deploy/network.yml \
	  -f deploy/caddy.yml \
	  restart

# *****************************************************************************
# * C L E A N U P
# *****************************************************************************

clean: clean-containers network-down clean-src ##@cleanup Cleanup containers, network and sources

clean-containers: ##@cleanup Stop and cleanup containers
	CURRENT_UID=$(CURRENT_UID) docker-compose \
	  -f deploy/network.yml \
	  -f deploy/caddy.yml \
	  -f deploy/idm/konnectd.yml \
	  -f deploy/idm/openldap.yml \
	  -f deploy/reva/authsvc.yml \
	  -f deploy/reva/ocdavsvc.yml \
	  -f deploy/reva/ocssvc.yml \
	  -f deploy/reva/reva-basic.yml \
	  -f deploy/reva/storageprovidersvc-eos.yml \
	  -f deploy/phoenix/phoenix.yml \
	  rm -s

clean-src: ##@cleanup Cleanup sources
	-rm -rf build/reva/src
	-rm -rf build/phoenix/src

# clean steps should always run, mark as stateless
.PHONY: clean-containers clean-src

# *****************************************************************************
# * T E S T S
# *****************************************************************************

test-litmus: ##@tests run litmus tests - requires an instance with basic auth credential strategy
	# FIXME mounting the folder 'litmus' does not work from within the makefile
	docker run \
	  -e LITMUS_URL="http://ocdavsvc-basic:9998/remote.php/webdav/" \
	  -e LITMUS_USERNAME=aaliyah_adams \
	  -e LITMUS_PASSWORD=secret \
	  --network=deploy_ocis \
	  -v "$(pwd)"/litmus:/root \
	  owncloud/litmus

# docker-compose leaves no files we could check, mark as stateless
.PHONY: up-litmus test-litmus