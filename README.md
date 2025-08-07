# TKE Chaos Playbook

腾讯云容器服务（TKE）混沌工程测试工具集，专注于超级节点沙箱复用性能测试。

## 🎯 项目概述

本项目提供了一套完整的混沌工程测试工具，用于测试和验证腾讯云TKE超级节点的沙箱复用机制性能。通过自动化的测试流程，可以准确测量Pod创建时间、沙箱初始化时间，并分析沙箱复用对性能的影响。

## ✨ 核心功能

- **🚀 超级节点沙箱复用测试**: 自动化测试沙箱复用机制的性能表现
- **⏱️ 精确时间测量**: 毫秒级精度的Pod创建和沙箱初始化时间测量
- **📊 性能对比分析**: 基准测试与沙箱复用测试的详细对比
- **🔄 滚动更新测试**: 测试Pod滚动更新过程中的沙箱复用效果
- **💬 企业微信通知**: 测试结果自动推送到企业微信群
- **📈 多维度指标**: Pod创建时间、沙箱初始化时间、端到端时间等多项指标
- **🔍 智能复用检测**: 基于时间差异自动检测沙箱复用情况

## 🚀 快速开始

### 前置条件

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

## 📁 项目结构

```
tke-chaos-playbook/
├── playbook/
│   ├── template/                    # Argo Workflows模板
│   │   ├── supernode-sandbox-deployment-template.yaml  # 主测试模板
│   │   ├── supernode-rolling-update-template.yaml      # 滚动更新测试模板
│   │   ├── kubectl-cmd-template.yaml                   # kubectl命令模板
│   │   └── sandbox-wechat-notify-template.yaml         # 微信通知模板
│   └── workflow/                    # 工作流定义
│       ├── supernode-sandbox-deployment-scenario.yaml  # 基础测试工作流
│       └── supernode-rolling-update-scenario.yaml      # 滚动更新工作流
├── examples/                        # 测试示例
│   ├── basic-deployment-test.yaml           # 基础测试
│   ├── performance-test.yaml               # 性能测试
│   ├── sandbox-reuse-precise-test.yaml     # 精确沙箱复用测试
│   ├── rolling-update-test.yaml            # 滚动更新测试
│   ├── test-wechat-notification.yaml       # 微信通知测试
│   └── README.md                           # 示例说明
├── scripts/                         # 辅助脚本
│   ├── deploy-all.sh               # 一键部署脚本
│   ├── cleanup.sh                  # 清理脚本
│   └── diagnose.sh                 # 诊断脚本
└── docs/                           # 文档
    ├── USAGE.md                    # 使用指南
    ├── WECHAT_NOTIFICATION_SETUP.md # 微信通知设置
    ├── INTERACTIVE_DEPLOYMENT_GUIDE.md # 交互式部署指南
    ├── SANDBOX_REUSE_TEST_GUIDE.md # 沙箱复用测试指南
    └── ROLLING_UPDATE_TEST_GUIDE.md # 滚动更新测试指南
```

## 📊 测试指标说明

### 时间指标

- **Pod创建时间**: 从发出Deployment命令到Pod被创建的时间
- **沙箱初始化时间**: 从Pod创建到容器启动的时间（核心指标）
- **端到端时间**: 从发出命令到容器启动的总时间

### 性能指标

- **平均时间**: 多个Pod的平均启动时间
- **最小/最大时间**: 最快和最慢的Pod启动时间
- **沙箱复用率**: 复用沙箱的Pod占比
- **性能提升**: 沙箱复用相对于基准测试的性能提升百分比

### 典型测试结果

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

## 🛠️ 配置参数

### 部署参数

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

### 测试参数自定义

可以通过修改测试文件中的参数来自定义测试：

```yaml
arguments:
  parameters:
  - name: replicas
    value: "5"                    # Pod副本数
  - name: test-iterations
    value: "2"                    # 测试迭代次数
  - name: delay-between-tests
    value: "30s"                  # 测试间隔
  - name: pod-image
    value: "nginx:alpine"         # 测试镜像
  - name: cpu-request
    value: "100m"                 # CPU请求
  - name: memory-request
    value: "128Mi"                # 内存请求
```

### 企业微信集成

支持将测试结果自动推送到企业微信群：

```yaml
- name: webhook-url
  value: "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=YOUR_KEY"
```

## 🔧 使用指南

### 基础测试

运行基础的Pod部署测试：

```bash
kubectl apply -f examples/basic-deployment-test.yaml
```

### 性能测试

运行完整的性能对比测试：

```bash
kubectl apply -f examples/performance-test.yaml
```

### 沙箱复用测试

运行精确的沙箱复用性能测试：

```bash
kubectl apply -f examples/sandbox-reuse-precise-test.yaml
```

### 滚动更新测试

测试Pod滚动更新过程中的沙箱复用效果：

```bash
kubectl apply -f examples/rolling-update-test.yaml
```

### 企业微信通知

配置企业微信通知：

```bash
kubectl apply -f examples/test-wechat-notification.yaml
```

详细配置请参考 [企业微信通知设置指南](docs/WECHAT_NOTIFICATION_SETUP.md)

## 🛠️ 故障排除

### 常见问题

1. **Pod创建超时**
   - 检查超级节点状态：`kubectl get nodes -l node.kubernetes.io/instance-type=eklet`
   - 确认镜像可以正常拉取
   - 检查资源配额

2. **时间测量显示0.000秒**
   - 确保容器已启动完成
   - 检查kubectl权限
   - 验证时区设置

3. **沙箱复用率为0%**
   - 检查超级节点配置
   - 确认Pod规格一致
   - 验证调度策略
   - 检查测试间隔时间

### 调试工具

使用内置的诊断脚本：

```bash
# 检查系统状态
./scripts/diagnose.sh

# 清理测试资源
./scripts/cleanup.sh

# 一键部署所有模板
./scripts/deploy-all.sh
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

### 查看测试日志

```bash
# 查看工作流状态
kubectl get workflows -n argo

# 查看详细日志
kubectl logs -n argo <workflow-name>

# 查看Pod状态
kubectl get pods -n tke-chaos-test
```

## 🔍 技术特性

### 精确时间测量

- 使用kubectl直接获取Pod时间戳信息
- Python毫秒级时间计算
- 跨平台时区兼容性
- 多层时间戳解析策略

### 智能沙箱复用检测

- 基于容器启动时间差异判断
- 自动等待容器启动完成
- Events API备用时间源
- 详细的调试信息输出

### 企业级特性

- 完整的错误处理和重试机制
- 详细的测试报告和统计分析
- 企业微信集成通知
- 可扩展的模板架构

## 📚 文档

- [使用指南](docs/USAGE.md) - 详细的使用说明
- [企业微信通知设置](docs/WECHAT_NOTIFICATION_SETUP.md) - 微信通知配置
- [交互式部署指南](docs/INTERACTIVE_DEPLOYMENT_GUIDE.md) - 交互式部署
- [沙箱复用测试指南](docs/SANDBOX_REUSE_TEST_GUIDE.md) - 沙箱复用测试
- [滚动更新测试指南](docs/ROLLING_UPDATE_TEST_GUIDE.md) - 滚动更新沙箱复用测试

## 🤝 贡献指南

欢迎提交Issue和Pull Request来改进项目。

## 📄 许可证

本项目采用MIT许可证，详见LICENSE文件。