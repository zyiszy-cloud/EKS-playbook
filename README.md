# EKS/TKE Serverless Performance Testing Playbook

[English](README.md) | [中文](README_zh.md)

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.20+-blue.svg)](https://kubernetes.io/)
[![TKE](https://img.shields.io/badge/TKE-Serverless-green.svg)](https://cloud.tencent.com/product/tke)

## 🚀 Overview

This project provides comprehensive performance testing capabilities for **Tencent Cloud TKE Serverless** (Elastic Kubernetes Service) and general Kubernetes chaos engineering scenarios. Built on Argo Workflow, it offers automated testing pipelines for evaluating and optimizing serverless container performance.

## ✨ Key Features

### 🎯 TKE Serverless Performance Testing
- **Pod Startup Performance**: Test pod startup speed across different specifications
- **Auto-scaling Performance**: Evaluate HPA response time and stability
- **Resource Optimization**: Analyze cost-performance ratios
- **Automated Reporting**: Generate detailed performance reports

### 🔥 Chaos Engineering Scenarios
- **Control Plane Testing**: API server, etcd overload scenarios
- **Component Disruption**: CoreDNS, kube-proxy service interruption
- **Master Component Testing**: Managed cluster component shutdown/recovery
- **Resource Protection**: Namespace deletion protection testing

## 🏃‍♂️ Quick Start

### Prerequisites

1. **Kubernetes Clusters**: Source cluster (for running tests) and target cluster (for testing)
2. **TKE Serverless Cluster**: Tencent Cloud EKS cluster
3. **Argo Workflow**: Installed in source cluster

### One-Click Testing (Recommended)

```bash
# Clone the repository
git clone https://github.com/wi1123/EKS-playbook.git
cd EKS-playbook

# Make script executable
chmod +x run-serverless-tests.sh

# Run pod startup performance test
./run-serverless-tests.sh startup

# Run auto-scaling performance test
./run-serverless-tests.sh scaling

# Run all performance tests
./run-serverless-tests.sh all
```

### Manual Setup

```bash
# Create necessary resources
kubectl create ns tke-chaos-test
kubectl create -n tke-chaos-test configmap tke-chaos-precheck-resource --from-literal=empty=""

# Configure target cluster kubeconfig
kubectl create -n tke-chaos-test secret generic dest-cluster-kubeconfig --from-file=config=./your-kubeconfig

# Deploy Argo Workflow
kubectl create -f playbook/install-argo.yaml

# Deploy templates and RBAC
kubectl create -f playbook/rbac.yaml
kubectl create -f playbook/all-in-one-template.yaml

# Run specific tests
kubectl create -f playbook/workflow/serverless-pod-startup-performance.yaml
kubectl create -f playbook/workflow/serverless-scaling-performance.yaml
```

## 📊 Performance Testing Scenarios

| Test Scenario | File | Description | Key Metrics |
|---------------|------|-------------|-------------|
| Pod Startup | `serverless-pod-startup-performance.yaml` | Test pod startup speed for different specs | Startup time, success rate, concurrency |
| Auto-scaling | `serverless-scaling-performance.yaml` | Test HPA scale-out/scale-in performance | Response time, stability, resource efficiency |
| Network Performance | Coming Soon | Test network latency and throughput | Latency, bandwidth, connection time |
| Storage Performance | Coming Soon | Test storage I/O performance | IOPS, throughput, mount time |

## 🎛️ Configuration Parameters

### Pod Startup Performance Test
```yaml
pod-count-small: "10"      # Small spec pods (0.25C/0.5Gi)
pod-count-medium: "5"      # Medium spec pods (1C/2Gi)
pod-count-large: "3"       # Large spec pods (2C/4Gi)
startup-timeout: "120s"    # Pod startup timeout
test-duration: "300s"      # Test duration
```

### Auto-scaling Performance Test
```yaml
initial-replicas: "2"      # Initial replica count
max-replicas: "20"         # Maximum replica count
target-cpu-percent: "50"   # Target CPU utilization
load-duration: "300s"      # Load test duration
cooldown-duration: "180s"  # Cooldown period
```

## 📈 Performance Benchmarks

### Pod Startup Performance
- **Small Pods** (0.25C/0.5Gi): < 10 seconds
- **Medium Pods** (1C/2Gi): < 15 seconds
- **Large Pods** (2C/4Gi): < 30 seconds
- **Success Rate**: > 95%

### Auto-scaling Performance
- **Scale-out Response**: < 60 seconds
- **Scale-in Response**: < 120 seconds
- **Stability**: No frequent oscillation

## 🔍 Monitoring and Results

### View Test Results

1. **Argo UI** (Recommended):
   ```bash
   # Get access token
   kubectl exec -it -n tke-chaos-test deployment/tke-chaos-argo-workflows-server -- argo auth token
   # Access UI at LoadBalancer IP:2746
   ```

2. **Command Line**:
   ```bash
   # Check workflow status
   kubectl get workflow -n tke-chaos-test
   
   # View detailed results
   kubectl describe workflow <workflow-name> -n tke-chaos-test
   ```

3. **Test Status**:
   ```bash
   ./run-serverless-tests.sh --status
   ```

## 📚 Documentation

- [TKE Serverless Performance Guide](playbook/TKE_SERVERLESS_PERFORMANCE_GUIDE.md) - Comprehensive testing guide
- [Chaos Engineering Scenarios](playbook/README.md) - Available chaos testing scenarios
- [Troubleshooting Guide](playbook/TKE_SERVERLESS_PERFORMANCE_GUIDE.md#故障排查) - Common issues and solutions

## 🛠️ Advanced Usage

### Custom Test Parameters

Edit the workflow YAML files to customize test parameters:

```yaml
# Example: Modify pod startup test
arguments:
  parameters:
  - name: pod-count-small
    value: "20"  # Increase small pod count
  - name: startup-timeout
    value: "180s"  # Extend timeout
```

### Integration with CI/CD

```yaml
# Example GitHub Actions workflow
name: TKE Serverless Performance Test
on:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM
jobs:
  performance-test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: Run Performance Tests
      run: ./run-serverless-tests.sh all
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Setup

```bash
# Fork and clone the repository
git clone https://github.com/your-username/EKS-playbook.git
cd EKS-playbook

# Create a feature branch
git checkout -b feature/new-test-scenario

# Make your changes and test
./run-serverless-tests.sh startup

# Submit a pull request
```

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built on [Argo Workflow](https://argoproj.github.io/argo-workflows/)
- Inspired by chaos engineering principles
- Designed for Tencent Cloud TKE Serverless

## 📞 Support

- 📧 Issues: [GitHub Issues](https://github.com/wi1123/EKS-playbook/issues)
- 📖 Documentation: [Wiki](https://github.com/wi1123/EKS-playbook/wiki)
- 💬 Discussions: [GitHub Discussions](https://github.com/wi1123/EKS-playbook/discussions)

---

**Made with ❤️ for the Kubernetes and Serverless community**