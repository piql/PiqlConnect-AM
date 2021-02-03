#!/bin/bash
export AM_SEARCH_ENABLED=false
docker-compose -f docker-compose-nosearch.yml up -d
