# Purpose

This project was used to the course [**Docker and Kubernetes: The Complete Guide**](https://www.udemy.com/docker-and-kubernetes-the-complete-guide) from section 14 till its end.

The rest of documentation used can be found at [dk-fib-calculator-multi-container](https://github.com/ricardo-aspira/dk-fib-calculator-multi-container/blob/master/README.md).

# Path to Production

![Path to Production](/docs/images/k8s-path-prod.png)

# Application Infraestructure

![k8s App Infra](/docs/images/k8s-app-infra.png)

# Cluster IP service

Instead of using **NodePort** service (only good for dev purposes), we should use **ClusterIP** service.

![k8s Object Types Infra](/docs/images/k8s-obj-types.png)

With **ClusterIP** we cannot access from the outside world the **Pod** through an IP and port as we did with **NodePort**. On the other hand, anything else running inside the cluster can access whatever object the **ClusterIP** is pointing at. Non traffic from outside can reach **ClusterIP** service.

In the k8s App Infra diagram describe above, we can see that the **ClusterIP** services are access only through **Ingress** service.

#### Differences between NodePort and ClusterIP

There is not **nodePort** property because it is not addressable or accessible from the outside world.

#### Equalities between NodePort and ClusterIP

The **port** property is going to be how other pods or other objects inside of our cluster are going to access the **Pod** that we are kind of governing access to.

The **targetPort** is going to be the port on the target **Pod** that we are providing access to. The port that container provides its service.

## Combination of files

We could specify the **ClusterIP** and **Deployment** on the same file, as below:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: server-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      component: server
  template:
    metadata:
      labels:
        component: server
    spec:
      containers:
        - name: server
          image: ricardosouzamorais/multi-fib-server
          ports:
            - containerPort: 5000 
---
apiVersion: v1
kind: Service
metadata:
  name: server-cluster-ip-service
spec:
  type: ClusterIP
  selector:
    component: server
  ports:
    - port: 5000
      targetPort: 5000
```



# Persistent Volume Claim and Persistent Volume

Check the appropriate [README file](docs/pvc-pv.md).





# Env variables

The env variables can only be specified as strings as can be seen below (e.g. **REDIS_PORT**).

# Secrets

Securely stores a piece of information in the cluster, such as a database password.

Instead of using a config file, we are going to use an imperative command to store our secret inside the cluster. We do not use the config file, because when you create a secret, you have to provide the data that will be encoded, so it does not make sense to store a config file with the original stuff that we want to hash.

Image that you password **banana**, r
Run the following command:

```sh
kubectl create secret generic SECRET_NAME --from-literal KEY=VALUE
```

*  `create` - imperative command to create a new object
*  `secret` - type of object we are going to create
*  `generic` - type of secret (indicates that we are saving some arbitrary number of key/value. There are other two types of secret that you might create: `docker-registry` and `tls`)
*  SECRET_NAME - name of sceret, for later reference in a **Pod** config file
*  `--from-literal` - specify that we are going to add the secret information into this command as opposed from a file
*  KEY=VALUE - key/value pair of the secret information

For a password **banana** stored in a key called **postgrespwd** inside a secret named **mysecrets**, we would have:

```sh
kubectl create secret generic mysecrets --from-literal postgrespwd=banana
```

To check the secrets, run: `kubectl get secrets`

## Wiring secret to **Pod** as env variable

Content of server deployment config file:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: server-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      component: server
  template:
    metadata:
      labels:
        component: server
    spec:
      containers:
        - name: server
          image: ricardosouzamorais/multi-fib-server
          ports:
            - containerPort: 5000 
          env:
            - name: REDIS_HOST
              value: redis-cluster-ip-service
            - name: REDIS_PORT
              value: '6379'
            - name: PGHOST
              value: postgres-cluster-ip-service
            - name: PGPORT
              value: '5432'
            - name: PGDATABASE
              value: postgres
            - name: PGUSER
              value: postgres
            - name: PGPASSWORD
              valueFrom:
                secretKeyRef:
                  name: mysecrets
                  key: postgrespwd
```

*  The `name` defined as the key inside the **Deployment** config file, inside `env` array is how the container knows it and is not related to the secret neither the key of the secret.
*  The `name` defined in `valueFrom`/`secretKeyRef` is the name of the secret created in the cluster.
*  The `key` defined in `valueFrom`/`secretKeyRef` is the key that stores the value inside the secret. A secret can stores a bunch of key/value pairs.

## Upgrading postgres to use other password

We just need to inform an env variable called PGPASSWORD inside the container spec of Postgres **Deployment** file.

The Postgres deployment config file:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      component: postgres
  template:
    metadata:
      labels:
        component: postgres
    spec:
      volumes:
        - name: postgres-storage
          persistentVolumeClaim:
            claimName: database-persistent-volume-claim
      containers:
        - name: postgres
          image: postgres
          ports: 
            - containerPort: 5432
          volumeMounts:
            - name: postgres-storage
              mountPath: /var/lib/postgresql/data
              subPath: postgres
          env:
            - name: PGPASSWORD
              valueFrom:
                secretKeyRef:
                  name: mysecrets
                  key: postgrespwd
```

# Load Balancer and Ingress

![Ingress and LoadBalancer](/docs/images/k8s-services.png)

LoadBalancer is a legacy way of getting some amount of traffic into your application.

## Load Balancer 

Actually does two separate things inside of your cluster.

A Load Balancer gives access to one set of pods only but in our case there are two sets of pods that we want to expose to outside world (**multi-server** and **multi-client**).

**k8s** is going to reach out your cloud provider and it is going to create a Load Balancer.
You need a Load Balancer outside of your cluster in order to access the load balancer inside of your cluster.

## Ingress

Exposes a set of services to the outside world.<br/>
There are several different implementations of ingress. We are going to use [**ingress-nginx**](http://github.com/kubernetes/ingress-nginx) not **kubernetes-ingress** that is a project from nginx company.

![ingress-nginx vs kubernetes-ingress](/docs/images/k8s-ingress-nginx.png)

Setup of [**ingress-nginx**](http://github.com/kubernetes/ingress-nginx) changes depending on your environment (local, GC, AWS, Azure etc). In this course, we are going to use local and GC.

### Behind the Scenes of Ingress

We are going to create **Ingress Config** file which is going to be a set of routing rules, feed that file into ***kubectl*** that will create this ingress controller. The ingress controller is going to make something that accepts incoming traffic.

![Ingress Config](/docs/images/k8s-ingress-config.png)

In the [**ingress-nginx**](http://github.com/kubernetes/ingress-nginx), the Ingress Controller and the thing that accepts incoming traffic are the same thing.

![Ingress Controller](/docs/images/k8s-ingress-controller.png)

### Behind the Scenes with Google Cloud

A Google Cloud Load Balancer is created and it sends traffic to a **LoadBalancer** service (the one we said that is not being used anymore) inside the cluster which is going to eventually get that traffic into the nginx ***Pod*** that gets created by our nginx controller. After that, it is up to the nginx ***Pod*** to eventually send that traffic off to the appropriate service inside our cluster.

Another deployment is setup inside your cluster, that is called **default-backend pod**, that is used for a series of health checks to essentially make sure that our cluster is working as expected. In the ideal world, you would replace this default-backend by your API.

![Ingress Controller GC](/docs/images/k8s-ingress-googlecloud.png)

[Ingress Nginx Deployment](https://kubernetes.github.io/ingress-nginx/deploy)

### The Ingress Config File

[ingress-service.yaml](k8s/ingress-service.yaml)

*  `metadata/annotations` - Higher level configurations around ingress object that is got created.
   *  `kubernetes.io/ingress.class: nginx` - tells the ***k8s*** that we want to create an ingress controller based on nginx project
   *  `nginx.ingress.kubernetes.io/rewrite-target: /` - how our copy of nginx behaves. After deciding sending that to **Server** instead of **Client**, it is going to do some rewrite on the request, for example, removing the `/api` part.
* `rules`- are saying that there are two possible paths that we can match traffic to.

# minikube Dashboard

Run: `minikube dashboard`

# Deployment in Production env