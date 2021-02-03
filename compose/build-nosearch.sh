export AM_SEARCH_ENABLED=false
git submodule update --init --recursive
git submodule foreach -q --recursive 'git checkout $(git config -f $toplevel/.gitmodules submodule.$name.branch || echo master)'
make create-volumes
sed -i 's/20190227.01.9a3872e0/latest/g' ../src/archivematica/src/MCPClient.Dockerfile
docker-compose -f docker-compose-nosearch.yml up -d --build
make bootstrap
make restart-am-services
