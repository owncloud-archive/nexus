CURRENT_UID=$(shell id -u):$(shell id -g)

# Makefile help mechanism taken from from https://gist.github.com/prwhite/8168133#gistcomment-1727513
#COLORS
GREEN  := $(shell tput -Txterm setaf 2)
WHITE  := $(shell tput -Txterm setaf 7)
YELLOW := $(shell tput -Txterm setaf 3)
RESET  := $(shell tput -Txterm sgr0)

# Add the following 'help' target to your Makefile
# And add help text after each target name starting with '\#\#'
# A category can be added with @category
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

help: ##@other Show this help
	@perl -e '$(HELP_FUN)' $(MAKEFILE_LIST)

default: help

future: up ##@containers Start a development environment

.PHONY: reva-container
reva-container: reva-src ##@reva Build a docker container for reva, the storage
	docker-compose -f deploy/core.yml -f deploy/storage/eos.yml build authsvc ocdavsvc storageprovidersvc

.PHONY: reva-rebuild-auth
reva-rebuild-auth: ##@reva Rebuild and restart the storage container without bringing down the nexus
	docker-compose -f deploy/core.yml -f deploy/storage/eos.yml up -d --no-deps --build authsvc

.PHONY: reva-rebuild-ocdav
reva-rebuild-ocdav: ##@reva Rebuild and restart the storage container without bringing down the nexus
	docker-compose -f deploy/core.yml -f deploy/storage/eos.yml up -d --no-deps --build ocdavsvc

.PHONY: reva-rebuild-storage
reva-rebuild-storage: ##@reva Rebuild and restart the storage container without bringing down the nexus
	docker-compose -f deploy/core.yml -f deploy/storage/eos.yml up -d --no-deps --build storageprovidersvc


reva-src: build/reva/src ##@reva Get reva sources
build/reva/src:
	git clone git@github.com:owncloud/reva.git build/reva/src 
	cd build/reva/src; \
	git checkout nexus; \
	git remote add upstream git@github.com:cernbox/reva.git

.PHONY: phoenix-container
phoenix-container: phoenix-src ##@phoenix Build a docker container for phoenix, the web frontend
	docker-compose -f deploy/core.yml build phoenix

build/eos-docker/src:
	git clone https://gitlab.cern.ch/eos/eos-docker.git build/eos-docker/src

.PHONY: start-eos
start-eos: build/eos-docker/src
	./build/eos-docker/src/scripts/start_services.sh -i gitlab-registry.cern.ch/dss/eos:4.4.25 -n 1

.PHONY: stop-eos
stop-eos: build/eos-docker/src
	./build/eos-docker/src/scripts/shutdown_services.sh

phoenix-src: build/phoenix/src ##@phoenix Get phoenix sources
build/phoenix/src:
	git clone git@github.com:owncloud/phoenix.git build/phoenix/src

.PHONY: up
up: start-eos reva-container phoenix-container ##@containers docker-compose up all containers
	CURRENT_UID=$(CURRENT_UID) docker-compose -f deploy/core.yml -f deploy/storage/eos.yml up -d

.PHONY: down
down: stop-eos ##@containers docker-compose down all containers
	CURRENT_UID=$(CURRENT_UID) docker-compose -f deploy/core.yml -f deploy/storage/eos.yml down

.PHONY: logs
logs: 
	docker-compose -f deploy/core.yml -f deploy/storage/eos.yml logs -f

.PHONY: litmus
test-litmus: ##@tests run litmus tests - requires an instance with basic auth credential strategy
	docker run -e LITMUS_URL="http://ocdavsvc:9998/remote.php/webdav/" -e LITMUS_USERNAME=aaliyah_abernathy -e LITMUS_PASSWORD=secret --network=nexus_ocis -v "$(pwd)"/litmus:/root owncloud/litmus

.PHONY: clean
clean: clean-containers clean-src ##@cleanup Cleanup sources and containers

.PHONY: clean-containers
clean-containers: ##@cleanup Stop and cleanup containers
	CURRENT_UID=$(CURRENT_UID) docker-compose -f deploy/storage/eos.yml -f deploy/core.yml rm -s

.PHONY: clean
clean-src: ##@cleanup Cleanup sources
	rm -rf build/reva/src
	rm -rf build/phoenix/src