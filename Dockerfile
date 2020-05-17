FROM alpine:3.11

ARG VERSION

LABEL \
    "name"="tooldockers/iops" \
    "maintainer"="tool-dockers" \
    "version"="${VERSION}" \
    "release"="3.16" \
    "vendor"="tool-dockers" \
    "summary"="I/O performance statistics" \
    "description"="Alpine-based Docker containing fio, and ioping, a filesystem benchmarking tool."

# Create a iops user and group first so the IDs get set the same way, even as
# the rest of this may change over time.
RUN addgroup iops \
    && adduser -S -G iops iops

RUN set -eux \
    && apk add --no-cache ca-certificates curl dumb-init su-exec fio ioping \
    && ioping -v \
    && fio -v \
    && /bin/rm -rf /tmp/* /var/tmp/* /var/cache/apk/*

RUN mkdir -p /iops/config \
    && mkdir -p /iops/data \
    && chown -R iops:iops /iops

VOLUME /iops/data

WORKDIR /iops/

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]
CMD [ "--help" ]
