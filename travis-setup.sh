#!/bin/bash

if [ "$STACK" == "1" ]; then
  docker swarm init
  docker build -t frappe .
  docker stack deploy -c docker-compose.stack.yml default
else
  ./dbench setup docker
fi
