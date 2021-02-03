#!/bin/bash
export AM_SEARCH_ENABLED=false
sudo usermod -aG docker $USER
git submodule update --init --recursive || exit
git submodule foreach -q --recursive 'git checkout $(git config -f $toplevel/.gitmodules submodule.$name.branch || echo master)' || exit
make create-volumes || exit
sed -i 's/20190227.01.9a3872e0/latest/g' ../src/archivematica/src/MCPClient.Dockerfile
docker-compose up -d --build || exit
make bootstrap || exit
make restart-am-services || exit