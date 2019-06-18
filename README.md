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

Volume will survive container restarts inside of a ***Pod*** but not ***Pod*** crashes/recreation.

## Volume V.S. Persistent Volume

![Volume V.S. Persistente Volume](/docs/images/k8s-volume-vs-persistent-volume.png)

Persistent is some type of long term durable storage that is not tied to any specific ***Pod*** or any specific container. 

## Persistent Volume V.S. Persistent Volume Claim

PVC are just like the advertisements, not actually volumes. They cannot persist anything just show the options available in the cluster.

Inside our cluster we might have some number of persistent volumes that have been created ahead of time. They are actually instances of hard drives essentially that can be used right away for storage.

Any persistent volume that is created ahead of time inside of our cluster is called **Statically provisioned Persistent Volume**. On the other hand, we also had another option that could be created on the fly which is called **Dynamically provisioned Persistent Volume**.

# Claim Config Files

A config file that has the **kind** property as ***PersistentVolumeClaim*** is not an actual instance of storage, but it is something that we are going to attach to a ***Pod*** config. If we attach the `database-persistent-volume-claim.yaml`do a ***Pod***, ***k8s*** must find an instance of storage like a slice of your HD that meets this requirement.

## Access Modes

![Access Modes](/docs/images/k8s-persistent-volume-claim-access-modes.png)

## Allocation of Persistent Volume by k8s

On your personal computer, ***k8s*** it gets a slice from your HD.<br/>
You can use the following commands in order to check the storage classes and their details:
*  `kubectl get storageclass`
*  `kubectl describe storageclass`

When we are talking about a Cloud Provider, we can have it from a lot of options like Google Cloud Persistent Disk, Azure File, Azure Disk, AWS Block Store.<br/>
You can see other options in [Storage Classes Options](https://kubernetes.io/docs/concepts/storage/storage-classes) link.

## Linking PVC to Pod

We do it with `volumes` inside Deployment config file but that is not enough, besides specifying, we need to link it to the container through `volumeMounts` configuration inside the same config file.

**ATTENTION:** The **volume name** and **volume mount name** should be identical.

The `mountPath` property of the `volumeMount` is where inside the container this storage should be available.

The `subPath` is not needed for a normal application but in our case, for Postgres, it is needed and it means that any data inside the container that is stored inside of this mount path, is going to be stored inside of a folder with this name in the actual persistent volume claim.

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
```

To get information about PV from your cluster, run `kubectl get pv` and for PVC, run `kubectl get pvc`.

# Env variables

The env variables can only be specified as strings as can be seen below.

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