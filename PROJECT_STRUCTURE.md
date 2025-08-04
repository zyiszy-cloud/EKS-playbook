# 项目结构

## 📁 目录结构

```
tke-chaos-playbook/
├── scripts/                                # 脚本工具
│   ├── deploy-all.sh                       # 一键部署脚本（主要工具）
│   └── cleanup.sh                          # 资源清理脚本
├── playbook/                               # Kubernetes资源
│   ├── rbac.yaml                           # RBAC权限配置
│   ├── install-argo.yaml                   # Argo Workflows安装
│   ├── template/                           # 工作流模板
│   │   ├── kubectl-cmd-template.yaml       # 基础kubectl模板
│   │   └── supernode-sandbox-deployment-template.yaml  # 沙箱测试模板
│   └── workflow/                           # 工作流场景
│       └── supernode-sandbox-deployment-scenario.yaml  # 测试场景
├── README.md                               # 项目说明（英文）
├── README_zh.md                            # 项目说明（中文）
├── USAGE.md                                # 详细使用指南
├── SANDBOX_REUSE_TEST_GUIDE.md             # 沙箱复用测试指南
├── INTERACTIVE_DEPLOYMENT_GUIDE.md         # 交互式部署指南
├── WECHAT_NOTIFICATION_SETUP.md            # 企业微信通知配置
└── LICENSE                                 # 许可证
```

## 🎯 核心文件说明

### 脚本工具
- **deploy-all.sh**: 主要部署脚本，支持交互式配置和命令行参数
- **cleanup.sh**: 资源清理脚本，支持多种清理模式

### Kubernetes资源
- **rbac.yaml**: 服务账户和权限配置
- **install-argo.yaml**: Argo Workflows安装配置
- **kubectl-cmd-template.yaml**: 基础kubectl命令模板
- **supernode-sandbox-deployment-template.yaml**: 核心测试模板
- **supernode-sandbox-deployment-scenario.yaml**: 测试场景工作流

### 文档
- **README.md**: 项目主要说明文档
- **USAGE.md**: 详细使用指南
- **SANDBOX_REUSE_TEST_GUIDE.md**: 沙箱复用测试原理和指南
- **INTERACTIVE_DEPLOYMENT_GUIDE.md**: 交互式部署详细说明
- **WECHAT_NOTIFICATION_SETUP.md**: 企业微信通知配置指南

## 🚀 快速开始

1. **一键部署**: `./scripts/deploy-all.sh --interactive`
2. **查看状态**: `kubectl get workflows -n tke-chaos-test`
3. **清理资源**: `./scripts/cleanup.sh quick`

项目结构已经简化，只保留核心功能和必要文档！