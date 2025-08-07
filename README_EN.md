# 🚀 TKE Supernode Sandbox Reuse Testing Tool

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.20+-blue.svg)](https://kubernetes.io/)
[![Argo Workflows](https://img.shields.io/badge/Argo%20Workflows-3.4+-green.svg)](https://argoproj.github.io/argo-workflows/)

An automated testing tool specifically designed to test the sandbox reuse effectiveness of Tencent Cloud TKE (Tencent Kubernetes Engine) supernodes. Through precise time measurement and intelligent reuse detection, it helps you comprehensively understand the performance of supernodes.

## ✨ Core Features

- **⏱️ Precise Time Measurement**: Millisecond-precision measurement of Pod creation and sandbox initialization time
- **📊 Performance Comparison Analysis**: Detailed comparison between baseline tests and sandbox reuse tests
- **🔄 Rolling Update Testing**: Test sandbox reuse effectiveness during real rolling update scenarios
- **🎯 Intelligent Reuse Detection**: Automatic detection of sandbox reuse based on 20-second threshold
- **💬 WeChat Work Notifications**: Automatic push of test results to WeChat Work groups

## 🚀 Quick Start

### Prerequisites

- Kubernetes cluster (1.20+)
- Argo Workflows (3.4+)
- TKE supernode configured cluster
- kubectl command-line tool

### Installation Steps

1. **Clone the project**
```bash
git clone https://github.com/your-org/tke-chaos-playbook.git
cd tke-chaos-playbook
```

2. **Configure cluster access**
```bash
# Ensure kubectl can access the target cluster
kubectl cluster-info
```

3. **Run tests**

#### Using Scripts (Recommended)
```bash
# Interactive execution, supports all test types
./scripts/deploy-all.sh
```

#### Direct Workflow Submission
```bash
# Basic sandbox reuse test
kubectl apply -f playbook/workflow/supernode-sandbox-deployment-scenario.yaml

# Rolling update sandbox reuse test
kubectl apply -f playbook/workflow/supernode-rolling-update-scenario.yaml
```

## 📁 Project Structure

```
tke-chaos-playbook/
├── README.md                             # Project documentation
├── README_EN.md                          # English documentation
├── scripts/                              # Script tools
│   ├── deploy-all.sh                     # Main deployment script (recommended)
│   └── cleanup.sh                        # Cleanup script
├── playbook/                             # Argo Workflows
│   ├── template/                         # Workflow templates
│   │   ├── supernode-sandbox-deployment-template.yaml  # Basic test template
│   │   ├── supernode-rolling-update-template.yaml      # Rolling update test template
│   │   └── sandbox-wechat-notify-template.yaml         # WeChat Work notification template
│   └── workflow/                         # Workflow definitions
│       ├── supernode-sandbox-deployment-scenario.yaml  # Basic test workflow
│       └── supernode-rolling-update-scenario.yaml      # Rolling update test workflow
└── docs/                                 # Detailed documentation
    └── WECHAT_NOTIFICATION_SETUP.md      # WeChat notification setup guide
```

## 📊 Test Types

| Test Type | Description | Recommended Scenario |
|---|---|---|
| **Basic Sandbox Reuse Test** | Test sandbox reuse effectiveness by recreating Deployment | Basic performance validation |
| **Rolling Update Test** | Test sandbox reuse effectiveness in real rolling update scenarios | Production environment simulation |

## 🎯 Key Metrics

### Core Indicators
- **Sandbox Initialization Time**: Time from Pod creation to container startup (core metric)
- **Pod Creation Time**: Time from Deployment creation to Pod creation
- **End-to-End Time**: Total time from Deployment creation to container startup
- **Reuse Coverage Rate**: Percentage of Pods that successfully reuse sandboxes

### Judgment Criteria
- **Sandbox Reuse Success**: Sandbox initialization time < 20.0 seconds
- **Sandbox Reuse Failure**: Sandbox initialization time ≥ 20.0 seconds

## 🔧 Configuration Options

### Test Parameters
- **replicas**: Number of Pod replicas (default: 3)
- **test-iterations**: Number of test iterations (default: 2)
- **delay-between-tests**: Interval between tests (default: 30s)
- **pod-image**: Container image for testing (default: nginx:alpine)

### WeChat Work Notification
Configure WeChat Work webhook URL to receive test notifications:
```bash
# Interactive configuration
./scripts/deploy-all.sh --interactive

# Or specify webhook directly
./scripts/deploy-all.sh -w "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=YOUR_KEY"
```

## 📈 Test Results Example

```
📊 Sandbox Reuse Effect Analysis:
- Baseline Test: 25.2 seconds
- Sandbox Reuse Test: 8.7 seconds  
- Performance Improvement: 65.5%
- Reuse Coverage Rate: 100% (3/3 Pods)
```

## 🛠️ Troubleshooting

### Common Issues
1. **Pod Creation Timeout**: Check supernode status and image pulling
2. **Zero Reuse Rate**: Verify Pod specification consistency and test interval time
3. **Abnormal Time Measurement**: Verify kubectl permissions and timezone settings

### Diagnostic Commands
```bash
# Check cluster status
kubectl get nodes -l node.kubernetes.io/instance-type=eklet

# View test logs
kubectl logs -l workflows.argoproj.io/workflow -n tke-chaos-test

# Clean up test resources
./scripts/cleanup.sh
```

## 📖 Documentation

- [WeChat Work Notification Setup](docs/WECHAT_NOTIFICATION_SETUP.md) - WeChat notification configuration guide

## 🤝 Contributing

Welcome to submit Issues and Pull Requests to improve the project.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.