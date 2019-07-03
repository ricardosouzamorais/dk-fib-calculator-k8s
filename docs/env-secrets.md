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