# TKE Chaos Playbook 中文指南

基于Argo Workflows的腾讯云TKE超级节点沙箱复用测试平台。

## 🎯 项目简介

本项目是专门为腾讯云TKE超级节点设计的沙箱复用性能测试工具。通过精确的时间测量和智能的复用检测，帮助用户验证和优化超级节点的沙箱复用机制。

## ✨ 主要特性

- **🚀 自动化测试**: 全自动的沙箱复用性能测试流程
- **⏱️ 精确测量**: 毫秒级精度的时间测量
- **📊 智能分析**: 自动分析沙箱复用效果
- **💬 实时通知**: 企业微信群实时推送测试结果
- **🔧 易于使用**: 一键部署，简单配置

## 🚀 快速开始

### 环境要求

- Kubernetes集群（推荐TKE）
- Argo Workflows已安装
- kubectl命令行工具
- 超级节点已配置

### 一键部署

```bash
# 克隆项目
git clone <repository-url>
cd tke-chaos-playbook

# 交互式配置部署（推荐新手）
./scripts/deploy-all.sh --interactive

# 快速部署（默认配置）
./scripts/deploy-all.sh -q

# 自定义配置部署
./scripts/deploy-all.sh -i 2 -r 5 -w "YOUR_WEBHOOK_URL"
```

### 启动测试

```bash
# 基础测试
kubectl apply -f examples/basic-deployment-test.yaml

# 性能测试
kubectl apply -f examples/performance-test.yaml

# 精确沙箱复用测试
kubectl apply -f examples/sandbox-reuse-precise-test.yaml

# 滚动更新沙箱复用测试
kubectl apply -f examples/rolling-update-test.yaml
```

### 查看结果

```bash
# 监控测试状态
kubectl get workflows -n tke-chaos-test -w

# 查看详细日志
kubectl logs -l workflows.argoproj.io/workflow -n tke-chaos-test
```

## 📋 核心功能

| 功能 | 描述 | 状态 |
|---|---|---|
| **Deployment测试** | 使用Deployment进行沙箱复用测试 | ✅ 推荐 |
| **滚动更新测试** | 测试Pod滚动更新过程中的沙箱复用效果 | ✅ 新增 |
| **精确时间测量** | 毫秒级精度的时间测量 | ✅ 已优化 |
| **智能复用检测** | 自动检测沙箱复用情况 | ✅ 已修复 |
| **企业微信通知** | 测试结果自动发送到微信群 | ✅ 支持 |
| **多维度分析** | 全面的性能分析报告 | ✅ 完整 |

## 🛠️ 配置参数

### 部署脚本参数

```bash
./scripts/deploy-all.sh [选项]
  -i, --iterations NUM    测试迭代次数 (1-20, 默认: 2)
  -r, --replicas NUM      Pod副本数 (默认: 5)
  -w, --webhook URL       企业微信webhook地址
  -c, --cluster-id ID     集群ID (默认: tke-cluster)
  --image IMAGE           Pod镜像 (默认: nginx:alpine)
  --cpu-request CPU       CPU请求 (默认: 100m)
  --memory-request MEM    内存请求 (默认: 128Mi)
  --cpu-limit CPU         CPU限制 (默认: 200m)
  --memory-limit MEM      内存限制 (默认: 256Mi)
  --delay TIME            测试间隔 (默认: 30s)
  -q, --quick             快速模式，跳过确认
  --interactive           交互式配置模式
  --skip-test             只部署组件，不启动测试
```

### 清理资源

```bash
# 快速清理
./scripts/cleanup.sh quick

# 完全清理
./scripts/cleanup.sh full

# 交互式清理
./scripts/cleanup.sh
```

## 📊 测试结果解读

### 典型测试输出

```
📋 Pod创建时间（不含启动时间）:
- 基准测试平均: 14.000秒
- 沙箱复用平均: 13.400秒
- 性能提升: 4.3%

📊 沙箱复用效果分析:
- 基准测试（首次创建）: 14.000秒
- 沙箱复用测试: 13.400秒
- 沙箱复用覆盖率: 60% (6/10个Pod)
- 结论: 沙箱复用显著提升了Pod启动性能
```

### 关键指标说明

- **基准测试时间**: 首次创建沙箱的时间
- **沙箱复用时间**: 复用现有沙箱的时间
- **性能提升**: (基准时间-复用时间)/基准时间 × 100%
- **复用覆盖率**: 成功复用沙箱的Pod占比

### 成功标准

- ✅ 沙箱复用时间 < 基准测试时间
- ✅ 性能提升 > 2%
- ✅ 复用覆盖率 > 50%
- ✅ 所有Pod成功启动

## 🔧 故障排除

### 常见问题

1. **时间显示0.000秒**
   - 原因：容器未启动或时区问题
   - 解决：检查Pod状态，验证时区设置

2. **沙箱复用率为0%**
   - 原因：测试间隔太短或配置不一致
   - 解决：增加测试间隔，检查Pod规格

3. **测试超时**
   - 原因：资源不足或网络问题
   - 解决：检查集群资源，验证网络连接

### 调试工具

```bash
# 系统诊断
./scripts/diagnose.sh

# 查看Pod状态
kubectl get pods -n tke-chaos-test

# 查看工作流日志
kubectl logs -n argo <workflow-name>
```

## 📁 项目结构

```
tke-chaos-playbook/
├── playbook/
│   ├── template/                    # 工作流模板
│   └── workflow/                    # 工作流定义
├── examples/                        # 测试示例
├── scripts/                         # 辅助脚本
├── docs/                           # 文档
└── README.md                       # 项目说明
```

## 🔗 核心文件

- **部署脚本**: `scripts/deploy-all.sh` - 一键部署工具
- **清理脚本**: `scripts/cleanup.sh` - 资源清理工具
- **主测试模板**: `playbook/template/supernode-sandbox-deployment-template.yaml`
- **kubectl模板**: `playbook/template/kubectl-cmd-template.yaml`
- **微信通知模板**: `playbook/template/sandbox-wechat-notify-template.yaml`

## 📖 详细文档

- [使用指南](docs/USAGE.md) - 详细使用说明
- [沙箱复用测试指南](docs/SANDBOX_REUSE_TEST_GUIDE.md) - 专业测试指南
- [交互式部署指南](docs/INTERACTIVE_DEPLOYMENT_GUIDE.md) - 新手友好指南
- [企业微信通知配置](docs/WECHAT_NOTIFICATION_SETUP.md) - 通知配置指南
- [微信模板架构](docs/WECHAT_TEMPLATE_ARCHITECTURE.md) - 技术架构说明

## 🤝 贡献

欢迎提交Issue和Pull Request来改进项目！

## 📄 许可证

本项目采用MIT许可证。