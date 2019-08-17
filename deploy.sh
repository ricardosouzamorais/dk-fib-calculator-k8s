# Getting git commit sha
GIT_SHA=`git rev-parse HEAD`

# Build images
docker build \
            -t ricardosouzamorais/multi-fib-client:latest \
            -t ricardosouzamorais/multi-fib-client:$GIT_SHA \
            -f ./client/Dockerfile ./client

docker build \
            -t ricardosouzamorais/multi-fib-server:latest \
            -t ricardosouzamorais/multi-fib-server:$GIT_SHA \
            -f ./server/Dockerfile ./server

docker build \
            -t ricardosouzamorais/multi-fib-worker:latest \
            -t ricardosouzamorais/multi-fib-worker:$GIT_SHA \
            -f ./worker/Dockerfile ./worker

# Push images to Docker Hub (does not need to loging again cause we've login in Travis yaml file)
docker push ricardosouzamorais/multi-fib-client:latest
docker push ricardosouzamorais/multi-fib-client:$GIT_SHA
docker push ricardosouzamorais/multi-fib-server:latest
docker push ricardosouzamorais/multi-fib-server:$GIT_SHA
docker push ricardosouzamorais/multi-fib-worker:latest
docker push ricardosouzamorais/multi-fib-worker:$GIT_SHA

# Apply all cluster config files
kubectl apply -f ./k8s

# Set latest tag on each deployment
# deployment/name-of-deployment and then the name of 
# the container set to the image and tag
kubectl set image deployments/client-deployment \
        client=ricardosouzamorais/multi-fib-client:$GIT_SHA

kubectl set image deployments/server-deployment \
        server=ricardosouzamorais/multi-fib-server:$GIT_SHA

kubectl set image deployments/worker-deployment \
        worker=ricardosouzamorais/multi-fib-worker:$GIT_SHA