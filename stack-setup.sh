#!/bin/bash

if [ "$STACK" == "1" ]; then
  docker swarm init
  docker-compose down
  docker stack deploy -c docker-compose.stack.yml default
fi
