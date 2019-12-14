N = rchain/buildenv
C = $(or $(DRONE_COMMIT_SHA),$(shell git rev-parse --short HEAD))
V = $(shell git describe --tags)

.PHONY: all build-all push-all
all: build
build-all: build
push-all: push

.PHONY: build
build:
	docker build -t $(N):$(C) .
	docker tag $(N):$(C) $(N):$(V)
	docker tag $(N):$(C) $(N):latest

.PHONY: login
login:
	echo $$DOCKER_PASSWORD | docker login -u $$DOCKER_USERNAME --password-stdin

.PHONY: push
push: login
	docker push $(N):$(V)
	docker push $(N):latest
