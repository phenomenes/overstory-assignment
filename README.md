# Overstory assignment

## Requirements

* Python 3
* Docker >= 26.1
* Kubernetes >= 1.29
* minikube >= 1.33
* helm >= 3.15

## Running the service locally

Install dependencies

```shell
pip install -r requirements.txt
```

Start the flask app

```shell
python app.py
```

The service listens on port 5000 by default, you can use `curl` to get an inference:

```shell
curl -X POST "http://0.0.0.0:5000/inference" -F "file=@./data/test-1.tif" --output 'output.npy'
```

Validate the response

```shell
python3 -c "import numpy; print(isinstance(numpy.load('output.npy'), numpy.ndarray))"
```

## Deploying to Kubernetes (minikube)

Please note that minikube requires at least 3GB of memory.

Start minikube

```shell
make minikube
```

Deploy the helm chart

```shell
make deploy
```
This target will install a helm chart that will create a `Deployment`, and a Service of type `LoadBalancer`.

To be able to access the service we need to start a tunnel on a separate terminal

```shell
minikube tunnel --profile overstory
```

To obtain the ip address and port, get the Kubernetes services

```shell
$ kubectl get svc

NAME                TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
kubernetes          ClusterIP      10.96.0.1       <none>        443/TCP          8m59s
overstory-service   LoadBalancer   10.101.189.44   $IPADDR       $PORT:31980/TCP   6m4s
```

Take note of `$IPADDR` and `$PORT`

Now we can curl the web app using the above address and port and verify the result as above

```shell
curl -X POST "http://127.0.0.1:8888/inference" -F "file=@./data/test-1.tif" --output 'output.npy'

python3 -c "import numpy;print(type(numpy.load('output.npy')))"
```

## Design considerations

Some changes were made to the original code for better performance and readability:

* The trained model is loaded globally to avoid reloading it on each request, enhancing performance.
* The U-Net library was moved to its own file for better readability and maintainability.
* Flask was used for simplicity and ease of development.
* Used minikube with minimum requirements. Since I'm constrained to the local environment, I had to create a tunnel to access the service.
* The current Docker image is quite large (~3GB) due to the inclusion of GDAL. Explore alternatives to reduce image size when moving to production:
    * Pre-compile GDAL and copy the necessary .so files into the image.
    * Use a repository to store and retrieve pre-compiled GDAL binary
_(FIXME: these are assumptions, verify docker image)_

### Running on production

To run this application in a production environment, several modifications and enhancements are necessary.

#### Architecture enhancements

To handle increased traffic and ensure high availability, we should consider making improvements to the architecture:

* Load Balancing: Introduce load balancers to distribute incoming traffic across multiple instances of the web app to ensure even load distribution and high availability.

* nginx: Introduce nginx as a reverse proxy to handle incoming requests and provide features such as load balancing, caching, and SSL termination

* Horizontal Pod Autoscaler (HPA): Dynamically adjust the number of running pods based on CPU and memory usage to handle varying traffic loads.  By scaling up during peak times and scaling down during low traffic periods, HPA helps in maintaining optimal resource utilization and cost efficiency.

* Cluster Autoscaler, Node Auto-Provisioner (NAP) or Karpenter: Automatically adjust the size of the Kubernetes cluster based on resource utilization, adding or removing nodes as necessary.

* Multi Availability Zone cluster: Deploy the Kubernetes cluster in multiple availability zones to increase the availability.

* GPUs: Utilize GPUs for running the prediction/inference to improve the performance.

#### Infrastructure as Code (IaC)

To ensure reproducibility and facilitate collaboration among multiple team members, it's essential to build the proposed architecture using Infrastructure as Code (IaC) tools like Terraform. By defining infrastructure in code, we can version control the infrastructure setup, making it easier to manage and track changes over time.

#### CI/CD Pipeline

Establish a CI pipeline to maintain code quality and ensure reliability of both the source code and infrastructure by running tests:

* Unit Testing:
    * Mocking the web app and test each endpoint.
    * Unit testing the utility functions.

* Linting
    * Lint Helm charts to ensure they follow best practices
    * pylint

* Template Testing
    * Generate Kubernetes templates to verify deployment configurations.

* Integration tests

Automated deployments (CD) triggered by events, such as a version change in code, can be efficiently managed using a GitOps approach

#### Monitoring and Metrics

Proper instrumentation of the web app, and model library are essential for collecting metrics and establishing baselines and ensuring efficient use of resources. This will allow proactive monitoring, quick identification of degradation of service, and capacity planning.

Key metrics to monitor:

* HTTP Request time
* Error rates
* Throughput
* CPU and Memory Usage
* Prediction latency
* Input data size, and output result size
* Prediction accuracy
