# TKE Chaos Playbook

腾讯云容器服务（TKE）超级节点沙箱复用性能测试工具。

## 🎯 项目概述

专门用于测试和验证腾讯云TKE超级节点的沙箱复用机制性能，通过自动化测试流程准确测量Pod启动时间，分析沙箱复用对性能的影响。

## ✨ 核心功能

- **🚀 沙箱复用测试**: 自动化测试沙箱复用机制的性能表现
- **⏱️ 精确时间测量**: 毫秒级精度的Pod创建和沙箱初始化时间测量
- **📊 性能对比分析**: 基准测试与沙箱复用测试的详细对比
- **🔄 滚动更新测试**: 测试Pod滚动更新过程中的沙箱复用效果
- **💬 企业微信通知**: 测试结果自动推送到企业微信群

## 🚀 快速开始

### 前置条件

- Kubernetes集群（推荐TKE）
- Argo Workflows已安装
- kubectl命令行工具
- 超级节点已配置

### 30秒快速部署

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

### 测试场景

```bash
# 基础功能验证
kubectl apply -f examples/basic-deployment-test.yaml

# 精确沙箱复用测试
kubectl apply -f examples/sandbox-reuse-precise-test.yaml

# 滚动更新测试
kubectl apply -f examples/rolling-update-test.yaml

# 性能对比测试
kubectl apply -f examples/performance-test.yaml
```

## 📁 项目结构

```
tke-chaos-playbook/
├── playbook/                        # 核心工作流
│   ├── template/                    # Argo Workflows模板
│   └── workflow/                    # 工作流定义
├── examples/                        # 测试示例
├── scripts/                         # 部署脚本
└── docs/                           # 文档
```

## 📊 测试指标

### 核心指标
- **沙箱初始化时间**: 从Pod创建到容器启动的时间（核心指标）
- **沙箱复用率**: 复用沙箱的Pod占比
- **性能提升**: 沙箱复用相对于基准测试的性能提升百分比

### 典型测试结果
```
📊 沙箱复用效果分析:
- 基准测试（首次创建）: 14.000秒
- 沙箱复用测试: 13.400秒
- 沙箱复用覆盖率: 60% (6/10个Pod)
- 性能提升: 4.3%
```

## 🛠️ 配置选项

### 部署参数
```bash
./scripts/deploy-all.sh [选项]
  -i, --iterations NUM    测试迭代次数 (默认: 2)
  -r, --replicas NUM      Pod副本数 (默认: 5)
  -w, --webhook URL       企业微信webhook地址
  -q, --quick             快速模式
  --interactive           交互式配置模式
```

### 企业微信通知
```bash
# 交互式配置（包含微信通知）
./scripts/deploy-all.sh --interactive

# 或直接指定webhook
./scripts/deploy-all.sh -w "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=YOUR_KEY"
```

## 🔧 测试场景详解

### 沙箱复用原理
- **沙箱保留**: Pod删除后，底层沙箱环境可能被保留一段时间
- **资源匹配**: 新Pod如果资源规格匹配，可以复用已有沙箱
- **启动加速**: 复用沙箱可以跳过部分初始化步骤，显著减少启动时间

### 滚动更新测试
测试采用两阶段对比方式：
1. **标准滚动更新（基准测试）**: 执行标准Kubernetes滚动更新
2. **沙箱复用测试**: 滚动更新完成后，创建临时Pod测试沙箱复用效果

### 复用判断标准
- **复用成功**: 沙箱初始化时间 < 20.0秒
- **复用效果显著**: 复用率 > 50%
- **复用效果一般**: 复用率 20%-50%

## 🛠️ 故障排除

### 常见问题
1. **Pod创建超时**: 检查超级节点状态和镜像拉取
2. **沙箱复用率为0%**: 检查Pod规格一致性和测试间隔时间
3. **时间测量异常**: 验证kubectl权限和时区设置

### 工具命令
```bash
# 诊断系统问题
./scripts/diagnose.sh

# 清理测试资源
./scripts/cleanup.sh quick

# 查看测试日志
kubectl logs -l workflows.argoproj.io/workflow -n tke-chaos-test
```

## 📚 文档

- [企业微信通知设置](docs/WECHAT_NOTIFICATION_SETUP.md) - 微信通知配置指南

## 🤝 贡献指南

欢迎提交Issue和Pull Request来改进项目。

## 📄 许可证

本项目采用MIT许可证，详见LICENSE文件。