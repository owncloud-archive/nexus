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
	docker-compose build ocdavsvc
	docker-compose build authsvc
	docker-compose build storageprovidersvc

reva-src: build/reva/src ##@reva Get reva sources
build/reva/src:
	git clone git@github.com:owncloud/reva.git build/reva/src 
	cd build/reva/src; \
	git checkout nexus; \
	git remote add upstream git@github.com:cernbox/reva.git

.PHONY: phoenix-container
phoenix-container: phoenix-src ##@phoenix Build a docker container for phoenix, the web frontend
	docker-compose build phoenix

phoenix-src: build/phoenix/src ##@phoenix Get phoenix sources
build/phoenix/src:
	git clone git@github.com:owncloud/phoenix.git build/phoenix/src

.PHONY: up
up: reva-container phoenix-container ##@containers docker-compose up all containers
	CURRENT_UID=$(CURRENT_UID) docker-compose up

.PHONY: down
down: ##@containers docker-compose down all containers
	CURRENT_UID=$(CURRENT_UID) docker-compose down


.PHONY: litmus
test-litmus: ##@tests run litmus tests - requires an instance with basic auth credential strategy
	docker run -e LITMUS_URL="http://ocdavsvc:9998/remote.php/webdav/" -e LITMUS_USERNAME=aaliyah_abernathy -e LITMUS_PASSWORD=secret --network=nexus_ocis -v "$(pwd)"/litmus:/root owncloud/litmus

.PHONY: clean
clean: clean-containers clean-src ##@cleanup Cleanup sources and containers

.PHONY: clean-containers
clean-containers: ##@cleanup Stop and cleanup containers
	CURRENT_UID=$(CURRENT_UID) docker-compose rm -s

.PHONY: clean
clean-src: ##@cleanup Cleanup sources
	rm -rf build/reva/src
	rm -rf build/phoenix/src
