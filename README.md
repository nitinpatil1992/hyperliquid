# Overview

We have leveraged high availability across zones, controlled node types, dedicated nodes, affinitiy/antiaffinity along with zonal preference to run our hyperliquid node using ArgoCD and helm.
Critically, the signing of the node was bit underlook with helm configuration with replica count 2 but it can be improved reporeplicating the values.yaml to create the secondary controller.


# Base setup
The overall setup is configured considering we have running k8s environment. Most of the components are aligned with AWS setup which can easily be converted into choice of k8s hosting provider under any cloud/bare metal setup.

Simplified version of execution order
```
Node tuning -> k8s pre-provisioning -> CI/CD -> validation/rollout
```

You can simply render out the helm chart 
```sh
helm dependency update charts/hyperliquid-node/
helm template  hyperliquid-node --namespace hyperliquid charts/hyperliquid-node/
```

### Node tuning
Integrate the `base/node-tuning.sh` ansible/terraform to optimize k8s worker node running our hyperliquid node.

### k8s pre-provisioning 
```
# Handling toleration for our statefulset
kubectl taint nodes <node> dedicated=hyperliquid-node:NoSchedule

# Create storage class
kubectl apply -f base/storage-class.yaml

# setup the validator and signer keys
./base/resource.sh

```

# CI/CD 
We use github action here in order to validate the security around hyperliquid node setup. We simply leverage trivy to validate our setup. 
It is divided into building images, validating it, scanning the chart and deploying argocd cli to set the images.
Currently the sync is disabled but can be turned on for end to end deployment

# Key Design Choices
### Performance Optimizations

Instance Type Selection: m6i/m6in instances for consistent network performance

Storage: GP3 volumes with 16k IOPS for blockchain data

Network: kernel tuning for sub-millisecond latency

CPU: Guaranteed 4 cores with NUMA awareness

Memory: 16GB guaranteed with huge pages enabled

### Scaling Strategy

Horizontal scaling across AZs with StatefulSet

Pod anti-affinity ensures distribution

PDB maintains minimum availability during updates

Automatic peer discovery and optimization

### Monitoring & Observability

Custom peer latency metrics exported to Prometheus

Grafana dashboards for real-time monitoring

Alert rules for high latency (>50ms) connections

Distributed tracing with OpenTelemetry (optional)

### Latency Reduction
```yaml
#VPC CNI Configuration
apiVersion: v1
kind: ConfigMap
metadata:
  name: amazon-vpc-cni
  namespace: kube-system
data:
  enable-pod-eni: "true"
  enable-prefix-delegation: "true"
```

# Risk assessments
1. Supply chain attack: High
2. Consensus manipulation: low 
3. Secret exposure(insider/outsider exploitation): low 
4. Data exfiltration

# Thread Model & Security Hardening 

### Compromised runtimes (docker image/binary/depdendencies)

Impact is quite high  with  molicious code injected into base images or dependencies could compromise the node, potentially leading to:
- Private key theft
- Consensus manipulation
- Backdoor installation

We have targetted the container images from hyperliquid docker registry. Hence, there are chances in case whole repository is compromised along with GPG validation keys.

**Level**
High

**Mitigations**:

1. Segregate the network for workload (private subnets) with routing table, NACLs, and security groups with specific ports for inbound and outbound access
2. Implement advance OS hardining levels for worker nodes host
3. External dependencies are prunned to Suppy chain attack, test thoroughly before exposing credentials to molicious packages
4. Image verification
```yaml
# Admission Controller Policy
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  name: image-policy-webhook
webhooks:
  - name: validate.images.security
    clientConfig:
      service:
        name: image-policy-webhook
        namespace: security
        path: "/validate"
      caBundle: LS0tLS1CRUdJTi...
    rules:
      - operations: ["CREATE", "UPDATE"]
        apiGroups: ["*"]
        apiVersions: ["*"]
        resources: ["pods", "deployments", "statefulsets"]
```

### Credential exposure

1. Hardcoded credentials are prune to expose in most of the cases as it can get scrapped from developers machine with browser/IDE extensions
2. k8s support base64 encoded secrets but are easy to compromise once access is breached

**Level**
High

**Mitigation**
1. Use external secret operator to avoid storing credentials on version control
2. Alternatively, use kerberose to get the the credentials files from secure locations in your infrastructure boundary


# Improvements
1. Use of cert manager to enable end to end TLS/SSL traffic across the peer network
2. Enable falco securiy to alert based on the crirical files manipulation on running workloads 
3. Further enhancement for specific ports can be adjusted for peer to peer connection improvement
