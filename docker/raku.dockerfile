#FROM rakuland/raku:latest
FROM rakudo-star:alpine
LABEL maintainer="Tim Nelson <wayland@wayland.id.au>"

##### Install general packages
#ENV PKGS="zlib-dev curl"
ENV PKGS="openssl-dev bash shadow libpq"

# Next time, add bash and nano
RUN apk update && apk upgrade && apk add --no-cache $PKGS $PKGS_TMP

#RUN zef install fez

##### Set up raku user
# Apparently it's important for the user to be 1001 for GitHub actions
#RUN addgroup -S raku && adduser -S raku -G raku -u 1001
RUN usermod -u 1001 raku && chown raku:raku /home/raku
RUN rm -rf /tmp/.zef && mkdir -p /tmp/.zef && chown raku:raku /tmp/.zef
USER raku
WORKDIR /home/raku

##### Install private raku packages
ENV LIBDIR=/home/raku/lib/raku
RUN mkdir -p $LIBDIR t
COPY lib/raku $LIBDIR/

COPY META6.json META6.json
COPY resources resources
#COPY t/* t/
COPY xt/* xt/
COPY all-tests all-tests

COPY docker/pgpass .pgpass
COPY docker/bash_login .bash_login

RUN zef install .

ENTRYPOINT tail -f /dev/null
