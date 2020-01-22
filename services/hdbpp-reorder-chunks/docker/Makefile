NAME=hdbpp-reorder-chunks

default: image

build-files/.built: Dockerfile
	mkdir -p build-files
	cp ../requirements.txt build-files
	cp -rf ../setup build-files/
	cp ../hdbpp_reorder_chunks.py build-files/
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