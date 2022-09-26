default: build

build:
	docker compose build --build-arg=USER_ID=$(shell id -u)
