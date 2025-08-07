# 🚀 TKE Chaos Playbook 快速开始指南

## 📋 前置条件

- ✅ Kubernetes集群（推荐TKE）
- ✅ kubectl命令行工具
- ✅ Argo Workflows已安装
- ✅ 超级节点已配置

## ⚡ 30秒快速部署

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

## 🎯 核心测试场景

### 1. 基础功能验证
```bash
kubectl apply -f examples/basic-deployment-test.yaml
```

### 2. 精确沙箱复用测试
```bash
kubectl apply -f examples/sandbox-reuse-precise-test.yaml
```

### 3. 滚动更新测试（新功能）
```bash
kubectl apply -f examples/rolling-update-test.yaml
```

### 4. 性能对比测试
```bash
kubectl apply -f examples/performance-test.yaml
```

## 📊 查看测试结果

```bash
# 监控测试进度
kubectl get workflows -n tke-chaos-test -w

# 查看详细日志
kubectl logs -l workflows.argoproj.io/workflow -n tke-chaos-test -f

# 查看Pod状态
kubectl get pods -n tke-chaos-test
```

## 🧹 清理资源

```bash
# 快速清理
./scripts/cleanup.sh quick

# 完全清理
./scripts/cleanup.sh full
```

## 💬 企业微信通知配置

```bash
# 交互式配置（包含微信通知）
./scripts/deploy-all.sh --interactive

# 或直接指定webhook
./scripts/deploy-all.sh -w "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=YOUR_KEY"
```

## 🔧 自定义配置

```bash
# 自定义Pod数量和资源
./scripts/deploy-all.sh -r 10 --cpu-request 200m --memory-request 256Mi

# 完全交互式配置
./scripts/deploy-all.sh --interactive
```

## 📚 更多文档

- [详细使用指南](docs/USAGE.md)
- [滚动更新测试指南](docs/ROLLING_UPDATE_TEST_GUIDE.md)
- [企业微信通知设置](docs/WECHAT_NOTIFICATION_SETUP.md)
- [交互式部署指南](docs/INTERACTIVE_DEPLOYMENT_GUIDE.md)

## 🆘 故障排除

```bash
# 检查项目状态
./scripts/check-project-status.sh

# 诊断系统问题
./scripts/diagnose.sh

# 查看帮助
./scripts/deploy-all.sh --help
```

## 🎉 典型测试结果

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

---

🎯 **开始你的第一个测试**: `./scripts/deploy-all.sh -q && kubectl apply -f examples/basic-deployment-test.yaml`