NAME=hdbpp-cluster-reporting

default: image

build-files/.built: Dockerfile
	mkdir -p build-files/app
	cp ../requirements.txt build-files
	cp -rf ../setup build-files/
	cp -rf ../server build-files/app
	cp ../run_server.py build-files/app
	docker build -t ${NAME} .
	touch build-files/.built

lint:
	docker run --rm -i hadolint/hadolint < Dockerfile

image: build-files/.built

push: build-files/.built
# User must set this environment variable if they want to push the image to a docker repo
ifndef DOCKER_REGISTRY
	$(error DOCKER_REGISTRY is not set)
endif

	docker tag ${NAME}:latest ${DOCKER_REGISTRY}/${NAME}
	docker push ${DOCKER_REGISTRY}/${NAME}

clean:
	rm -rf build-files

.PHONY: default image clean