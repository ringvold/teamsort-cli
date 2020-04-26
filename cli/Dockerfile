FROM registry.gitlab.com/minizinc/minizinc-python

RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -
RUN apt update && apt install -y nodejs
RUN npm install -g yarn

RUN mkdir /app
WORKDIR /app

ENTRYPOINT /bin/bash