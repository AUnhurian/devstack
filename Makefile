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
	@make start-d

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
	@make prepare-env
	@make prepare-supervisord
	@docker-compose build app
	@docker-compose up -d
	@docker-compose exec app composer install
	@echo "Wait on setup database" && sleep 10
	@docker-compose exec app php artisan migrate
	@docker-compose exec app php artisan db:seed --class=DatabaseSeeder
	@docker exec -ti --user root ${PROJECT_DIR}-app service supervisor start
	@docker-compose exec app php artisan queue:restart

quick-start-d:
	make prepare-nginx
	@make prepare-env
	@make prepare-supervisord
	@docker-compose build app
	@docker-compose up -d
	@docker exec -ti --user root ${PROJECT_DIR}-app service supervisor start
	@docker-compose exec app php artisan queue:restart

my-sql:
	docker-compose exec db mysql -u${DB_USERNAME} -p${DB_PASSWORD}

stop:
	docker-compose down

bash:
	docker exec -ti "$(DOCKER_PREFIX)-app" bash

bash-db:
	docker exec -ti "$(DOCKER_PREFIX)-db" bash

update:
	docker-compose build app
	@docker-compose up -d

restart:
	make stop
	@make start-d

quick-restart:
	make stop
	@make quick-start-d

destroy:
	docker stop $(docker ps -a -q)
	@docker rm $(docker ps -a -q)
	@docker rmi $(docker images -q)

prepare-nginx:
	set -ex;\
		if [ ! -f './nginx/conf.d/app.conf' ]; then \
			echo "---> Missing nginx configuration. Creating...";\
			cp ./nginx/conf.d/app.stub ./nginx/conf.d/app.conf; \
		fi;\

	set +ex; \
	if [[ "$OSTYPE" == "darwin"* ]]; then \
      sed -i "" "s/{PROJECT_NAME}/${PROJECT_DIR}/g" ./nginx/conf.d/app.conf; \
	  sed -i "" "s/{HOSTNAME}/${HOSTNAME}/g" ./nginx/conf.d/app.conf; \
    else \
      sed -i -e "s/{PROJECT_NAME}/${PROJECT_DIR}/g" ./nginx/conf.d/app.conf; \
      sed -i -e "s/{HOSTNAME}/${HOSTNAME}/g" ./nginx/conf.d/app.conf; \
    fi

prepare-supervisord:
	set -ex;\
		if [ ! -f './supervisord/laravel.conf' ]; then \
			echo "---> Missing supervisord. Creating...";\
			cp ./supervisord/supervisord.stub ./supervisord/laravel.conf; \
		fi;\

	set +ex; \
	if [[ "$OSTYPE" == "darwin"* ]]; then \
	  sed -i "" "s/{PROJECT_NAME}/${PROJECT_DIR}/g" ./supervisord/laravel.conf; \
    else \
	  sed -i -e "s/{PROJECT_NAME}/${PROJECT_DIR}/g" ./supervisord/laravel.conf; \
    fi

prepare-env:
	set -ex;\
    	if [ ! -f ./${PROJECT_DIR_PATH}/.env ]; then \
			(cp ./${PROJECT_DIR_PATH}/.env.example ./${PROJECT_DIR_PATH}/.env || true) \
    	fi;\
	set +ex;

root:
	docker exec -ti --user root ${PROJECT_DIR}-app ${command};

supervisor-start:
	docker exec -ti --user root ${PROJECT_DIR}-app service supervisor start

supervisor-restart:
	docker exec -ti --user root ${PROJECT_DIR}-app service supervisor restart

supervisor-status:
	docker exec -ti --user root ${PROJECT_DIR}-app service supervisor status
