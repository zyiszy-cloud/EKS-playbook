# TKE Serverless 性能测试指南

## 概述

本指南提供了针对腾讯云TKE Serverless（弹性容器服务EKS）的性能测试方案，帮助您评估和优化Serverless容器的性能表现。

## TKE Serverless 特性

### 核心优势
- **无服务器管理**：无需管理节点，专注业务逻辑
- **秒级弹性**：Pod秒级启动，自动扩缩容
- **按需计费**：按Pod实际使用的CPU/内存计费
- **安全隔离**：每个Pod独立的安全沙箱环境
- **完全托管**：底层基础设施完全托管

### 适用场景
- 突发流量应用
- 批处理任务
- 微服务架构
- CI/CD流水线
- 事件驱动应用

## 性能测试场景

### 1. Pod启动性能测试

**测试目标**：验证不同规格Pod的启动速度和稳定性

**测试文件**：`workflow/serverless-pod-startup-performance.yaml`

**测试内容**：
- 小规格Pod (0.25C/0.5Gi) 启动性能
- 中规格Pod (1C/2Gi) 启动性能  
- 大规格Pod (2C/4Gi) 启动性能
- 不同镜像大小对启动时间的影响
- 批量Pod启动的并发性能

**关键指标**：
- Pod启动时间（从创建到Running状态）
- 启动成功率
- 并发启动能力
- 资源就绪时间

### 2. 弹性扩缩容性能测试

**测试目标**：验证HPA自动扩缩容的响应速度和稳定性

**测试文件**：`workflow/serverless-scaling-performance.yaml`

**测试内容**：
- CPU负载触发的自动扩容
- 负载降低后的自动缩容
- 扩缩容响应时间测量
- 扩缩容稳定性验证

**关键指标**：
- 扩容响应时间
- 缩容响应时间
- 扩缩容稳定性
- 资源利用率

### 3. 网络性能测试

**测试目标**：验证Serverless Pod的网络性能

**测试内容**：
- Pod间通信延迟
- Service负载均衡性能
- Ingress吞吐量测试
- 外网访问性能

**关键指标**：
- 网络延迟
- 吞吐量
- 连接建立时间
- 负载均衡效果

### 4. 存储性能测试

**测试目标**：验证存储I/O性能

**测试内容**：
- PVC挂载性能
- 不同存储类型的I/O测试
- 数据持久化验证

**关键指标**：
- 存储I/O延迟
- 读写吞吐量
- 存储挂载时间

## 测试执行步骤

### 前置准备

1. **准备TKE Serverless集群**
```bash
# 确保集群已启用Serverless节点池
# 在腾讯云TKE控制台创建或配置Serverless集群
```

2. **配置测试环境**
```bash
# 克隆项目
git clone https://github.com/tkestack/tke-chaos-playbook.git
cd tke-chaos-playbook

# 创建必要的ConfigMap
kubectl create ns tke-chaos-test
kubectl create -n tke-chaos-test configmap tke-chaos-precheck-resource --from-literal=empty=""

# 配置目标集群kubeconfig
kubectl create -n tke-chaos-test secret generic dest-cluster-kubeconfig --from-file=config=./your-serverless-cluster-kubeconfig

# 部署Argo Workflow
kubectl create -f playbook/install-argo.yaml
```

3. **验证环境**
```bash
# 检查Argo Workflow状态
kubectl get po -n tke-chaos-test

# 获取Argo UI访问token
kubectl exec -it -n tke-chaos-test deployment/tke-chaos-argo-workflows-server -- argo auth token
```

### 执行性能测试

#### 1. Pod启动性能测试

```bash
# 部署模板
kubectl create -f playbook/rbac.yaml
kubectl create -f playbook/all-in-one-template.yaml

# 执行Pod启动性能测试
kubectl create -f playbook/workflow/serverless-pod-startup-performance.yaml

# 监控测试进度
kubectl get workflow -n tke-chaos-test
kubectl logs -f -n tke-chaos-test workflow/serverless-pod-startup-performance
```

**参数配置**：
```yaml
# 可调整的关键参数
pod-count-small: "10"      # 小规格Pod数量
pod-count-medium: "5"      # 中规格Pod数量  
pod-count-large: "3"       # 大规格Pod数量
startup-timeout: "120s"    # Pod启动超时时间
test-duration: "300s"      # 测试持续时间
```

#### 2. 弹性扩缩容性能测试

```bash
# 执行扩缩容性能测试
kubectl create -f playbook/workflow/serverless-scaling-performance.yaml

# 监控HPA状态
kubectl get hpa -n tke-serverless-scaling-test -w

# 查看Pod扩缩容过程
kubectl get pods -n tke-serverless-scaling-test -w
```

**参数配置**：
```yaml
# 可调整的关键参数
initial-replicas: "2"      # 初始副本数
max-replicas: "20"         # 最大副本数
target-cpu-percent: "50"   # CPU目标使用率
load-duration: "300s"      # 负载持续时间
cooldown-duration: "180s"  # 冷却时间
```

### 测试结果分析

#### 1. 查看测试结果

```bash
# 通过Argo UI查看详细结果（推荐）
# 访问 LoadBalancer IP:2746

# 或通过命令行查看
kubectl describe workflow serverless-pod-startup-performance -n tke-chaos-test
kubectl describe workflow serverless-scaling-performance -n tke-chaos-test
```

#### 2. 性能指标分析

**Pod启动性能指标**：
- 小规格Pod：通常 < 10秒
- 中规格Pod：通常 < 15秒  
- 大规格Pod：通常 < 30秒
- 启动成功率：应 > 95%

**扩缩容性能指标**：
- 扩容响应时间：通常 < 60秒
- 缩容响应时间：通常 < 120秒
- 扩容稳定性：无频繁抖动

#### 3. 性能优化建议

**Pod启动优化**：
1. 使用轻量级基础镜像（如alpine）
2. 优化镜像层数和大小
3. 使用镜像预热功能
4. 合理设置资源请求和限制

**扩缩容优化**：
1. 调整HPA的CPU/内存阈值
2. 配置合适的扩缩容策略
3. 设置适当的冷却时间
4. 考虑使用VPA垂直扩缩容

**成本优化**：
1. 根据业务模式选择合适的Pod规格
2. 利用Spot实例降低成本
3. 优化资源利用率
4. 监控和分析成本趋势

## 故障排查

### 常见问题

1. **Pod启动失败**
```bash
# 检查Pod状态和事件
kubectl describe pod <pod-name> -n <namespace>
kubectl get events -n <namespace>

# 检查镜像拉取
kubectl logs <pod-name> -n <namespace>
```

2. **HPA不工作**
```bash
# 检查metrics-server
kubectl get pods -n kube-system | grep metrics-server

# 检查HPA状态
kubectl describe hpa <hpa-name> -n <namespace>

# 检查Pod资源使用
kubectl top pods -n <namespace>
```

3. **网络连接问题**
```bash
# 检查Service和Endpoints
kubectl get svc,ep -n <namespace>

# 测试Pod间连通性
kubectl exec -it <pod-name> -n <namespace> -- ping <target-ip>
```

### 性能调优

1. **资源配置优化**
```yaml
# 合理设置资源请求和限制
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

2. **HPA配置优化**
```yaml
# 配置扩缩容行为
behavior:
  scaleUp:
    stabilizationWindowSeconds: 30
    policies:
    - type: Percent
      value: 100
      periodSeconds: 15
  scaleDown:
    stabilizationWindowSeconds: 60
    policies:
    - type: Percent
      value: 50
      periodSeconds: 30
```

## 最佳实践

### 1. 测试策略
- 在非生产环境进行性能测试
- 模拟真实业务场景和流量模式
- 定期执行性能基准测试
- 建立性能监控和告警

### 2. 资源规划
- 根据业务需求选择合适的Pod规格
- 预估峰值流量和资源需求
- 设置合理的扩缩容策略
- 监控成本和资源利用率

### 3. 监控运维
- 配置完善的监控指标
- 设置关键性能告警
- 定期分析性能趋势
- 持续优化配置参数

## 总结

TKE Serverless为云原生应用提供了优秀的弹性和性能表现。通过系统的性能测试，您可以：

1. **了解性能基线**：建立应用的性能基准
2. **优化配置参数**：调整资源配置和扩缩容策略
3. **验证业务场景**：确保满足业务性能要求
4. **降低运营成本**：优化资源利用率和成本效益

建议定期执行性能测试，持续优化TKE Serverless的配置，以获得最佳的性能和成本效益。