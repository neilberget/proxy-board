FROM ubuntu:12.04

RUN apt-get update

RUN apt-get install -y build-essential
RUN apt-get install -y curl openssl libreadline6 libreadline6-dev curl zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt-dev autoconf libc6-dev ncurses-dev automake libtool bison subversion pkg-config git
RUN apt-get install -y wget
RUN apt-get install -y python-software-properties python-setuptools
RUN DEBIAN_FRONTEND=noninteractive apt-get -q -y install mysql-server

# Supervisor Config
RUN /usr/bin/easy_install supervisor
ADD ./supervisord.conf /etc/supervisord.conf

# Set up Mysql
ADD ./db/proxy_board.sql /proxy_board.sql
ADD ./db/mysql-setup.sh /mysql-setup.sh
RUN /bin/bash -l -c "/mysql-setup.sh"

# Install node
ADD ./setup_node.sh /setup_node.sh
RUN /setup_node.sh

ADD . /var/www
WORKDIR /var/www

RUN mkdir -p /var/log/supervisor

RUN /bin/bash -l -c "npm install"

EXPOSE 3001 3002

##ENTRYPOINT ["./proxy.sh"]
CMD ["./start_supervisor.sh"]
