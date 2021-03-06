APP_NAME = ups-config-operator

PKG     = github.com/aerogear/$(APP_NAME)
TOP_SRC_DIRS   = pkg
PACKAGES     ?= $(shell sh -c "find $(TOP_SRC_DIRS) -name \\*_test.go \
                   -exec dirname {} \\; | sort | uniq")

DOCKER_LATEST_TAG = docker.io/aerogear/$(APP_NAME):latest
DOCKER_MASTER_TAG = docker.io/aerogear/$(APP_NAME):master
RELEASE_TAG ?= $(CIRCLE_TAG)
DOCKER_RELEASE_TAG = aerogear/$(APP_NAME):$(RELEASE_TAG)

.PHONY: generate
generate:
	./scripts/generate.sh

.PHONY: setup
setup:
	glide install
	mockery -all -inpkg -dir pkg

.PHONY: test
test:
	@echo Running tests:
	mockery -all -inpkg -dir pkg
	GOCACHE=off go test -cover \
	  $(addprefix $(PKG)/,$(PACKAGES))

.PHONY: build_linux
build_linux:
	mockery -all -inpkg -dir pkg
	env GOOS=linux GOARCH=amd64 go build cmd/server/main.go

.PHONY: docker_build
docker_build: build_linux
	docker build -t $(DOCKER_LATEST_TAG) -f Dockerfile .

.PHONY: docker_build_release
docker_build_release: build_linux
	docker build -t $(DOCKER_LATEST_TAG) -t $(DOCKER_RELEASE_TAG) -f Dockerfile .

.PHONY: docker_build_master
docker_build_master:
	docker build -t $(DOCKER_MASTER_TAG) -f Dockerfile .

.PHONY: docker_push_latest
docker_push_latest:
	@docker login -u $(DOCKERHUB_USERNAME) -p $(DOCKERHUB_PASSWORD)
	docker push $(DOCKER_LATEST_TAG)

.PHONY: docker_push_master
docker_push_master:
	@docker login -u $(DOCKERHUB_USERNAME) -p $(DOCKERHUB_PASSWORD)
	docker push $(DOCKER_MASTER_TAG)

.PHONY: docker_push_release
docker_push_release:
	@docker login --username $(DOCKERHUB_USERNAME) --password $(DOCKERHUB_PASSWORD)
	docker push $(DOCKER_LATEST_TAG)
	docker push $(DOCKER_RELEASE_TAG)
