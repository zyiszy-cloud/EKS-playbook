# TKE SuperNode Performance Testing Playbook

[English](README.md) | [中文](README_zh.md)

## Project Overview

This project is a comprehensive performance testing toolkit for Tencent Cloud TKE (Tencent Kubernetes Engine) SuperNodes based on Argo Workflows. It provides comprehensive performance benchmarking, network performance evaluation, image pulling tests, and resource elasticity validation capabilities. Through standardized testing processes and precise performance metrics, it helps users evaluate SuperNode performance and provides data support for business deployment decisions.

## Pod Creation Benchmark Testing

**playbook**: `workflow/supernode-pod-benchmark.yaml`

This scenario performs Pod creation performance benchmark testing on SuperNodes, including the following main processes:
- **Environment Pre-check**: Check cluster health status, verify SuperNode availability, ensure test environment meets requirements
- **Node Discovery**: Automatically discover all SuperNodes in the cluster and intelligently distribute test workloads
- **Concurrent Creation**: Create specified number of Pods concurrently or sequentially based on configuration, monitor creation status in real-time
- **Performance Statistics**: Precisely measure Pod creation time, calculate key metrics such as average latency, P99 latency, and success rate
- **Resource Cleanup**: Automatically clean up all test resources after testing completion

Supports two testing modes: `concurrent-creation` (concurrent creation) and `sequential-creation` (sequential creation). Concurrent mode can test SuperNode's concurrent processing capability, while sequential mode can obtain more stable baseline performance data.

**Parameter Description**

| Parameter Name | Type | Default Value | Description |
|---------|---------|------|--------|
| `target-pod-count` | `int` | `20` | Target number of Pods to create |
| `benchmark-type` | `string` | `concurrent-creation` | Test type: `concurrent-creation`/`sequential-creation` |
| `supernode-selector` | `string` | `node.kubernetes.io/instance-type=eklet` | SuperNode selector |
| `kubeconfig-secret-name` | `string` | `dest-cluster-kubeconfig` | Target cluster kubeconfig secret name |
| `test-namespace` | `string` | `tke-supernode-benchmark` | Test namespace |
| `pod-resource-cpu` | `string` | `100m` | Pod CPU resource request |
| `pod-resource-memory` | `string` | `128Mi` | Pod memory resource request |
| `timeout-seconds` | `int` | `300` | Test timeout (seconds) |
| `batch-size` | `int` | `10` | Batch creation size (for concurrent mode only) |

## Network Performance Testing

**playbook**: `workflow/network-performance-test.yaml`

This scenario tests network performance between SuperNodes, including the following main processes:
- **Network Topology Construction**: Deploy client and server Pods on different SuperNodes
- **Connectivity Testing**: Verify network connectivity between Pods, ensure test environment is normal
- **Latency Testing**: Measure round-trip time (RTT) for Pod-to-Pod communication
- **Throughput Testing**: Test network bandwidth and data transmission capability
- **Protocol Support**: Support TCP and UDP protocol performance testing
- **Result Analysis**: Generate detailed network performance reports and optimization recommendations

**Parameter Description**

| Parameter Name | Type | Default Value | Description |
|---------|---------|------|--------|
| `test-type` | `string` | `latency` | Test type: `latency`/`throughput`/`all` |
| `protocol` | `string` | `tcp` | Network protocol: `tcp`/`udp` |
| `test-duration` | `string` | `60s` | Test duration |
| `packet-size` | `int` | `1024` | Packet size (bytes) |
| `concurrent-connections` | `int` | `10` | Number of concurrent connections |
| `supernode-selector` | `string` | `node.kubernetes.io/instance-type=eklet` | SuperNode selector |
| `kubeconfig-secret-name` | `string` | `dest-cluster-kubeconfig` | Target cluster kubeconfig secret name |
| `server-port` | `int` | `8080` | Server listening port |

## Image Pull Testing

**playbook**: `workflow/image-pull-test.yaml`

This scenario tests SuperNode image pulling performance, including the following main processes:
- **Image Preparation**: Prepare test images of different sizes (small, medium, large images)
- **Concurrent Pulling**: Pull multiple images concurrently to simulate real business scenarios
- **Performance Measurement**: Record image pull time and success rate
- **Cache Testing**: Test the effectiveness of image caching mechanisms
- **Optimization Recommendations**: Provide image pull optimization recommendations based on test results

**Parameter Description**

| Parameter Name | Type | Default Value | Description |
|---------|---------|------|--------|
| `image-sizes` | `string` | `small,medium,large` | Test image size types |
| `concurrent-pulls` | `int` | `5` | Number of concurrent pulls |
| `test-images` | `string` | `nginx:alpine,ubuntu:20.04,tensorflow/tensorflow:latest` | Test image list |
| `supernode-selector` | `string` | `node.kubernetes.io/instance-type=eklet` | SuperNode selector |
| `kubeconfig-secret-name` | `string` | `dest-cluster-kubeconfig` | Target cluster kubeconfig secret name |
| `image-pull-policy` | `string` | `Always` | Image pull policy |
| `timeout-per-image` | `int` | `600` | Timeout per image pull (seconds) |

## Resource Elasticity Testing

**playbook**: `workflow/resource-elasticity-test.yaml`

This scenario tests SuperNode resource elasticity scaling capability, including the following main processes:
- **Baseline Testing**: Establish resource usage baseline
- **Gradual Pressure**: Gradually increase Pod count and resource consumption
- **Elasticity Monitoring**: Monitor node resource utilization and Pod scheduling status
- **Limit Testing**: Test performance under resource overcommitment scenarios
- **Recovery Verification**: Verify recovery capability after resource release

**Parameter Description**

| Parameter Name | Type | Default Value | Description |
|---------|---------|------|--------|
| `initial-pod-count` | `int` | `10` | Initial Pod count |
| `max-pod-count` | `int` | `100` | Maximum Pod count |
| `increment-step` | `int` | `10` | Pod count increment per step |
| `step-duration` | `string` | `60s` | Duration of each step |
| `resource-stress-cpu` | `string` | `500m` | CPU stress test resource |
| `resource-stress-memory` | `string` | `512Mi` | Memory stress test resource |
| `supernode-selector` | `string` | `node.kubernetes.io/instance-type=eklet` | SuperNode selector |
| `kubeconfig-secret-name` | `string` | `dest-cluster-kubeconfig` | Target cluster kubeconfig secret name |

## SuperNode Comprehensive Testing

**playbook**: `workflow/supernode-scenario.yaml`

This scenario provides comprehensive testing for SuperNodes, supporting multiple testing scenarios:

### Testing Scenario Types

1. **Schedule Pressure Testing (schedule-pressure)**: Batch create Pods to SuperNodes, test scheduling capability and capacity
2. **Resource Limit Testing (resource-limit)**: Create high CPU and memory consuming Pods, test resource management capability
3. **Failure Simulation Testing (failure-simulation)**: Create failing Pods, test exception handling capability

**Parameter Description**

| Parameter Name | Type | Default Value | Description |
|---------|---------|------|--------|
| `scenario-type` | `string` | `schedule-pressure` | Testing scenario type |
| `supernode-selector` | `string` | `node.kubernetes.io/instance-type=eklet` | SuperNode selector |
| `test-duration` | `string` | `60s` | Test duration |
| `test-pod-count` | `int` | `10` | Test Pod count |
| `kubeconfig-secret-name` | `string` | `dest-cluster-kubeconfig` | Target cluster kubeconfig secret name |

## Project Structure

```
tke-chaos-playbook/
├── playbook/                    # Core testing components
│   ├── template/               # Workflow templates
│   │   ├── supernode-pod-benchmark-template.yaml  # Pod creation benchmark template
│   │   ├── network-performance-template.yaml      # Network performance test template
│   │   ├── image-pull-template.yaml              # Image pull test template
│   │   ├── resource-elasticity-template.yaml     # Resource elasticity test template
│   │   ├── supernode-template.yaml               # SuperNode comprehensive test template
│   │   ├── kubectl-cmd-template.yaml             # kubectl command execution template
│   │   └── precheck-template.yaml                # Pre-check template
│   ├── workflow/               # Test scenario definitions
│   │   ├── supernode-pod-benchmark.yaml          # Pod creation benchmark workflow
│   │   ├── network-performance-test.yaml         # Network performance test workflow
│   │   ├── image-pull-test.yaml                  # Image pull test workflow
│   │   ├── resource-elasticity-test.yaml         # Resource elasticity test workflow
│   │   └── supernode-scenario.yaml               # SuperNode comprehensive testing workflow
│   ├── scripts/                # Automation scripts
│   │   ├── deploy-all-templates.sh               # Deploy all templates
│   │   ├── deploy-supernode-benchmark.sh         # Deploy benchmark test environment
│   │   ├── test-network-performance.sh           # Network performance test script
│   │   ├── validate-project.sh                   # Project validation script
│   │   └── validate-supernode-allocation.sh      # SuperNode allocation validation script
│   ├── config/                 # Configuration files
│   │   ├── supernode-config.yaml                 # SuperNode configuration
│   │   ├── network-test-config.yaml              # Network test configuration
│   │   └── performance-thresholds.yaml           # Performance threshold configuration
│   ├── install-argo.yaml      # Argo Workflows installation configuration
│   ├── rbac.yaml              # RBAC permission configuration
│   └── README_zh.md           # Project documentation (Chinese)
├── README.md                   # Main project documentation (English)
├── read.md                     # Testing scenario documentation
└── LICENSE                     # License file
```

## Quick Start

### Environment Prerequisites

1. **Tencent Cloud TKE Cluster**: A created and configured TKE cluster with at least one SuperNode
2. **kubectl**: Installed and configured with access permissions to the TKE cluster
3. **Shell Environment**: Terminal environment supporting bash (Linux/MacOS)
4. **Network Access**: Ability to access Tencent Cloud Container Service and image repositories

### Installation and Deployment

```bash
# 1. Clone the project
git clone <repository-url>
cd tke-chaos-playbook

# 2. Install Argo Workflows
kubectl apply -f playbook/install-argo.yaml
kubectl apply -f playbook/rbac.yaml

# 3. Deploy test templates
./playbook/scripts/deploy-supernode-benchmark.sh

# 4. Verify installation
./playbook/scripts/validate-project.sh
```

### Running Tests

```bash
# Pod creation benchmark test
kubectl apply -f playbook/workflow/supernode-pod-benchmark.yaml

# Network performance test
kubectl apply -f playbook/workflow/network-performance-test.yaml

# Image pull test
kubectl apply -f playbook/workflow/image-pull-test.yaml

# Resource elasticity test
kubectl apply -f playbook/workflow/resource-elasticity-test.yaml

# SuperNode comprehensive testing
kubectl apply -f playbook/workflow/supernode-scenario.yaml
```

### Viewing Test Results

```bash
# View workflow status
kubectl get workflows -n tke-chaos-test

# View test logs
kubectl logs -n tke-chaos-test -l workflows.argoproj.io/workflow=<workflow-name> -f

# View detailed results
kubectl describe workflow <workflow-name> -n tke-chaos-test
```

## Performance Metrics

### Key Metrics

- **Pod Creation Time**: Time from Pod creation to Running state
- **End-to-End Time**: Complete time from Pod creation to Ready state
- **P99 Latency**: 99% of operations have latency less than this value
- **Success Rate**: Percentage of successfully completed operations
- **Network Latency**: Round-trip time (RTT) for Pod-to-Pod communication
- **Network Throughput**: Network data transmission rate
- **Image Pull Time**: Image download completion time
- **Resource Utilization**: CPU and memory resource usage

### Performance Benchmarks

**Excellent Level**:
- Pod creation P99 < 10s, success rate > 95%
- Network latency < 1ms, throughput > 1Gbps
- Image pull P99 < 30s

**Good Level**:
- Pod creation P99 < 20s, success rate > 90%
- Network latency < 5ms, throughput > 500Mbps
- Image pull P99 < 60s

**Needs Optimization**:
- Pod creation P99 > 30s, success rate < 85%
- Network latency > 10ms, throughput < 100Mbps
- Image pull P99 > 120s

## Configuration

### SuperNode Configuration

Modify the `playbook/config/supernode-config.yaml` file:

```yaml
# SuperNode selector
supernodes:
  auto_discovery: true
  selector: "node.kubernetes.io/instance-type=eklet"

# Pod resource configuration
pod_config:
  resources:
    requests:
      cpu: "100m"
      memory: "128Mi"
    limits:
      cpu: "200m"
      memory: "256Mi"
```

### Test Parameter Configuration

Modify parameters in workflow files:

```yaml
# playbook/workflow/supernode-pod-benchmark.yaml
arguments:
  parameters:
  - name: target-pod-count
    value: "50"  # Increase Pod count
  - name: benchmark-type
    value: "concurrent-creation"  # Select test type
```

## Troubleshooting

### Common Issues

1. **Template Not Found**
   ```bash
   # Solution: Redeploy templates
   ./playbook/scripts/deploy-all-templates.sh
   ```

2. **Pod Creation Failed**
   ```bash
   # Check SuperNode status
   kubectl get nodes -l node.kubernetes.io/instance-type=eklet
   
   # Check resource quotas
   kubectl describe quota -n tke-supernode-benchmark
   ```

3. **Network Test Failed**
   ```bash
   # Check network policies
   kubectl get networkpolicies -n tke-supernode-benchmark
   
   # Check service status
   kubectl get svc -n tke-supernode-benchmark
   ```

4. **Permission Issues**
   ```bash
   # Check RBAC configuration
   kubectl get clusterrolebinding | grep tke-chaos
   
   # Reapply permission configuration
   kubectl apply -f playbook/rbac.yaml
   ```

### Debug Commands

```bash
# View Pod detailed information
kubectl describe pod <pod-name> -n tke-supernode-benchmark

# View node resource usage
kubectl top nodes -l node.kubernetes.io/instance-type=eklet

# View workflow execution details
kubectl get workflow <workflow-name> -n tke-chaos-test -o yaml

# Monitor test progress
kubectl get pods -n tke-supernode-benchmark -w
```

## Best Practices

### Testing Recommendations

1. **Phased Testing**: Start with small-scale functional verification, then proceed to large-scale performance testing
2. **Baseline Establishment**: Establish performance baselines during business off-peak hours as reference for future comparisons
3. **Regular Monitoring**: Regularly execute performance tests to monitor SuperNode performance trends
4. **Environment Isolation**: Conduct stress testing in dedicated test environments to avoid affecting production business

### Optimization Recommendations

1. **Resource Configuration Optimization**: Adjust Pod resource requests and limits based on test results
2. **Image Optimization**: Use image caching and local image repositories to improve pull speed
3. **Network Optimization**: Configure appropriate network plugins and policies to improve network performance
4. **Monitoring and Alerting**: Establish performance monitoring and alerting mechanisms to detect performance issues promptly

## Resource Cleanup

```bash
# Delete test workflows
kubectl delete workflow --all -n tke-chaos-test

# Clean up test namespaces
kubectl delete namespace tke-supernode-benchmark --ignore-not-found=true
kubectl delete namespace tke-supernode-test --ignore-not-found=true

# Clean up templates (optional)
kubectl delete clusterworkflowtemplate --all
```

## Important Notes

1. **Resource Consumption**: Large-scale testing will consume significant cluster resources, please plan test scale reasonably
2. **Network Impact**: Network performance testing may have some impact on cluster network
3. **Cost Control**: SuperNodes are billed based on usage, please pay attention to controlling test costs
4. **Security Considerations**: Testing process will create many resources, ensure test environment is securely isolated
5. **Version Compatibility**: Ensure Argo Workflows version is compatible with Kubernetes cluster version

---

**Project Status**: Production Ready ✅  
**Technical Support**: Verified in actual TKE environments  
**Continuous Improvement**: Keeping pace with latest TKE SuperNode features