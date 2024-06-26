NAME        = overstory-service
IMAGE       = overstory-service
TAG         ?= latest
K8S_VERSION = "1.29"
MINIKUBE_MB = 3092

build-image: delete-image
	docker build \
		--rm \
		-t ghcr.io/phenomenes/$(IMAGE):$(TAG) .

push-image:
	docker push ghcr.io/phenomenes/$(IMAGE):$(TAG)

delete-image:
	-docker rmi -f ghcr.io/phenomenes/$(IMAGE)/$(TAG) >/dev/null 2>&1

run-image:
	docker run --rm -it -p 8888:8888 ghcr.io/phenomenes/$(IMAGE):$(TAG)

build-chart: lint-chart
	helm package helm/

lint-chart:
	helm lint helm/ --values helm/values.yaml

install-chart:
	helm install $(NAME) helm/

delete-chart:
	-helm del $(IMAGE) >/dev/null 2>&1

minikube: delete-minikube
	minikube start \
		--profile=overstory \
		--kubernetes-version="$(K8S_VERSION)" \
	        --cpus=2 \
		--memory=$(MINIKUBE_MB)MB

delete-minikube:
	-minikube delete --profile overstory

deploy: build-image delete-chart install-chart

clean-up: delete-minikube delete-image
