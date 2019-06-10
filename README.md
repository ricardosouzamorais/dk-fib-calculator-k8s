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

#### Difference between NodePort and ClusterIP

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

# Postgres PVC

***PVC*** stands for Persistent Volume Claim.

Without configuring a **PVC** we will have this kind of situation.

![Postgres PVC](/docs/images/k8s-postgres-pvc.png)

If we do not specify a persistent volume and **Pod** goes away, we will lose all data.

![Postgres PVC - Lost Data](/docs/images/k8s-postgres-pvc-lost-data.png)

Instead of writing data inside the container, we need to write data into this persistent volume that exists outside on host machine.

![Postgres PVC on Host](/docs/images/k8s-postgres-pvc-host.png)

## Replicas of Postgres on Deployment file

You will notice that inside our postgres-deployment file we specified the number of replicas as ***ONE (1)***.

In fact we can setup postgres to have some kind of replication or a clustering that is going to improve the availability and performance of our database. If we just increase the number of replicas to ***TWO (2)***, we would end up with a situation where two Pods that might be accessing the same volume but having two different databases accessing the same file system without them being aware of each other and have them very distinctly cooperate with eatch other, is a recipe for disaster.

That is not just isolated to postgres world, it is for many other databases you are going to find the same problem. So for whatever reason you want to scale up your copy of postgres and make it more available, you have to go through some additional steps.

# Volume - Container V.S. Kubernetes Terminology

![Volume Terminology](/docs/images/k8s-volume-terminology.png)

![Volume Access](/docs/images/k8s-volume-access.png)

## Volume on Kubernetes

We can have a Kubernetes Volume that could be accessed by any container inside that ***Pod***.

![Volume in k8s world](/docs/images/k8s-volume.png)

The downside is that the volume is tied to the ***Pod*** and so if ***Pod*** itself ever diest the volume dies and goes away as well.

Volume will survive container restarts inside of a ***Pod***.

## Volume V.S. Persistent Volume

![Volume V.S. Persistente Volume](/docs/images/k8s-volume-vs-persistent-volume.png)

Persistent is some type of long term durable storage that is not tied to any specific ***Pod*** or any specific container. 

## Persistent Volume V.S. Persistent Volume Claim

PVC are just like the advertisements, not actually volumes. They cannot persist anything just show the options available in the cluster.

Inside our cluster we might have some number of persistent volumes that have been created ahead of time. They are actually instances of hard drives essentially that can be used right away for storage.

Any persistent volume that is created ahead of time inside of our cluster is called **Statically provisioned Persistent Volume**. On the other hand, we also had another option that could have been create on the fly which is called **Dynamically provisioned Persistent Volume**.