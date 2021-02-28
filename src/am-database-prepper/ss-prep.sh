#!/bin/sh
mysql -hmysql -upiqlconnect@archivematica-mysql -pServersAreKewl! -e "\
	DROP DATABASE IF EXISTS SS; \
	CREATE DATABASE SS; \
    CREATE USER 'archivematica'@'%' IDENTIFIED BY 'demo'; \
	GRANT ALL ON SS.* TO 'archivematica'@'%';"