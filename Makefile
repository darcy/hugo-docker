# which docker machine
DOCKER_MACHINE := dev
# localhost url name so we don't have to type the IP
# (add /etc/hosts entry for this which points to localhost)

# If the first argument is "rake"...
ifeq (rake,$(firstword $(MAKECMDGOALS)))
  # use the rest as arguments for "rake"
  RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  # ...and turn them into do-nothing targets
  $(eval $(RUN_ARGS):;@:)
endif

# for OS specific cheks
ifeq ($(OS),Windows_NT)
	OSFLAG := Windows
else
	UNAME_S := $(shell uname -s)

	ifeq ($(UNAME_S),Darwin)
		OSFLAG := Darwin
	endif

	ifeq ($(UNAME_S),Linux)
		OSFLAG := Linux
	endif
endif

#
# Pre-checks
#

# make sure docker is installed
DOCKER_EXISTS := $(NOOP)
DOCKER_WHICH := $(shell which docker)
ifeq ($(strip $(DOCKER_WHICH)),)
	DOCKER_EXISTS := @echo "\nERROR:\n docker not found.\n See: https://docs.docker.com/\n" && exit 1
endif

# make sure docker-machine is available, for Macs (and Windows)
DOCKER_MACHINE_EXISTS := $(NOOP)
DOCKER_MACHINE_WHICH := $(shell which docker-machine)
ifneq ($(OSFLAG),Darwin)
	ifeq ($(strip $(DOCKER_MACHINE_WHICH)),)
		DOCKER_MACHINE_EXISTS := @echo "\nERROR:\n docker-machine not found.\n See: https://docs.docker.com/machine/\n" && exit 1
	endif
endif

# make sure docker-compose is available
DOCKER_COMPOSE_EXISTS := $(NOOP)
DOCKER_COMPOSE_WHICH := $(shell which docker-compose)
ifneq ($(OSFLAG),Darwin)
	ifeq ($(strip $(DOCKER_COMPOSE_WHICH)),)
		DOCKER_COMPOSE_EXISTS := @echo "\nERROR:\n docker-compose not found.\n See: https://docs.docker.com/compose/\n" && exit 1
	endif
endif

# make sure docker machine is running
DOCKER_MACHINE_RUNS := $(NOOP)
DOCKER_MACHINE_RUNNING := $(shell docker-machine env $(DOCKER_MACHINE) 2>&1 | grep -o 'not running')
ifneq ($(strip $(DOCKER_MACHINE_RUNNING)),)
	DOCKER_MACHINE_RUNS := docker-machine start $(DOCKER_MACHINE)
endif

DOCKER_MACHINE_ENV = eval "$$(docker-machine env $(DOCKER_MACHINE))";
DOCKER_CMD = $(DOCKER_MACHINE_ENV) docker
DOCKER_COMPOSE_CMD = $(DOCKER_MACHINE_ENV) docker-compose

default:

.PHONY: new build run

init:
	$(DOCKER_EXISTS)
	$(DOCKER_COMPOSE_EXISTS)
	$(DOCKER_MACHINE_EXISTS)
	$(DOCKER_MACHINE_RUNS)

build: init
	$(DOCKER_COMPOSE_CMD) build

new_site: init
	$(DOCKER_COMPOSE_CMD) run --rm app hugo new site . --force

new: init
	$(DOCKER_COMPOSE_CMD) run --rm app hugo new $(page)

run: build
	$(DOCKER_COMPOSE_CMD) up

shutdown: init
	$(DOCKER_COMPOSE_CMD) stop
	docker-machine stop $(DOCKER_MACHINE)

status:
	docker-machine ls
	@echo
	@echo
	@(docker-machine env $(DOCKER_MACHINE) 2>&1 | grep 'not running' && exit 1) || true
	docker-machine ip $(DOCKER_MACHINE)
	@echo
	@echo
	$(DOCKER_COMPOSE_CMD) ps
	@echo
	@echo
	$(DOCKER_CMD) ps -a
	@echo
	@echo

shell: init
	$(DOCKER_COMPOSE_CMD) run --rm app bash
