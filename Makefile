VERSION := `cat VERSION` 

CURRENT := frank:${VERSION}
DOCKERHUB_TARGET := enterhaken/frank:${VERSION}
DOCKERHUB_TARGET_LATEST := enterhaken/frank:latest


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
	docker build -t ${CURRENT} .

.PHONY: docker_push
docker_push:
	docker tag $(CURRENT) $(DOCKERHUB_TARGET)
	docker push $(DOCKERHUB_TARGET)
	docker tag $(CURRENT) $(DOCKERHUB_TARGET_LATEST)
	docker push $(DOCKERHUB_TARGET_LATEST)

.PHONY: docker_run
docker_run:
	docker run \
		-v /home/gooose/src/active:/var/opt/frank/ \
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
