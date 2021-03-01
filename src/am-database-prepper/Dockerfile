FROM alpine:latest
RUN apk add mysql-client
COPY *.sh ./
RUN ["chmod", "+x", "./*.sh"]