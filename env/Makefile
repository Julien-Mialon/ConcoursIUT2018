default:
	@echo "Try make build, make build-nocache or make push."

build:
	docker build -t mpoquet/bashbot:latest \
                 -t mpoquet/bashbot:$$(date --iso-8601) \
                 .

build-nocache:
	docker build -t mpoquet/bashbot:latest \
                 -t mpoquet/bashbot:$$(date --iso-8601) \
                 --no-cache \
                 .

push:
	docker push mpoquet/bashbot
