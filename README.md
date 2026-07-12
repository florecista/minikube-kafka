# Setting up Minikube and Apache Kafka on Ubuntu Linux

Run a single Apache Kafka broker locally in Kubernetes for development and
script testing without using an AWS account.

The supported host environment is Ubuntu Linux. The included setup scripts
install the host prerequisites, allowing a new Linux instance to be prepared
quickly. The Kubernetes manifests themselves remain portable and can also be
used from Windows for development.

## Architecture

- Minikube provides a single-node Kubernetes cluster.
- Kafka 4.3.1 runs in KRaft combined broker/controller mode.
- ZooKeeper is not required.
- Kafka data is ephemeral and is discarded when the pod or cluster is removed.
- An in-cluster Job provides a repeatable producer/consumer smoke test, so kcat
  is optional.

This environment is intended only for local development. It does not configure
authentication, encryption, replication, durable storage, or other production
features.

## Prepare an Ubuntu host

The installation scripts support Ubuntu on x86-64 and ARM64. Run them as a
normal user with sudo access, from the repository directory. Install Docker
first:

```shell
bash 01_install_docker.sh
```

The Docker installer uses Docker's official apt repository, starts the service,
adds the current user to the `docker` group, and runs Docker's `hello-world`
test. Log out and back in after running it so the new group membership takes
effect. Return to the repository directory, then install Minikube and kubectl:

```shell
bash 02_install_minikube.sh
bash 03_install_kubectl.sh
```

kcat is not required for the automated smoke test. Install it when host-based
producer or consumer testing is useful:

```shell
bash 04_install_kcat.sh
```

The scripts follow the upstream installation processes for
[Docker Engine on Ubuntu](https://docs.docker.com/engine/install/ubuntu/),
[Minikube](https://minikube.sigs.k8s.io/docs/start/), and
[kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/).

### Windows development

Windows is not the primary bootstrap target. For development, install Docker
Desktop, kubectl, and Minikube separately, then continue from **Start
Minikube** below. The Kafka deployment and smoke test commands are identical.

## Start Minikube

Start Minikube with the Docker driver:

```shell
minikube start --driver=docker --cpus=2 --memory=4096
kubectl get nodes
```

The node should report `Ready` before continuing.

## Deploy Kafka

```shell
kubectl apply -f 05-namespace.yaml
kubectl apply -f 06-kafka.yaml
kubectl rollout status deployment/kafka -n kafka --timeout=5m
kubectl get pods,services -n kafka
```

The initial deployment may take a few minutes while Minikube downloads the
Kafka image.

## Run the smoke test

The Job creates a uniquely named topic, produces one message, consumes it, and
fails if the received value is not identical.

Delete any previous Job before running the test again:

```shell
kubectl delete job kafka-smoke-test -n kafka --ignore-not-found
kubectl apply -f 07-smoke-test.yaml
kubectl wait --for=condition=complete job/kafka-smoke-test -n kafka --timeout=2m
kubectl logs job/kafka-smoke-test -n kafka
```

Successful output ends with:

```text
Smoke test passed: hello from minikube kafka
```

## Connect from the host

Keep this command running in a separate terminal:

```shell
kubectl port-forward service/kafka 9094:9094 -n kafka
```

Host-based Kafka clients can then use `localhost:9094` as their bootstrap
server. For example, if kcat is installed:

```shell
echo "hello world" | kcat -P -b localhost:9094 -t test
kcat -C -o beginning -e -c 1 -b localhost:9094 -t test
```

Clients running inside Kubernetes should use `kafka:9092` instead.

## Useful commands

```shell
kubectl get all -n kafka
kubectl logs deployment/kafka -n kafka
kubectl describe deployment/kafka -n kafka
kubectl exec -it deployment/kafka -n kafka -- /bin/bash
```

## Cleanup

Remove Kafka while keeping Minikube:

```shell
kubectl delete namespace kafka
```

Remove the entire local cluster and all its data:

```shell
minikube delete
```

## AWS compatibility

This setup reproduces the Kafka protocol and common topic, producer, consumer,
and administration operations. It does not reproduce AWS MSK networking, IAM
authentication, TLS certificates, broker sizing, or multi-broker behaviour.
Pin the local Kafka version to the version used by the target MSK cluster when
version-specific behaviour matters.
