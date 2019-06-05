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

The **port** propertye is going to be how other pods or other objects inside of our cluster are going to access the **Pod** that we are kind of governing access to.

The **targetPort** is going to be the port on the target **Pod** that we are poviding access to. The port that container provides its service.
