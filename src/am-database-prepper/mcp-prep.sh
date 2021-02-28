#!/bin/sh
mysql -hmysql -upiqlconnect@archivematica-mysql -pServersAreKewl! -e "\
	DROP DATABASE IF EXISTS MCP; \
	CREATE DATABASE MCP; \
    CREATE USER 'archivematica'@'%' IDENTIFIED BY 'demo'; \
	GRANT ALL ON MCP.* TO 'archivematica'@'%';"