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
RUN ls -laF /home
#RUN addgroup -S raku && adduser -S raku -G raku -u 1001
RUN usermod -u 1001 raku && chown raku:raku /home/raku
RUN rm -rf /tmp/.zef && mkdir -p /tmp/.zef && chown raku:raku /tmp/.zef
USER raku
WORKDIR /home/raku

##### Install public raku packages
RUN \
	zef install -v \
		CSV::Parser \
		Database::Driver::Postgres Slang::Otherwise \
		'Hash::Ordered:ver<0.0.8>' 'Hash::Agnostic:ver<0.0.16>' \
		'UUID' 'Text::CSV' 'IO::Glob' \
	&& rm -rf /tmp/.zef

##### Install private raku packages
ENV LIBDIR=/home/raku/lib/raku
RUN mkdir -p $LIBDIR
#COPY Slang/DataFlow.rakumod $LIBDIR/Slang/DataFlow.rakumod
COPY lib/raku $LIBDIR/

COPY data data
COPY testing/tests/* ./
COPY testing/docker/pgpass .pgpass
#RUN ls -laF ./
#RUN chmod a+x *.rakutest

ENTRYPOINT tail -f /dev/null
