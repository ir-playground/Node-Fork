FROM docker.io/library/node:alpine3.21

RUN mkdir /app

COPY . /app
WORKDIR /app

RUN NODE_OPTIONS=--openssl-legacy-provider yarn workspace web build

RUN ls /app/packages/web/build/

FROM docker.io/library/nginx:1.19.2
ARG TAG

ENV APP_VERSION=${TAG}

COPY --from=0 /app/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=0 /app/packages/web/build /usr/share/nginx/html/
COPY --from=0 /app/init-with-config.sh /init-with-config.sh
RUN chmod 766 /init-with-config.sh
RUN ls /usr/share/nginx/html/

CMD ["/init-with-config.sh"]
