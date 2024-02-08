# Kubernetes Technical Challenge 1

Complete as much of this challenge as you can. We will be discussing this with you during your interview.

The goal of this challenge is to create a monitoring stack using the Prometheus Operator to scrape
application metrics and send a notification to AlertManger when the application is not running.

## Create a Kubernetes cluster

 - Create a Kubernetes cluster. This can be done in whatever environment you prefer, including
[kind](https://kind.sigs.k8s.io/) or [minikube](https://minikube.sigs.k8s.io/).

## Install Prometheus & Alertmanager using the Prometheus Operator

- Install [Prometheus Operator](https://github.com/prometheus-operator/prometheus-operator#quickstart)
- Create a [`Prometheus` resource](https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/api.md#prometheus) that runs Prometheus as an HA pair
- Create an [`Alertmanager` resource](https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/api.md#alertmanager) that Prometheus connects to

## Deploy an application that exposes Prometheus metrics

- Create a `Deployment` that runs the [`kubespheredev/prometheus-example-app`](https://github.com/kubesphere/prometheus-example-app) container
- Create a `Service` that exposes the Prometheus metrics on port `2112`

 ## Deploy monitoring for the application

- Create a [`ServiceMonitor` resource](https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/api.md#servicemonitor) that scrapes the metrics from the application
- Create a [`PrometheusRule` resource](https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/api.md#prometheusrule) that notifies Alertmanager when the metrics are missing
- Bonus: Create an [`AlertmanagerConfig` resource](https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/api.md#alertmanagerconfig) that sends the alert notification via email

## Submitting the results

You will need to provide the following information.

- The manifest(s) you used to deploy
  - Prometheus
  - Alertmanager
  - the application
  - ServiceMonitor
  - PrometheusRule
- A screenshot showing the pods running on the cluster
- A screenshot showing the metrics in Prometheus
- A screenshot showing the alert in Alertmanager
