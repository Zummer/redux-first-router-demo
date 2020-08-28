init: docker-down-clear \
	npm-ready-clear build-clear \
	docker-pull docker-build docker-up \
	node-init
up: docker-up
down: docker-down
restart: down up

node-init: npm-install npm-ready
npm-ready-clear:
	docker run --rm -v ${PWD}:/app -w /app alpine sh -c 'rm -rf .npm-ready'

build-ready:
	docker run --rm -v ${PWD}:/app -w /app alpine touch .build-ready

npm-ready:
	docker run --rm -v ${PWD}:/app -w /app alpine touch .npm-ready

npm-install:
	docker-compose run --rm node-cli npm install

build-clear:
	docker run --rm -v ${PWD}:/app -w /app alpine sh -c 'rm -rf .build-ready dist buildClient buildServer'

lint: 
	docker-compose run --rm node-cli npm run eslint
	docker-compose run --rm node-cli npm run stylelint

lint-fix: 
	docker-compose run --rm node-cli npm run eslint-fix

docker-up:
	docker-compose up -d

docker-down:
	docker-compose down --remove-orphans

docker-down-clear:
	docker-compose down -v --remove-orphans

docker-pull:
	docker-compose pull --include-deps

docker-build:
	docker-compose build

build: build-clear build-prod build-ready build-gateway build-server build-static

build-gateway:
	docker --log-level=debug build --pull --file=gateway/docker/production/nginx/Dockerfile --tag=${REGISTRY}/rfr-gateway:${IMAGE_TAG} .

build-static:
	docker --log-level=debug build --pull --file=static/docker/production/nginx/Dockerfile --tag=${REGISTRY}/rfr-static:${IMAGE_TAG} .

build-server:
	docker --log-level=debug build --pull --file=server/docker/production/Dockerfile --tag=${REGISTRY}/rfr-server:${IMAGE_TAG} .

build-prod:
	docker-compose run --rm node-cli npm run build

try-build:
	REGISTRY=localhost IMAGE_TAG=0 make build

push: push-gateway push-server push-static

push-gateway:
	docker push ${REGISTRY}/rfr-gateway:${IMAGE_TAG}

push-static:
	docker push ${REGISTRY}/rfr-static:${IMAGE_TAG}

push-server:
	docker push ${REGISTRY}/rfr-server:${IMAGE_TAG}

password:
	docker run --rm registry:2 htpasswd -Bbn ${LOGIN} ${PASSWORD} > htpasswd

validate-jenkinsfile:
	curl --user ${USER} -X POST -F "jenkinsfile=<Jenkinsfile" ${HOST}/pipeline-model-converter/validate

deploy:
	ssh ${HOST} -p ${PORT} 'rm -rf site_${BUILD_NUMBER}'
	ssh ${HOST} -p ${PORT} 'mkdir site_${BUILD_NUMBER}'
	scp -P ${PORT} docker-compose-production.yml ${HOST}:site_${BUILD_NUMBER}/docker-compose.yml
	ssh ${HOST} -p ${PORT} 'cd site_${BUILD_NUMBER} && echo "COMPOSE_PROJECT_NAME=site" >> .env'
	ssh ${HOST} -p ${PORT} 'cd site_${BUILD_NUMBER} && echo "REGISTRY=${REGISTRY}" >> .env'
	ssh ${HOST} -p ${PORT} 'cd site_${BUILD_NUMBER} && echo "IMAGE_TAG=${IMAGE_TAG}" >> .env'
	ssh ${HOST} -p ${PORT} 'cd site_${BUILD_NUMBER} && docker-compose pull'
	ssh ${HOST} -p ${PORT} 'cd site_${BUILD_NUMBER} && docker-compose up --build --remove-orphans -d'
	ssh ${HOST} -p ${PORT} 'rm -f site'
	ssh ${HOST} -p ${PORT} 'ln -sr site_${BUILD_NUMBER} site'

rollback:
	ssh ${HOST} -p ${PORT} 'cd site_${BUILD_NUMBER} && docker-compose pull'
	ssh ${HOST} -p ${PORT} 'cd site_${BUILD_NUMBER} && docker-compose up --build --remove-orphans -d'
	ssh ${HOST} -p ${PORT} 'rm -f site'
	ssh ${HOST} -p ${PORT} 'ln -sr site_${BUILD_NUMBER} site'
