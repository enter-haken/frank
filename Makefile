NAME := hake/frank
TAG := $$(git log -1 --pretty=%H)
IMG := ${NAME}:${TAG}
LATEST := ${NAME}:latest

.PHONY: default
default: build

.PHONY: check_deps
check_deps:
	if [ ! -d deps ]; then mix deps.get; fi

.PHONY: client
client:
	make -C ./client

.PHONY: build_client_if_missing
build_client_if_missing:
	if [ ! -d ./client/dist/Frank/ ]; then make client; fi;

.PHONY: build
build: check_deps build_client_if_missing 
	#mix book.generate
	mix compile --force --warnings-as-errors

.PHONY: run
run: build
	iex -S mix

.PHONY: clean
clean:
	rm _build/ -rf || true

.PHONY: clean_deps
clean_deps:
	rm deps/ -rf || true

.PHONY: clean_client
clean_client:
	make -C ./client deep_clean

.PHONY: clean_env
clean_env:
	sh -c 'env | grep FRANK_ | awk -F"=" \'{ print $$1}\' | while read line; do unset $$line; done'

.PHONY: deep_clean
deep_clean: clean clean_deps clean_client

.PHONY: test
test: check_deps
	mix test --trace

.PHONY: loc
loc:
	make -C client/ loc
	find lib -type f | while read line; do cat $$line; done | sed '/^\s*$$/d' | wc -l

.PHONY: release
release: build
	MIX_ENV=prod mix release
	#tar cf /tmp/frank.tar _build/prod/rel/*

.PHONY: docker
docker: 
	docker build -t ${IMG} .
	docker tag ${IMG} ${LATEST}

.PHONY: docker_run
docker_run:
	docker run \
		-v /home/gooose/src/other/complete/enter-haken/appointment:/var/opt/frank/appointment \
		-v /home/gooose/src/other/complete/enter-haken/blog:/var/opt/frank/blog \
		-v /home/gooose/src/other/complete/enter-haken/dotfiles:/var/opt/frank/dotfiles \
		-v /home/gooose/src/other/complete/enter-haken/enter-haken.github.io:/var/opt/frank/enter-haken.github.io \
		-v /home/gooose/src/other/complete/enter-haken/hakyll-dot-demo:/var/opt/frank/hakyll-dot-demo \
		-v /home/gooose/src/other/complete/enter-haken/jsonutils:/var/opt/frank/jsonutils \
		-v /home/gooose/src/other/complete/enter-haken/mongoscripts:/var/opt/frank/mongoscripts \
		-v /home/gooose/src/other/complete/enter-haken/mquery:/var/opt/frank/mquery \
		-v /home/gooose/src/other/complete/enter-haken/plotTimeStamps:/var/opt/frank/plotTimeStamps \
		-v /home/gooose/src/other/complete/enter-haken/profanityChatLog:/var/opt/frank/profanityChatLog \
		-v /home/gooose/src/other/complete/enter-haken/rasmus:/var/opt/frank/rasmus \
		-v /home/gooose/src/other/complete/enter-haken/schema:/var/opt/frank/schema \
		-v /home/gooose/src/other/complete/enter-haken/scripts:/var/opt/frank/scripts \
		-v /home/gooose/src/other/complete/enter-haken/frank:/var/opt/frank/frank \
		-v /home/gooose/src/other/complete/enter-haken/retro:/var/opt/frank/retro \
		-v /home/gooose/src/other/complete/enter-haken/book:/var/opt/frank/book \
		-p 5052:4050 \
		--name frank \
		-d \
		-t ${LATEST}

.PHONY: update
update: docker
	docker stop frank 
	docker rm frank 
	make docker_run

.PHONY: ignore
ignore:
	find deps/ > .ignore || true
	find doc/ >> .ignore || true
	find _build/ >> .ignore || true
	find priv/generated/ >> .ignore || true
