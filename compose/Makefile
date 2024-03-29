.DEFAULT_GOAL := help

# Paths for Docker named volumes
AM_PIPELINE_DATA ?= $(HOME)/src/piql-archivematica-compose/.am/am-pipeline-data
SS_LOCATION_DATA ?= $(HOME)/src/piql-archivematica-compose/.am/ss-location-data


define compose_amauat
	docker-compose -f docker-compose.yml -f docker-compose.acceptance-tests.yml $(1)
endef


create-volumes:  ## Create external data volumes.
	mkdir -p ${AM_PIPELINE_DATA}
	docker volume create \
		--opt type=none \
		--opt o=bind \
		--opt device=$(AM_PIPELINE_DATA) \
			am-pipeline-data
	mkdir -p ${SS_LOCATION_DATA}
	docker volume create \
		--opt type=none \
		--opt o=bind \
		--opt device=$(SS_LOCATION_DATA) \
			ss-location-data

bootstrap: bootstrap-storage-service bootstrap-dashboard-db bootstrap-dashboard-frontend  ## Full bootstrap.

bootstrap-storage-service:  ## Boostrap Storage Service (new database).
	docker-compose exec mysql mysql -harchivematica-mysql.mysql.database.azure.com -upiqlconnect@archivematica-mysql -pServersAreKewl! -e "\
		DROP DATABASE IF EXISTS SS; \
		CREATE DATABASE SS;"
	docker-compose run \
		--rm \
		--entrypoint /src/storage_service/manage.py \
			archivematica-storage-service \
				migrate --noinput
	docker-compose run \
		--rm \
		--entrypoint /src/storage_service/manage.py \
			archivematica-storage-service \
				create_user \
					--username="test" \
					--password="test" \
					--email="test@test.com" \
					--api-key="test" \
					--superuser
	# SS needs to be restarted so the local space is created.
	# See #303 (https://git.io/vNKlM) for more details.
	docker-compose restart archivematica-storage-service

makemigrations-ss:
	docker-compose run \
		--rm \
		--entrypoint /src/storage_service/manage.py \
			archivematica-storage-service \
				makemigrations

manage-dashboard:  ## Run Django /manage.py on Dashbaord, suppling <command> [options] as value to ARG, e.g., `make manage-ss ARG=shell`
	docker-compose run \
		--rm \
		--entrypoint /src/dashboard/src/manage.py \
			archivematica-dashboard \
				$(ARG)

manage-ss:  ## Run Django /manage.py on Storage Service, suppling <command> [options] as value to ARG, e.g., `make manage-ss ARG='shell --help'`
	docker-compose run \
		--rm \
		--entrypoint /src/storage_service/manage.py \
			archivematica-storage-service \
				$(ARG)

bootstrap-dashboard-db:  ## Bootstrap Dashboard (new database).
	docker-compose exec mysql mysql -harchivematica-mysql.mysql.database.azure.com -upiqlconnect@archivematica-mysql -pServersAreKewl! -e "\
		DROP DATABASE IF EXISTS MCP; \
		CREATE DATABASE MCP;"
	docker-compose run \
		--rm \
		--entrypoint /src/dashboard/src/manage.py \
			archivematica-dashboard \
				migrate --noinput
	docker-compose run \
		--rm \
		--entrypoint /src/dashboard/src/manage.py \
			archivematica-dashboard \
				install \
					--username="test" \
					--password="test" \
					--email="test@test.com" \
					--org-name="test" \
					--org-id="test" \
					--api-key="test" \
					--ss-url="http://archivematica-storage-service:8000" \
					--ss-user="test" \
					--ss-api-key="test" \
					--site-url="http://archivematica-dashboard:8000"

bootstrap-dashboard-frontend:  ## Build front-end assets.
	docker-compose run --rm --no-deps \
		--user root \
		--entrypoint npm \
		--workdir /src/dashboard/frontend \
			archivematica-dashboard \
				install --unsafe-perm

restart-am-services:  ## Restart Archivematica services: MCPServer, MCPClient, Dashboard and Storage Service.
	docker-compose restart archivematica-mcp-server
	docker-compose restart archivematica-mcp-client
	docker-compose restart archivematica-dashboard
	docker-compose restart archivematica-storage-service

db:  ## Connect to the MySQL server using the CLI.
	docker-compose exec mysql mysql -hlocalhost -uroot -p12345

flush: flush-shared-dir flush-search bootstrap restart-am-services  ## Delete ALL user data.

flush-shared-dir-mcp-configs:  ## Delete processing configurations - it restarts MCPServer.
	rm -f ${AM_PIPELINE_DATA}/sharedMicroServiceTasksConfigs/processingMCPConfigs/defaultProcessingMCP.xml
	rm -f ${AM_PIPELINE_DATA}/sharedMicroServiceTasksConfigs/processingMCPConfigs/automatedProcessingMCP.xml
	docker-compose restart archivematica-mcp-server

flush-shared-dir:  ## Delete contents of the shared directory data volume.
	rm -rf ${AM_PIPELINE_DATA}/*

flush-search:  ## Delete Elasticsearch indices.
	docker-compose exec archivematica-mcp-client curl -XDELETE "http://elasticsearch:9200/aips,aipfiles,transfers,transferfiles"

flush-logs:  ## Delete container logs - requires root privileges.
	@./helpers/flush-docker-logs.sh

flush-test-dbs:
	docker-compose exec mysql mysql -hlocalhost -uroot -p12345 -e "DROP DATABASE IF EXISTS test_MCP; DROP DATABASE IF EXISTS test_SS;"

test-all: test-mcp-server test-mcp-client test-dashboard test-storage-service  ## Run all tests.

test-mcp-server:  ## Run MCPServer tests.
	docker-compose run --workdir /src/MCPServer --rm --entrypoint=py.test archivematica-mcp-server -p no:cacheprovider --reuse-db -v

test-mcp-client:  ## Run MCPClient tests.
	docker-compose run --workdir /src/MCPClient --rm --entrypoint=py.test archivematica-mcp-client -p no:cacheprovider --reuse-db -v

test-dashboard:  ## Run Dashboard tests.
	docker-compose run --workdir /src/dashboard --rm --entrypoint=py.test archivematica-dashboard -p no:cacheprovider --reuse-db -v

test-storage-service:  ## Run Storage Service tests.
	docker-compose run --workdir /src --rm --no-deps --entrypoint py.test -e "DJANGO_SETTINGS_MODULE=storage_service.settings.test" archivematica-storage-service -p no:cacheprovider --reuse-db -v

test-at-build:  ## AMAUAT: build image.
	$(call compose_amauat, \
		build archivematica-acceptance-tests)

test-at-check: test-at-build  ## AMAUAT: test browsers.
	$(call compose_amauat, \
		run --rm --no-deps archivematica-acceptance-tests /home/archivematica/acceptance-tests/simplebrowsertest.py)

TAGS ?= mo-aip-reingest
BROWSER ?= Firefox
test-at-behave: test-at-build  ## AMAUAT: run behave, default is `make test-at-behave TAGS=mo-aip-reingest BROWSER=Firefox`.
	$(call compose_amauat, \
		run --rm -e HEADLESS=1 --no-deps archivematica-acceptance-tests /usr/local/bin/behave \
			--tags=$(TAGS) --no-skipped -v --stop \
			-D driver_name=$(BROWSER) \
			-D ssh_accessible=no \
			-D am_url=http://nginx/ \
			-D am_username=test \
			-D am_password=test \
			-D am_api_key=test \
			-D am_version=1.8 \
			-D ss_url=http://nginx:8000/ \
			-D ss_username=test \
			-D ss_password=test \
			-D ss_api_key=test \
			-D transfer_source_path=archivematica/archivematica-sampledata/TestTransfers/acceptance-tests \
			-D home=archivematica)

test-frontend: bootstrap-dashboard-frontend  ## Run Dashboard JS tests.
	docker-compose run --rm --no-deps --user root --entrypoint npm --workdir /src/dashboard/frontend archivematica-dashboard run "test-single-run"

help:  ## Print this help message.
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
