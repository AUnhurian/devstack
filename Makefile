SHELL := /bin/bash
CURDIR := $(shell pwd)
include $(CURDIR)/.env

PROJECT_DIR_PATH := $(PROJECT_DIR_PATH)
PROJECT_DIR := $(PROJECT_DIR)
PROJECT_REPOSITORY_URL := $(PROJECT_REPOSITORY_URL)

test:
	echo $(HOSTNAME);

setup:
	make create-project

create-project:
	set -ex;\
    	if [ ! -d ${PROJECT_DIR_PATH} ]; then \
    		echo "Missing ${PROJECT_DIR}. Creating...";\
    		cd ..; \
    		git clone ${PROJECT_REPOSITORY_URL} ${PROJECT_DIR};\
    		cd $(CURDIR); \
    	fi;\

	cd ./${PROJECT_DIR_PATH};\
	set +ex;

start-d:
	make prepare-nginx
	@(cp ./${PROJECT_DIR_PATH}/.env.example.dist ./${PROJECT_DIR_PATH}/.env || true)
	@docker-compose build app
	@docker-compose up -d
	@docker-compose exec app composer install
	@echo "Wait on setup database" && sleep 10
	@docker-compose exec app php artisan migrate
	@docker-compose exec app php artisan db:seed --class=DatabaseSeeder

stop:
	docker-compose down

bash:
	docker exec -ti "$(DOCKER_PREFIX)-app" bash

update:
	docker-compose build app
	@docker-compose up -d

restart:
	make stop
	@make start-d

quick-restart:
	make stop
	@(cp ./${PROJECT_DIR_PATH}/.env.example.dist ./${PROJECT_DIR_PATH}/.env || true)
	@docker-compose build app
	@docker-compose up -d

destroy:
	make stop
	@docker rm $(docker ps -a -q)
	@docker rmi $(docker images -q)

prepare-nginx:
	cp ./nginx/conf.d/app.stub ./nginx/conf.d/app.conf
	@sed -i "" "s/{PROJECT_NAME}/${PROJECT_DIR}/g" ./nginx/conf.d/app.conf