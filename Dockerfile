FROM node:latest

RUN npm install -g coffee-script

RUN mkdir /npm
ADD package.json /npm/
WORKDIR /npm

RUN npm install

ADD . /var/www
WORKDIR /var/www

RUN rm -rf /var/www/node_modules
RUN mv /npm/node_modules /var/www/

EXPOSE 3001
ENV DOCKER_HOST unix:///tmp/docker.sock

CMD ["coffee", "app.coffee"]



# Get rid of nginx frontend on mac, just dns proxyboard.dev straight into container which is exposed on port 80

