# Pod滚动更新沙箱复用测试指南

## 🎯 测试目标

本测试专门用于验证TKE超级节点在Pod滚动更新过程中的沙箱复用效果。通过多次滚动更新操作，分析沙箱复用机制在实际生产场景中的表现。

## 🔄 测试原理

### 测试场景设计
本测试采用两阶段对比方式：

**阶段1：标准滚动更新（基准测试）**
1. 执行标准Kubernetes滚动更新（先创建新Pod，再删除旧Pod）
2. 分析滚动更新新Pod的沙箱初始化时间作为基准数据

**阶段2：沙箱复用测试**
1. 滚动更新完成后，创建临时Deployment使用旧配置
2. 这些Pod尝试复用滚动更新后释放的沙箱资源
3. 分析沙箱复用测试Pod的沙箱初始化时间

### 沙箱复用优势
- **资源效率**: 避免重复创建沙箱环境
- **启动速度**: 复用现有沙箱可显著减少Pod启动时间
- **成本优化**: 减少计算资源消耗
- **真实场景**: 模拟实际生产环境中的滚动更新过程

## 📊 测试指标

### 核心指标
- **滚动更新时间**: 每次滚动更新的完成时间
- **沙箱初始化时间**: 新Pod的沙箱初始化耗时
- **沙箱复用率**: 复用沙箱的Pod占比
- **总体复用效果**: 整个测试过程的复用统计

### 判断标准
- **复用成功**: 沙箱初始化时间 < 20.0秒
- **复用效果显著**: 复用率 > 50%
- **复用效果一般**: 复用率 20%-50%
- **复用效果不明显**: 复用率 < 20%

## 🚀 快速开始

### 1. 部署测试模板
```bash
kubectl apply -f playbook/template/supernode-rolling-update-template.yaml
```

### 2. 运行测试
```bash
kubectl apply -f examples/rolling-update-test.yaml
```

### 3. 监控测试进度
```bash
# 查看工作流状态
kubectl get workflows -n argo -w

# 查看详细日志
kubectl logs -f <workflow-pod-name> -n argo
```

## ⚙️ 配置参数

### 基础配置
```yaml
parameters:
- name: deployment-name
  value: "rolling-update-test"      # Deployment名称
- name: replicas
  value: "5"                       # Pod副本数（建议3-5个）
- name: update-iterations
  value: "4"                       # 滚动更新次数
- name: delay-between-updates
  value: "45s"                     # 更新间隔
```

### 镜像配置
```yaml
parameters:
- name: initial-image
  value: "nginx:1.20-alpine"       # 初始镜像版本
- name: updated-image
  value: "nginx:1.21-alpine"       # 更新目标镜像
```

### 资源配置
```yaml
parameters:
- name: cpu-request
  value: "100m"                    # CPU请求
- name: memory-request
  value: "128Mi"                   # 内存请求
- name: cpu-limit
  value: "200m"                    # CPU限制
- name: memory-limit
  value: "256Mi"                   # 内存限制
```

## 📈 测试结果解读

### 典型输出示例
```
📊 滚动更新沙箱复用测试总结
======================================
📋 测试配置:
- Pod副本数: 5个
- 更新次数: 4次
- 总Pod创建次数: 40次 (20次基准测试 + 20次沙箱复用测试)

📝 测试说明:
- 滚动更新：使用标准策略（先创建新Pod，再删除旧Pod）
- 沙箱复用测试：滚动更新完成后，创建使用旧配置的Pod测试沙箱复用
- 对比分析：滚动更新新Pod时间 vs 沙箱复用测试Pod时间
- 复用判断标准：沙箱初始化时间 < 20.0秒

🔄 滚动更新性能分析:
- 平均更新时间: 45.2秒
- 最快更新时间: 38.1秒
- 最慢更新时间: 52.3秒
- 总更新次数: 4次

📊 沙箱复用效果分析:
- 基准测试（滚动更新新Pod平均）: 15.8秒
- 沙箱复用测试（复用测试Pod平均）: 4.2秒
- ⚡ 性能提升: 11.6秒 (73%)
- 沙箱复用覆盖率: 85.0% (17/20次Pod创建)
- 复用检测阈值: 20.0秒

✅ 结论: 滚动更新过程中沙箱复用效果显著
```

### 结果分析
1. **复用率 > 50%**: 沙箱复用机制工作良好
2. **更新时间稳定**: 滚动更新性能一致
3. **阈值合理**: 20秒阈值为标准沙箱复用检测阈值

## 🔧 高级配置

### 自定义更新策略
```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 1              # 最大不可用Pod数
    maxSurge: 1                    # 最大超出Pod数
```

### 企业微信通知
```yaml
parameters:
- name: webhook-url
  value: "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=YOUR_KEY"
```

## 🛠️ 故障排除

### 常见问题

1. **滚动更新失败**
   - 检查镜像是否可用
   - 验证资源配额
   - 确认网络连接

2. **复用率为0%**
   - 增加更新间隔时间
   - 检查Pod资源规格一致性
   - 验证超级节点配置

3. **更新时间过长**
   - 检查镜像拉取速度
   - 验证节点资源状况
   - 调整资源限制

### 调试命令
```bash
# 查看Deployment状态
kubectl get deployment -n tke-chaos-test

# 查看Pod详情
kubectl describe pods -n tke-chaos-test

# 查看滚动更新历史
kubectl rollout history deployment/rolling-update-test -n tke-chaos-test
```

## 📚 相关文档

- [项目README](../README.md)
- [基础使用指南](USAGE.md)
- [沙箱复用测试指南](SANDBOX_REUSE_TEST_GUIDE.md)
- [企业微信通知设置](WECHAT_NOTIFICATION_SETUP.md)

## 🎯 最佳实践

1. **合理设置副本数**: 建议3-5个Pod以获得统计意义
2. **适当的更新间隔**: 45-60秒确保沙箱有时间被复用
3. **一致的资源配置**: 保持CPU/内存配置一致
4. **选择合适的镜像**: 使用相似大小的镜像版本
5. **监控测试过程**: 实时观察滚动更新进度

通过滚动更新测试，您可以全面了解TKE超级节点在实际生产场景中的沙箱复用表现！