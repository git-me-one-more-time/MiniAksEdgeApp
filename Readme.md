# 1. Containerization of the app
The actual application consists of a simple .net 8 webapp with a single endpoint ("/").
When this endpoint is called it returns the following string `"This request was handled by the {closest region to you} edge / cluster."`

{closest region to you} this part will automatically be replaced by the value of the environment variable `REGION` which is definded in the according yaml-file for the kubernetes-deployments. 

```yml 
    env:
    - name: REGION
      value: "eastus"
```

In order to run an app inside a kubernetes cluster the app first needs to be containerized.

For this a `Dockerfile` is used which contains the instruction of the building process of the image.
\
With `docker build -t miniedgeappacr.azurecr.io/minimal_edge_app1:2 .` we actually build the image.\
Then the app needs to be pushed or published on a dedicated repository (for that we used the azure container registry) `docker push miniedgeappacr.azurecr.io/minimal_edge_app1:2`.

Now inside the kubernetes-deployment yml-file the image-key simply refers to this image when deploying containers inside the cluster to run the app.  
```yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: miniedgeapp-deployment

 -----
   spec:
      containers:
      - name: miniedgeapp
        image: miniedgeappacr.azurecr.io/minimal_edge_app1:2
        imagePullPolicy: Always
```

# 2. Cloud / Azure

## Architecture
The whole architecture and therefore the edge is deployed on Microsoft's PaaS Azure.
For this project we have two edges installed. One cluster in WestEurope and one in EastUS.
Those were partly configured and managed by the azure-portal platform and partly via the azure cli.

Global Loadbalancer / global-app-endpoint:
- service: Azure Traffic Manager
- routing option: performance
- routes incomming requests to closests regional cluster
- works via DNS and health checks
- acts as global endpoint
- is connected to the clusters via public static ip addresses
- enpoint: http://miniedgeapp.trafficmanager.net/

Kubernetes Cluster WestEurope:
- deployed via AKS (Azure Kubernetes Service)
- no auto-scaling HPA (Horizontal Pods Autoscaler)
- pulls latest image from the ACR (Azure Container Registry)
- Node Size: (Standard_DS2_v2) => 2 cores, 7 GB memory x 1
- OS: Ubuntu
- enpoint: http://miniedgeapp.westeurope.cloudapp.azure.com/
- deployment and service files are in aks-westeurope/


Kubernetes Cluster EastUS:
- deployed via AKS (Azure Kubernetes Service)
- does autoscale HPA (Horizontal Pods Autoscaler)
- pulls latest image from the ACR (Azure Container Registry)
- Node Size: (Standard_DS2_v2) => 2 cores, 7 GB memory x 1
- OS: Ubuntu
- enpoint: http://miniedgeapp.easteurope.cloudapp.azure.com/
- deployment and service files are in aks-eastus/


## Demonstration of the cloude infrastructure

```bash
# listing clusters
kubectl config get-contexts

# swtich to west europe cluster
kubectl config use-context WestEuropeCluster

# list deployments, nodes, pods and services
kubectl get deployments
kubectl get nodes
kubectl get svc 

# same goes for the eastus cluster
kubectl config use-context EastUSCluster
```

# 3. Demonstration

The following scenarios should demonstarte the benefits of Edge Computing in general as well as using Kubernetes specific for this.


Demo scripts are located in the `demp-script` directory. 

## 3.1 Global endpoint (traffic manager, automatic request routing to the edge)
Request sent to the global enpoint are routed to the closest regional cluster of the location of the incomming request. 
This demonstrates that endusers don't need to care about the edge as the best edge is automatically accessed by the single global endpoint.

Demo: `curl miniedgeapp.trafficmanager.net`

Expected output: "This request was handled by the {closest region to you} edge / cluster."


## 3.2 The advantage of the edge(regional endpoints are faster)
To demonstrate that having multiple regional endpoints results in better latencies for the enduser than having only one single kubernetes cluster which is accessed by all endusers all over the world. 

Run `./benchmark-endpoint.sh` which benchmarks the request response time to the global endpoint (which routes to the closest regional enpoint) against the EAST US region endpoint.

As we can see having regional edges distributed across multiple regions results in overall better latencies as having only a sinlge centraliced server.\
Due to the decentraliced nature of Edge Computing, it's easily possible to apply regional adjustments to each node on the edge while still having the same app (image) deployed. 

## 3.3 Kubernetes and the advantage of scaling

The following section demonstrates the scaling aspect of kubernetes from which edge computing benefits. 

Measuring avg response time of endpoint / cluster in stressed (without auto-scaling):

1) run `k6 run -e ENDPOINT=<endpoint url> loadtest.js`

Measuring avg response time of endpoint / cluster in stressed and non-stressed mode (with auto-scaling): 

``` bash
# 1) scales pods from 2 to 10 when 50% of the cpu gets utilized
kubectl autoscale deployment miniedgeapp-deployment --cpu-percent=50 --min=2 --max=10

# 2) check if (horizontal pod) auto-scalling is enabled
kubectl get hpa

# 3) check how many pods are instantiated
kubectl get pods 

# 4) run load/stress test again (check on request duration and percentage of failed requests)
`k6 run -e ENDPOINT=<endpoint url> loadtest.js`

# 5) observe the scaling of the pods
kubectl top pods
```
Here due to having more pods available which do handle the requests, reduced response times and overall less failed request should be expected when the kubernetes cluster is under stress.

