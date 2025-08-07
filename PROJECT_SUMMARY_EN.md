# 🚀 TKE Supernode Sandbox Reuse Testing Tool - Project Summary

## 📋 Project Overview

This project provides an automated testing framework specifically designed to evaluate the sandbox reuse effectiveness of Tencent Cloud TKE (Tencent Kubernetes Engine) supernodes. Through precise time measurement and intelligent analysis, it helps DevOps teams understand and optimize supernode performance.

## ✨ Key Features

### 🎯 Core Testing Capabilities
- **Precise Time Measurement**: Millisecond-precision measurement of Pod creation and sandbox initialization times
- **Intelligent Reuse Detection**: Automatic detection of sandbox reuse based on 20-second threshold
- **Performance Comparison Analysis**: Detailed comparison between baseline and sandbox reuse tests
- **Rolling Update Testing**: Real-world rolling update scenario testing
- **WeChat Work Integration**: Automated test result notifications

### 📊 Test Types

| Test Type | Description | Use Case |
|-----------|-------------|----------|
| **Basic Sandbox Reuse Test** | Tests sandbox reuse by recreating Deployments | Basic performance validation |
| **Rolling Update Test** | Tests sandbox reuse during real rolling update scenarios | Production environment simulation |

## 🏗️ Architecture

### Core Components
```
tke-chaos-playbook/
├── playbook/template/          # Argo Workflow templates
│   ├── supernode-sandbox-deployment-template.yaml
│   ├── supernode-rolling-update-template.yaml
│   └── sandbox-wechat-notify-template.yaml
├── playbook/workflow/          # Workflow definitions
├── scripts/                    # Deployment and utility scripts
└── docs/                      # Documentation
```

### Technology Stack
- **Kubernetes**: Container orchestration platform
- **Argo Workflows**: Workflow execution engine
- **TKE Supernodes**: Tencent Cloud's serverless container nodes
- **WeChat Work API**: Notification system

## 📈 Key Metrics

### Performance Indicators
- **Sandbox Initialization Time**: Core metric for sandbox reuse detection
- **Pod Creation Time**: Time from Deployment creation to Pod creation
- **End-to-End Time**: Total time from Deployment creation to container startup
- **Reuse Coverage Rate**: Percentage of Pods successfully reusing sandboxes

### Success Criteria
- **Sandbox Reuse Success**: Initialization time < 20.0 seconds
- **Effective Reuse**: Coverage rate > 50%
- **Significant Performance Improvement**: > 30% time reduction

## 🚀 Quick Start

### Prerequisites
- Kubernetes cluster with TKE supernodes
- Argo Workflows installed
- kubectl configured
- Optional: WeChat Work webhook for notifications

### Basic Usage
```bash
# Clone and setup
git clone <repository-url>
cd tke-chaos-playbook

# Interactive deployment (recommended)
./scripts/deploy-all.sh

# Direct workflow execution
kubectl apply -f playbook/workflow/supernode-sandbox-deployment-scenario.yaml
```

## 📊 Test Results Interpretation

### Sample Output
```
📊 Sandbox Reuse Effect Analysis:
- Baseline Test: 25.2 seconds
- Sandbox Reuse Test: 8.7 seconds  
- Performance Improvement: 65.5%
- Reuse Coverage Rate: 100% (3/3 Pods)
```

### Analysis Guidelines
- **Excellent**: >50% improvement, >80% coverage
- **Good**: 20-50% improvement, >50% coverage  
- **Poor**: <20% improvement, <50% coverage

## 🔧 Configuration Options

### Test Parameters
```yaml
replicas: 3                    # Number of Pod replicas
test-iterations: 2             # Number of test iterations
delay-between-tests: 30s       # Interval between tests
pod-image: nginx:alpine        # Container image for testing
```

### WeChat Work Notifications
```bash
# Configure webhook URL
./scripts/deploy-all.sh -w "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=YOUR_KEY"
```

## 🛠️ Troubleshooting

### Common Issues
1. **No Supernodes Found**: Verify TKE supernode configuration
2. **Zero Reuse Rate**: Check Pod specification consistency and test intervals
3. **Timeout Issues**: Verify cluster resources and image availability
4. **Notification Failures**: Validate WeChat Work webhook configuration

### Diagnostic Commands
```bash
# Check supernode status
kubectl get nodes -l node.kubernetes.io/instance-type=eklet

# View workflow logs
kubectl logs -l workflows.argoproj.io/workflow -n tke-chaos-test

# Clean up resources
./scripts/cleanup.sh
```

## 📚 Documentation

- [English README](README_EN.md) - Complete project documentation
- [中文文档](README.md) - Chinese documentation
- [WeChat Notification Setup](docs/WECHAT_NOTIFICATION_SETUP.md) - Notification configuration

## 🤝 Contributing

We welcome contributions! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request with detailed description

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🎯 Future Enhancements

- [ ] Multi-cluster testing support
- [ ] Advanced metrics collection
- [ ] Grafana dashboard integration
- [ ] Slack notification support
- [ ] Automated performance regression detection

---

**Maintained by**: TKE DevOps Team  
**Last Updated**: $(date '+%Y-%m-%d')  
**Version**: 1.0.0