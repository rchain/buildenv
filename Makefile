N = rchain/buildenv
C = $(or $(DRONE_COMMIT_SHA),$(shell git rev-parse --short HEAD))
V = $(shell git describe --tags)

.PHONY: all build-all push-all
all: build
build-all: build build-java8
push-all: push push-java8

.PHONY: build
build:
	docker build -t $(N):$(C) .
	docker tag $(N):$(C) $(N):$(V)
	docker tag $(N):$(C) $(N):latest

.PHONY: build-java8
build-java8:
	docker build -f Dockerfile.java8 -t $(N):$(C)-java8 .
	docker tag $(N):$(C)-java8 $(N):$(V)-java8
	docker tag $(N):$(C)-java8 $(N):latest-java8

.PHONY: login
login:
	echo $$DOCKER_PASSWORD | docker login -u $$DOCKER_USERNAME --password-stdin

.PHONY: push
push: login
	docker push $(N):$(V)
	docker push $(N):latest

.PHONY: push-java8
push-java8: login
	docker push $(N):$(V)-java8
	docker push $(N):latest-java8
