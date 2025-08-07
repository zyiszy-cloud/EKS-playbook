# 超级节点沙箱复用测试指南

## 🎯 测试目标

本指南旨在帮助用户全面测试和验证腾讯云TKE超级节点的Pod沙箱复用功能，确保在Pod重建时能够有效复用沙箱资源，提升启动性能。

## 🔍 沙箱复用原理

### 什么是沙箱复用？
- **沙箱保留**: Pod删除后，底层沙箱环境可能被保留一段时间
- **资源匹配**: 新Pod如果资源规格匹配，可以复用已有沙箱
- **启动加速**: 复用沙箱可以跳过部分初始化步骤，显著减少启动时间

### 复用条件
1. **节点相同**: 新Pod调度到相同的超级节点
2. **资源匹配**: CPU、内存等资源规格相同或兼容
3. **时间窗口**: 在沙箱保留期内创建新Pod
4. **镜像相同**: 使用相同的容器镜像

## 🧪 测试场景

### Deployment沙箱复用测试
**文件**: `playbook/workflow/supernode-sandbox-deployment-scenario.yaml`

**测试流程**:
1. 创建Deployment
2. 等待Pod就绪
3. 删除Deployment
4. 重新创建相同Deployment
5. 分析启动时间变化

**适用场景**:
- 模拟生产环境使用方式
- 测试滚动更新场景
- 验证自动化管理下的复用效果
- 完整的资源生命周期管理

## 📊 结果分析

### 关键指标

#### 1. 启动时间对比
```
第1次启动: 15秒 (首次创建沙箱)
第2次启动: 8秒  (复用沙箱)
第3次启动: 9秒  (复用沙箱)
```

#### 2. 性能提升计算
```
性能提升 = (首次启动时间 - 后续平均时间) / 首次启动时间 × 100%
示例: (15 - 8.5) / 15 × 100% = 43.3%
```

#### 3. 复用效果评级
- **显著**: 性能提升 ≥ 30% 且绝对提升 ≥ 5秒
- **明显**: 性能提升 ≥ 15% 且绝对提升 ≥ 2秒
- **轻微**: 性能提升 < 15% 或绝对提升 < 2秒
- **无效**: 无性能提升或性能下降

### 节点分布分析
```
节点分布:
- node-1: 3次 (60% 复用率)
- node-2: 2次 (50% 复用率)
```

## 🛠️ 测试配置

### 基础配置参数
```yaml
# 测试迭代次数
test-iterations: "5"

# Pod资源配置
cpu-request: "100m"
memory-request: "128Mi"
cpu-limit: "200m"
memory-limit: "256Mi"

# 测试间隔
delay-between-tests: "30s"
```

### 高级配置选项
```yaml
# 超时设置
wait-pod-ready-timeout: "300s"

# 镜像选择
pod-image: "nginx:alpine"  # 轻量级镜像，启动快

# 企业微信通知
webhook-url: "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=YOUR_KEY"
```

## 🚀 快速开始

### 1. 环境准备
```bash
# 检查环境
./scripts/test-local-env.sh

# 一键部署
./scripts/deploy-all.sh -q
```

### 2. 运行测试
```bash
# Deployment测试（推荐且唯一支持的模式）
kubectl apply -f playbook/workflow/supernode-sandbox-deployment-scenario.yaml
```

### 3. 监控结果
```bash
# 查看工作流状态
kubectl get workflows -n tke-chaos-test -w

# 查看详细日志
kubectl logs -l workflows.argoproj.io/workflow -n tke-chaos-test -f
```

## 🔧 故障排查

### 常见问题

#### 1. 未检测到沙箱复用
**可能原因**:
- 沙箱保留时间过短
- 资源规格不匹配
- 节点调度到不同超级节点
- 镜像拉取时间影响

**解决方案**:
- 减少测试间隔时间
- 确保资源配置一致
- 使用nodeName固定节点
- 预拉取镜像

#### 2. Pod启动失败
**可能原因**:
- 超级节点资源不足
- 镜像拉取失败
- 网络连接问题

**解决方案**:
```bash
# 检查超级节点状态
kubectl get nodes -l "node.kubernetes.io/instance-type=eklet"

# 检查Pod事件
kubectl describe pod <pod-name> -n tke-chaos-test

# 检查镜像
kubectl get pods -n tke-chaos-test -o jsonpath='{.items[*].spec.containers[*].image}'
```

#### 3. 性能提升不明显
**可能原因**:
- 网络延迟影响
- 镜像已缓存
- 测试环境负载高

**优化建议**:
- 增加测试迭代次数
- 使用更大的镜像
- 在低负载时段测试

## 📈 最佳实践

### 1. 测试环境
- 使用专用测试集群
- 确保超级节点资源充足
- 避免其他工作负载干扰

### 2. 测试配置
- 使用轻量级镜像（如nginx:alpine）
- 设置合理的资源限制
- 配置适当的测试间隔

### 3. 结果分析
- 多次测试取平均值
- 关注绝对时间和相对提升
- 分析节点分布和复用率

### 4. 生产应用
- 根据测试结果调整部署策略
- 优化Pod资源配置
- 监控实际复用效果

## 📋 测试报告模板

```markdown
# 沙箱复用测试报告

## 测试环境
- 集群: tke-cluster-prod
- 超级节点数量: 3
- 测试时间: 2024-01-01 10:00:00

## 测试配置
- 测试类型: 单Pod沙箱复用
- 迭代次数: 5
- Pod镜像: nginx:alpine
- 资源配置: CPU=200m, Memory=256Mi

## 测试结果
- 总测试次数: 5
- 成功次数: 5
- 成功率: 100%
- 平均启动时间: 12秒

## 沙箱复用分析
- 首次启动: 18秒
- 后续平均: 10秒
- 性能提升: 8秒 (44.4%)
- 复用效果: 显著

## 结论
沙箱复用功能正常，性能提升显著，建议在生产环境启用。
```

## 🔗 相关文档
- [项目README](README.md)
- [使用指南](USAGE.md)
- [故障排查](USAGE_SIMPLE.md)
- [项目状态](PROJECT_STATUS.md)