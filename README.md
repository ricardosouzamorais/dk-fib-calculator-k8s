# Purpose

This project was used to the course [**Docker and Kubernetes: The Complete Guide**](https://www.udemy.com/docker-and-kubernetes-the-complete-guide) from section 14 till its end.

The rest of documentation used can be found at [dk-fib-calculator-multi-container](https://github.com/ricardo-aspira/dk-fib-calculator-multi-container/blob/master/README.md).

# Path to Production

![Path to Production](/docs/images/k8s-path-prod.png)

# Application Infraestructure

![k8s App Infra](/docs/images/k8s-app-infra.png)

# Cluster IP service

Check the appropriate [README file](docs/cluster-ip.md).

# Persistent Volume Claim and Persistent Volume

Check the appropriate [README file](docs/pvc-pv.md).

# Environment variables and Secrets

Check the appropriate [README file](docs/env-secrets.md).

# Load Balancer and Ingress

Check the appropriate [README file](docs/lb-ingress.md).

# minikube Dashboard

Run `minikube dashboard` to see the minikube dashboard.

# Deployment in Production - Google Cloud

Check the appropriate [README file](docs/google-cloud.md).

## AWS V.S. Google Cloud

Why are swapping to Google Cloud?
*  Google created ***k8s***
*  AWS only recently got ***k8s*** support
*  Far, far easier to poke around ***k8s*** on Google Cloud
*  Excellent documentation bor beginners