FROM alpine:3.11

ARG VERSION

ENV GROUP alpine
ENV USER alpine

LABEL "name"="<registry-name>/<image-name>" \
      "maintainer"="<organization-title>" \
      "version"="${VERSION}" \
      "release"="<release>" \
      "vendor"="<organization-title>" \
      "summary"="<short-description>" \
      "description"="<description>."

# Create a user and group first so the IDs get set the same way, even as
# the rest of this may change over time.
RUN addgroup ${GROUP} \
    && adduser -S -G ${GROUP} ${USER}

RUN set -eux \
    && apk add --no-cache ca-certificates curl dumb-init su-exec \
    && /bin/rm -rf /tmp/* /var/tmp/* /var/cache/apk/*

COPY docker-entrypoint.sh /usr/local/bin

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]

CMD [ ]
