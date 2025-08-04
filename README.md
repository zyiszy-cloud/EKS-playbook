# TKE Chaos Playbook

基于Argo Workflows的腾讯云TKE超级节点沙箱复用测试平台。

## 🚀 快速开始

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
./scripts/deploy-all.sh -i 5 -r 2 -w "YOUR_WEBHOOK_URL"
```

### 启动测试
```bash
# Deployment测试（推荐且唯一支持的模式）
kubectl apply -f playbook/workflow/supernode-sandbox-deployment-scenario.yaml
```

### 查看结果
```bash
# 监控测试状态
kubectl get workflows -n tke-chaos-test -w

# 查看详细日志
kubectl logs -l workflows.argoproj.io/workflow -n tke-chaos-test
```



## 📋 核心功能

| 功能 | 描述 | 文件 | 模式 |
|---|---|---|---|
| **Deployment测试** | 使用Deployment进行沙箱复用测试 | `supernode-sandbox-deployment-scenario.yaml` | **推荐** |
| **企业微信通知** | 测试结果自动发送到微信群 | 支持webhook配置 | 所有模式 |

## 🛠️ 配置参数

### 部署参数
```bash
./scripts/deploy-all.sh [选项]
  -i, --iterations NUM    测试迭代次数 (1-20, 默认: 1)
  -r, --replicas NUM      Deployment副本数 (默认: 1)
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
# 一键清理
./scripts/cleanup.sh quick

# 完全清理
./scripts/cleanup.sh full

# 交互式清理
./scripts/cleanup.sh
```

## 📊 Deployment模式特性

| 特性 | 说明 |
|---|---|
| **资源管理** | 自动管理Pod生命周期 |
| **故障恢复** | 自动重启失败的Pod |
| **滚动更新** | 支持无缝更新 |
| **健康检查** | 自动健康检查和恢复 |
| **资源清理** | 自动清理相关资源 |
| **测试精度** | 高精度的沙箱复用测试 |
| **生产友好** | 完全适用于生产环境 |

## 📊 结果解读

### 关键指标
- **首次启动时间**: 创建沙箱的基准时间
- **后续启动时间**: 复用沙箱的优化时间
- **性能提升**: (首次-后续)/首次 × 100%

### 成功标准
- 后续启动时间 < 首次启动时间
- 性能提升 > 10%
- 所有Pod成功启动

## 🔗 核心文件

- **部署脚本**: `scripts/deploy-all.sh`
- **清理脚本**: `scripts/cleanup.sh`
- **测试模板**: `playbook/template/`
- **工作流**: `playbook/workflow/`
- **权限配置**: `playbook/rbac.yaml`

## 📖 详细文档

- [中文指南](README_zh.md)
- [使用说明](USAGE.md)
- [沙箱复用测试指南](SANDBOX_REUSE_TEST_GUIDE.md)
- [交互式部署指南](INTERACTIVE_DEPLOYMENT_GUIDE.md)
- [企业微信通知配置](WECHAT_NOTIFICATION_SETUP.md)