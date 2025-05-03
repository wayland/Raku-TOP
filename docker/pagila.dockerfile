#FROM rakuland/raku:latest
FROM postgres:17 AS pagila-builder
LABEL maintainer="Tim Nelson <wayland@wayland.id.au>"

RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/devrimgunduz/pagila.git /usr/src/pagila

# New Name
RUN mv /usr/src/pagila/pagila-schema.sql /docker-entrypoint-initdb.d/1-pagila-schema.sql
RUN mv /usr/src/pagila/pagila-schema-jsonb.sql /docker-entrypoint-initdb.d/1-pagila-schema-jsonb.sql
RUN mv /usr/src/pagila/pagila-data.sql /docker-entrypoint-initdb.d/2-pagila-data.sql
#RUN mv /usr/src/pagila/restore-pagila-data-jsonb.sh /docker-entrypoint-initdb.d/3-restore-pagila-data-jsonb.sh
# Same Name
#RUN mv /usr/src/pagila/pagila-data-yum-jsonb.backup /docker-entrypoint-initdb.d/pagila-data-yum-jsonb.backup
#RUN mv /usr/src/pagila/pagila-data-apt-jsonb.backup /docker-entrypoint-initdb.d/pagila-data-apt-jsonb.backup

FROM postgres:17 AS pagila

COPY --from=pagila-builder /docker-entrypoint-initdb.d/ /docker-entrypoint-initdb.d/
