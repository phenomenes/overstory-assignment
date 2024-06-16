NAME        = overstory-service
IMAGE       = overstory-service
TAG         ?= test
K8S_VERSION = "1.29"
MINIKUBE_MB = 3092

build-image: clean-image
	docker build \
		--rm \
		-t ghrc.io/phenomenes/$(IMAGE):$(TAG) .

push-image:
	docker push ghrc.io/phenomenes/$(IMAGE):$(TAG)

clean-image:
	-docker rmi -f $(IMAGE)/$(TAG) >/dev/null 2>&1

run:
	docker run --rm -it -p 8000:8000 ghrc.io/phenomenes/$(IMAGE):$(TAG)

build-chart: lint-chart
	helm package helm/

lint-chart:
	helm lint helm/ --values helm/values.yaml

install-chart:
	helm install $(NAME) helm/

delete-chart:
	-helm del $(IMAGE) >/dev/null 2>&1

minikube:
	minikube delete || true
	minikube start \
		--kubernetes-version="$(K8S_VERSION)" \
	        --cpus=2 \
		--memory=$(MINIKUBE_MB)MB

deploy: build-image delete-chart install-chart
