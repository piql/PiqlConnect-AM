FROM alpine:latest
RUN apk add mysql-client
COPY *.sh ./
RUN ["chmod", "+x", "./mcp-prep.sh"]
RUN ["chmod", "+x", "./ss-prep.sh"]