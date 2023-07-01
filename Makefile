IMAGE_NAME=xxgt/cfitsio-omp-pack

build:
	docker build --network host -t $(IMAGE_NAME) .

push:
	docker push $(IMAGE_NAME)

run:
	docker run -it --rm --network=host --tmpfs /work -v /:/local \
		-e SOURCE_ROOT=/tmp/a -e TARGET_ROOT=/tmp/b $(IMAGE_NAME) bash

dist:
	docker save $(IMAGE_NAME) | zstdmt | pv | ssh h12 'zstd -d | docker load'

sync:
	rsync -av . --del h12:/tmp/cfitsio4-ompBINTABLEpack
