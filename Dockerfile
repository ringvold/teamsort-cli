FROM registry.gitlab.com/minizinc/minizinc-python

RUN curl -sL https://deb.nodesource.com/setup_12.x | bash -
RUN apt update && apt install -y nodejs

COPY ./cli/package.json teamsort/

WORKDIR teamsort

RUN npm install

COPY ./cli/elm.json .
COPY ./cli/src ./src
COPY ./cli/tests ./tests

RUN npm run build:elm && npm run build:ts && npm run build:copy

VOLUME /input

ENTRYPOINT ["build/teamsort"]
