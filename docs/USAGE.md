# 超级节点Pod沙箱复用测试使用指南

## 🚀 快速开始

### 方法1：一键部署（推荐）
```bash
# 快速部署所有模板并选择工作流
./scripts/deploy-all.sh
```

### 方法2：超快速部署
```bash
# 最简洁的部署方式
./scripts/deploy-all.sh -q
```

### 方法3：完整部署（功能最全）
```bash
# 功能最完整的部署脚本
./scripts/deploy-all.sh -i 5 -w "webhook-url"
```

## 📋 工作流说明

| 工作流名称 | 功能描述 | 适用场景 |
|-----------|----------|----------|
| `supernode-sandbox-deployment-scenario` | Deployment沙箱复用测试 | 使用Deployment验证沙箱复用效果 |

## 🛠️ 手动操作

### 部署模板
```bash
# 部署所有模板
kubectl apply -f playbook/template/

# 部署RBAC权限
kubectl apply -f playbook/rbac.yaml

# 创建前置资源
kubectl create namespace tke-chaos-test
kubectl create -n tke-chaos-test configmap tke-chaos-precheck-resource --from-literal=empty=""
```

### 启动工作流
```bash
# 启动Deployment测试
kubectl create -f playbook/workflow/supernode-sandbox-deployment-scenario.yaml
```

## 📊 监控和查看

### 查看工作流状态
```bash
# 查看所有工作流
kubectl get workflows -n tke-chaos-test

# 查看特定工作流详情
kubectl describe workflow <workflow-name> -n tke-chaos-test

# 实时监控工作流状态
kubectl get workflow <workflow-name> -n tke-chaos-test -w
```

### 查看Pod状态
```bash
# 查看所有Pod
kubectl get pods -n tke-chaos-test

# 查看Pod详情
kubectl describe pod <pod-name> -n tke-chaos-test

# 查看Pod日志
kubectl logs <pod-name> -n tke-chaos-test -f
```

### 查看测试结果
```bash
# 查看工作流日志
kubectl logs -l workflows.argoproj.io/workflow=<workflow-name> -n tke-chaos-test

# 查看最新的测试Pod日志
kubectl logs -l app=sandbox-reuse-test -n tke-chaos-test --tail=100
```

## 🔧 故障排查

### 运行故障排查脚本
```bash
# 环境检查
./scripts/test-local-env.sh

# 全面的故障排查
./scripts/cleanup.sh
```

### 常见问题

#### 1. Pod初始化失败
- 检查镜像是否可以拉取
- 检查节点资源是否充足
- 检查超级节点是否存在

#### 2. 工作流卡住
- 检查依赖模板是否部署
- 检查RBAC权限是否正确
- 检查前置检查资源是否存在

#### 3. 找不到超级节点
```bash
# 检查超级节点
kubectl get nodes -l "node.kubernetes.io/instance-type=eklet"

# 查看所有节点标签
kubectl get nodes --show-labels
```

## 🧹 清理资源

### 清理工作流
```bash
# 删除所有工作流
kubectl delete workflows --all -n tke-chaos-test

# 删除特定工作流
kubectl delete workflow <workflow-name> -n tke-chaos-test
```

### 清理Pod
```bash
# 删除所有测试Pod
kubectl delete pods -l app=sandbox-reuse-test -n tke-chaos-test --force --grace-period=0

# 删除所有Pod
kubectl delete pods --all -n tke-chaos-test --force --grace-period=0
```

### 完全清理
```bash
# 使用清理脚本（推荐）
./scripts/cleanup.sh full

# 或手动删除整个命名空间（谨慎使用）
kubectl delete namespace tke-chaos-test
```

## 📈 测试结果分析

### 关键指标
- **首次启动时间**：第一个Pod的启动时间（基准）
- **后续启动时间**：复用沙箱的Pod启动时间
- **平均启动时间**：所有Pod的平均启动时间
- **性能提升比例**：沙箱复用带来的性能提升百分比

### 结果解读
- 如果后续启动时间明显小于首次启动时间，说明沙箱复用生效
- 性能提升比例通常在10-50%之间
- 如果没有性能提升，可能是沙箱复用未启用或配置问题

## 🔗 相关文档
- [项目README](README.md)
- [中文指南](README_zh.md)
- [简化指南](USAGE_SIMPLE.md)