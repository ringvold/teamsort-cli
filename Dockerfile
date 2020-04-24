FROM registry.gitlab.com/minizinc/minizinc-python

RUN curl -sL https://deb.nodesource.com/setup_12.x | bash -
RUN apt update && apt install -y nodejs

COPY ./cli/package.json teamsort/
COPY ./cli/elm.json teamsort/
COPY ./cli/src teamsort/src
COPY ./cli/tests teamsort/tests

WORKDIR teamsort

RUN npm install

RUN npm run build:elm && npm run build:ts && npm run build:copy

VOLUME /input

ENTRYPOINT ["build/teamsort.js", "sort"]
