N = rchain/buildenv
V = $(shell git describe --tags)

TARGETS = - -withdeps

.PHONY: all
all: build

TARGETS_BUILD = $(addprefix build,$(TARGETS))
.PHONY: build $(TARGETS_BUILD)
build: $(TARGETS_BUILD)

$(TARGETS_BUILD): build-%:
	docker build -f Dockerfile$(*:%=.%) -t $(N)$(*:%=-%):$(V) .
	docker tag $(N)$(*:%=-%):$(V) $(N)$(*:%=-%):latest

TARGETS_PUSH = $(addprefix push,$(TARGETS))
.PHONY: push $(TARGETS_PUSH)
push: $(TARGETS_PUSH)

$(TARGETS_PUSH): push-%: build-%
	docker push $(N)$(*:%=-%):$(V)
	docker push $(N)$(*:%=-%):latest
