FROM elixir:latest

RUN mkdir /opt/minizinc && \
    wget --quiet https://github.com/MiniZinc/MiniZincIDE/releases/download/2.5.3/MiniZincIDE-2.5.3-bundle-linux-x86_64.tgz && \
    tar -xf MiniZincIDE-2.5.3-bundle-linux-x86_64.tgz  -C /opt/minizinc/

ENV PATH=/opt/minizinc/MiniZincIDE-2.5.3-bundle-linux-x86_64/bin:$PATH

RUN curl -sL https://deb.nodesource.com/setup_14.x | bash - && \
    apt-get install -y postgresql-client && \
    apt-get install -y inotify-tools && \
    apt-get install -y nodejs

ENV APP_HOME=/opt/app SHELL=/bin/bash
RUN mkdir $APP_HOME
WORKDIR $APP_HOME


RUN useradd -rm -d /home/ubuntu -s /bin/bash -u 1001 ubuntu
USER ubuntu

RUN mix local.hex --force && \
    mix archive.install hex phx_new 1.5.3 --force && \
    mix local.rebar --force

CMD ["mix", "phx.server"]
