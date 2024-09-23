 # Setting up Minikube and Apache Kafka on Ubuntu 24.04
   
 ## Docker installation
```
sudo apt update
sudo apt install apt-transport-https curl
sudo apt install docker.io
sudo systemctl enable docker
sudo systemctl start docker
sudo groupadd docker
sudo usermod -aG docker $USER
sudo chmod 666 /var/run/docker.sock
sudo systemctl restart docker
```
For more details refer  https://docs.docker.com/install/linux/docker-ce/ubuntu/#install-docker-ce-1 

## Minikube installation

Make sure docker installed in master and nodes, make sure master has 2 cpu's 
Execute below commands in both master and node
```
sudo apt-get update && sudo apt-get install -y apt-transport-https curl
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
 ```
Confirm installation with
```
minikube version
```
For more details https://k8s-docs.netlify.app/en/docs/tasks/tools/install-minikube/

## Install kubectl

add Kubernetes repository for Ubuntu 20.04 to all the servers.
```
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
```
Then Checksum
```
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
```
Now install kubectl
```
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```
Now confirm installation
```
kubectl version --client
```
```
Client Version: version.Info{Major:"1", Minor:"22", GitVersion:"v1.22.2", GitCommit:"8b5a19147530eaac9476b0ab82980b4088bbc1b2", GitTreeState:"clean", BuildDate:"2021-09-15T21:38:50Z", GoVersion:"go1.16.8", Compiler:"gc", Platform:"linux/amd64"}
kubeadm version: &version.Info{Major:"1", Minor:"22", GitVersion:"v1.22.2", GitCommit:"8b5a19147530eaac9476b0ab82980b4088bbc1b2", GitTreeState:"clean", BuildDate:"2021-09-15T21:37:34Z", GoVersion:"go1.16.8", Compiler:"gc", Platform:"linux/amd64"}
```
For more detail use the following:
```
kubectl version --client --output=yaml
```
## It will be handy to port-forward
### Get the name of the broker
```
kubectl get pods -n kafka
```
And insert that name into the following:
```
kubectl port-forward <pod_name> 9092 -n kafka
```
## Adding a namespace
```
kubectl create namespace kafka
```
Edit a YAML file to apply
```
vi 00-namespace.yaml
```
enter the following:
```
apiVersion: v1
kind: Namespace
metadata:
  name: kafka
```
Now:
```
kubectl apply -f 05-namespace.yaml
```
and check the result:
```
kubectl get namespaces
```
## Deploy Zookeeper
```
kubectl apply -f 06-zookeeper.yaml
```
## Deploy Kafka
```
kubectl apply -f 07-kafka.yaml
```
## Creating and Listing Topics

To test adding Topics we can run the following command:
```
echo "hello world!" | kcat -P -b localhost:9092 -t test
```
To check this Topic was added we can check with kafkacat:
```
kcat -C -b localhost:9092 -t test
```
### Alternatively we can list Topics using /bin/kafka-topics.sh --list
but there are some steps involved.

The command we want to execute needs 3 pieces of information and looks like this:
```
kubectl -n kafka exec <kafka-pod-name> -- <path-to-kafka-bin-dir>/kafka-topics.sh --zookeeper <zookeeper-service-name>:2181 --list
```
We need to list pods and services to get 2 out of the 3:
```
kubectl get pods -n kafka
kubectl get services -n kafka
```
In order to get the path-to-kafka-bin we can first go to the console of Minikube using the kafka pod name:
```
$ kubectl exec --tty -i kafka-broker-5dfd5bd87c-48rrf --namespace kafka -- bash
root@kafka-broker:/#
```
Then some SysAdmin black magic to find the file:
```
root@kafka-broker:/# find . -iname 'kafka-topics.sh'
./opt/kafka_2.13-2.8.1/bin/kafka-topics.sh
```
Now as an example we have:
```
kubectl -n kafka exec kafka-broker-5dfd5bd87c-48rrf -- /opt/kafka_2.13-2.8.1/bin/kafka-topics.sh --zookeeper zookeeper-service:2181 --list
```

## Useful kubectl commands

Check kubernetes pods, services, volumes health:

 - `kubectl cluster-info` - get Kubernetes cluster info
 - `kubectl get nodes` - get list of nodes
 - `kubectl get services -n kafka` - a list of all services
 - `kubectl describe pod $pod_name` - describe a specific pod
 - `kubectl logs $pod_name` - get logs for a specific pod
 - `kubectl exec -it $pod_name -- bash` - enters container and run a bash shell in a specific pod
