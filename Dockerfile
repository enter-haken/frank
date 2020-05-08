FROM node:12.2.0 as client_builder 

# install chrome for protractor tests
# only for tests

# RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
# RUN sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
# RUN apt-get update && apt-get install -yq google-chrome-stable brotli
RUN apt-get update && apt-get install -yq brotli 

# set working directory
WORKDIR /app

# add `/app/node_modules/.bin` to $PATH
ENV PATH /app/node_modules/.bin:$PATH

RUN npm install -g @angular/cli@9.1.4

# add app

COPY client/ .

RUN make deep_clean build 

# backend builder

FROM elixir:1.9.4 AS backend_builder

WORKDIR /app

COPY . .

COPY --from=client_builder /app/dist client/dist

RUN mix local.hex --force
RUN mix local.rebar --force

RUN make release

# backend runner 

FROM elixir:1.9.4-slim AS runner

RUN apt-get update && \
      apt-get install -y git \
      && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=backend_builder /app/_build/prod/rel/frank .

EXPOSE 4040

CMD ["bin/frank", "start"]

