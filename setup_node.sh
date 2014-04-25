#!/bin/bash

wget https://raw.github.com/creationix/nvm/master/install.sh
cat install.sh | HOME=/root /bin/bash 
echo '[[ -s /root/.nvm/nvm.sh ]] && . /root/.nvm/nvm.sh' > /etc/profile.d/nvm.sh

. /root/.nvm/nvm.sh

nvm install 0.11
nvm alias default 0.11
npm install -g coffee-script
