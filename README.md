# Frank

This is `Frank`, yet an other git frontend.
See [frank.hake.one][1] as an example.
This is still a little bit buggy.

## build requirements

If you want to build `Frank` on your machine, you need to install some packages.

### mandatory

I recommend to use [asdf][2] for installing `erlang` and `elixir`.

At the time of writing:

* ~> Erlang/OTP 22
* ~> elixir 1.9.2
* ~> git 2.17.1
* ~> node 12.2.0
* ~> @angular/cli 8.0.3

### optional

* ~> Docker 19.03.5

## build

`Frank` itself is a monorepo, where the client and the backend lives.

### build the client

When you want to build the client you can do a

```bash
$ make
```

within the `./client` folder.

This will create a `production build` of the client and puts it into the `dist` folder of the client.
The `node modules` will be created if it is missing.

```bash
$ make clean
```

will remove the `dist` folder.

```bash
$ make deep_clean
```

will remove the `node_modules` folder as well.

### build the backend

```bash
$ make
```

will install all necessary dependencies via `mix deps.get` and build the `client` if it is missing.

```bash
$ make clean
```

will remove the `./_build` folder.

```bash
$ make clean_deps
```

will remove the `./deps` folder.

```bash
$ make clean_client 
```

will do a `make deep_clean` on the client.

```bash
$ make deep_clean 
```

will delete all the build artefacts, used by `Frank`.

```bash
$ make release 
```

will do a `mix release` and build `Frank` if neccessary.

### build with Docker

If you don't want to have any dev dependencies on your machine you can build `Frank` with Docker

```bash
$ make docker 
```

This is a multi stage build.

## run 

### on your machine

`Frank` uses environment variables to introduce git repositories.

```bash
$ FRANK_repo_name=/path/to/repo make run 
```

will do a `make build` if necessary and starts the client on port `4040`.

### run with docker

After a `make docker`, you can create a container with

```bash
$ docker run \
> -v /path/to/repo:/repos/repo \
> --env FRANK_repo_name=/repos/repo \
> -p 4040:4040 \
> -t frank
```

After that `Frank` should be up and running on port `4040`.

### run dev version of the client

If you do a `make run` inside the `./client` folder, you start a dev server for client development.
The client is accessible via the port `4200`. 
The backend should be running to use the client.

# contact

Jan Frederik Hake, <jan_hake@gmx.de>. [@enter_haken](https://twitter.com/enter_haken) on Twitter.

[1]: https://frank.hake.one
[2]: https://asdf-vm.com/#/core-manage-asdf-vm
