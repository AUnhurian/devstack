# Devstack

## Setup Project

1. You should copy `.env.example` in the `.env` file to configure the docker environment.
2. Launch the `make setup` command to create and set up docker containers. (**Important: Please, suspend all other docker containers to avoid port conflicts.**)

## Useful commands

1. `make start-d` - It will rebuild your container settings and set up docker containers.
2. `make quick-start-d` - It will do the same as `make start-d` but without relaunching the composer and migrations.
3. `make restart` - It will stop docker containers and launch `make start-d`.
4. `make bash` - It will open CLI in the docker container with your project.
5. `make command="<your command>" root` - It will launch the command in the docker container with your project as the root user.