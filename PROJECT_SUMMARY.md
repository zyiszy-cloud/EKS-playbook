# TKE Chaos Playbook 项目总结

## 🎯 项目概述

TKE Chaos Playbook 是一个专门用于测试腾讯云TKE超级节点沙箱复用性能的自动化测试工具。

## ✨ 核心功能

- **沙箱复用测试**: 自动化测试沙箱复用机制的性能表现
- **精确时间测量**: 毫秒级精度的Pod创建和沙箱初始化时间测量
- **性能对比分析**: 基准测试与沙箱复用测试的详细对比
- **滚动更新测试**: 测试Pod滚动更新过程中的沙箱复用效果
- **企业微信通知**: 测试结果自动推送到企业微信群

## 📁 项目结构

```
tke-chaos-playbook/
├── playbook/                        # 核心工作流
│   ├── template/                    # Argo Workflows模板
│   │   ├── supernode-sandbox-deployment-template.yaml
│   │   ├── supernode-rolling-update-template.yaml
│   │   ├── kubectl-cmd-template.yaml
│   │   └── sandbox-wechat-notify-template.yaml
│   ├── workflow/                    # 工作流定义
│   │   ├── supernode-sandbox-deployment-scenario.yaml
│   │   └── supernode-rolling-update-scenario.yaml
│   ├── install-argo.yaml           # Argo安装配置
│   └── rbac.yaml                    # 权限配置
├── examples/                        # 测试示例
│   ├── basic-deployment-test.yaml
│   ├── performance-test.yaml
│   ├── sandbox-reuse-precise-test.yaml
│   ├── rolling-update-test.yaml
│   ├── test-wechat-notification.yaml
│   └── README.md
├── scripts/                         # 部署脚本
│   ├── deploy-all.sh               # 一键部署脚本
│   ├── cleanup.sh                  # 清理脚本
│   └── diagnose.sh                 # 诊断脚本
├── docs/                           # 文档
│   └── WECHAT_NOTIFICATION_SETUP.md # 微信通知配置指南
├── README.md                       # 项目主文档
└── LICENSE                         # MIT许可证
```

## 🚀 快速开始

```bash
# 1. 克隆项目
git clone <repository-url>
cd tke-chaos-playbook

# 2. 一键部署
./scripts/deploy-all.sh -q

# 3. 启动测试
kubectl apply -f examples/basic-deployment-test.yaml

# 4. 查看结果
kubectl get workflows -n tke-chaos-test -w
```

## 📊 测试场景

1. **基础功能验证**: `basic-deployment-test.yaml`
2. **精确沙箱复用测试**: `sandbox-reuse-precise-test.yaml`
3. **滚动更新测试**: `rolling-update-test.yaml`
4. **性能对比测试**: `performance-test.yaml`
5. **企业微信通知测试**: `test-wechat-notification.yaml`

## 🎉 项目特点

- **简洁高效**: 精简的项目结构，专注核心功能
- **易于使用**: 一键部署，快速上手
- **功能完整**: 涵盖沙箱复用测试的各种场景
- **企业级**: 支持企业微信通知，适合生产环境使用
- **开源友好**: MIT许可证，完整的文档和示例

## 📈 使用统计

- **总文件数**: 20个
- **YAML配置文件**: 11个
- **Markdown文档**: 4个
- **Shell脚本**: 3个
- **核心功能模块**: 5个

