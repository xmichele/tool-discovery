#Harvester + Store run in the same container as the store is merely a thin layer on top of the former
FROM proycon/codemeta-harvester

ENV GIT_TERMINAL_PROMPT=0
RUN mkdir -p /var/www/static && cp /usr/lib/python3.*/site-packages/codemeta/resources/* /var/www/static/

#Install webserver and build dependencies
#Install codemeta-server, this also pulls in rdflib-endpoint and uvicorn (for which we need the build dependencies)
#remove build dependencies
RUN apk add nginx ca-certificates runit cronie rsync py3-dotenv apache2-utils gcc libc-dev make python3-dev ; \
pip install codemeta-server flask waitress ; \
apk del gcc libc-dev make python3-dev ; rm -Rf /root/.cache /usr/src
#what build tools are still needed ?

# Patch to set proper mimetype for logs
RUN sed -i 's/txt;/txt log;/' /etc/nginx/mime.types
#nginx level auth
ARG nginx_user='user'
ARG nginx_pass='Gue33mypa33!'
RUN htpasswd -c -b /etc/nginx/.htpasswd $nginx_user $nginx_pass
#copy additional static resources
COPY static/* /var/www/static/

ADD etc /etc
ADD bin /usr/bin/
RUN chmod +x /usr/bin/*.sh
ADD app.py /app.py
RUN chmod +x /app.py

#VOLUME ["/tool-store-data/codemeta.json"]
#EXPOSE nginx port

WORKDIR /
#Runs everything under /etc/service dir: i.e. nginx, cron, codemeta-server and harv/st batch
ENTRYPOINT ["runsvdir","-P","/etc/service"]
