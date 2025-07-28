# TKE 超级节点性能测试 Playbook 项目说明

[English](README.md) | [中文](README_zh.md)

## 项目概述

本项目是一套基于 Argo Workflows 的腾讯云 TKE 超级节点性能测试工具包，提供全面的性能基准测试、网络性能评估、镜像拉取测试和资源弹性验证功能。通过标准化的测试流程和精确的性能指标，帮助用户评估超级节点的性能表现，为业务部署决策提供数据支持。

## Pod 创建基准测试

**playbook**：`workflow/supernode-pod-benchmark.yaml`

该场景对超级节点进行 Pod 创建性能基准测试，主要流程包括：
- **环境预检**：检查集群健康状态，验证超级节点可用性，确保测试环境满足要求
- **节点发现**：自动发现集群中的所有超级节点，智能分配测试负载
- **并发创建**：根据配置并发或顺序创建指定数量的 Pod，实时监控创建状态
- **性能统计**：精确测量 Pod 创建时间，计算平均耗时、P99 延迟和成功率等关键指标
- **资源清理**：测试完成后自动清理所有测试资源

支持两种测试模式：`concurrent-creation`（并发创建）和 `sequential-creation`（顺序创建）。并发模式可以测试超级节点的并发处理能力，顺序模式可以获得更稳定的基线性能数据。

**参数说明**

| 参数名称 | 类型 | 默认值 | 说明 |
|---------|---------|------|--------|
| `target-pod-count` | `int` | `20` | 目标创建的 Pod 数量 |
| `benchmark-type` | `string` | `concurrent-creation` | 测试类型：`concurrent-creation`/`sequential-creation` |
| `supernode-selector` | `string` | `node.kubernetes.io/instance-type=eklet` | 超级节点选择器 |
| `kubeconfig-secret-name` | `string` | `dest-cluster-kubeconfig` | 目标集群 kubeconfig secret 名称 |
| `test-namespace` | `string` | `tke-supernode-benchmark` | 测试命名空间 |
| `pod-resource-cpu` | `string` | `100m` | Pod CPU 资源请求 |
| `pod-resource-memory` | `string` | `128Mi` | Pod 内存资源请求 |
| `timeout-seconds` | `int` | `300` | 测试超时时间（秒） |
| `batch-size` | `int` | `10` | 批量创建大小（仅用于并发模式） |

## 网络性能测试

**playbook**：`workflow/network-performance-test.yaml`

该场景测试超级节点间的网络性能，主要流程包括：
- **网络拓扑构建**：在不同超级节点上部署客户端和服务端 Pod
- **连通性测试**：验证 Pod 间网络连通性，确保测试环境正常
- **延迟测试**：测量 Pod 间通信的往返时延（RTT）
- **吞吐量测试**：测试网络带宽和数据传输能力
- **协议支持**：支持 TCP 和 UDP 协议的性能测试
- **结果分析**：生成详细的网络性能报告和优化建议

**参数说明**

| 参数名称 | 类型 | 默认值 | 说明 |
|---------|---------|------|--------|
| `test-type` | `string` | `latency` | 测试类型：`latency`/`throughput`/`all` |
| `protocol` | `string` | `tcp` | 网络协议：`tcp`/`udp` |
| `test-duration` | `string` | `60s` | 测试持续时间 |
| `packet-size` | `int` | `1024` | 数据包大小（字节） |
| `concurrent-connections` | `int` | `10` | 并发连接数 |
| `supernode-selector` | `string` | `node.kubernetes.io/instance-type=eklet` | 超级节点选择器 |
| `kubeconfig-secret-name` | `string` | `dest-cluster-kubeconfig` | 目标集群 kubeconfig secret 名称 |
| `server-port` | `int` | `8080` | 服务端监听端口 |

## 镜像拉取测试

**playbook**：`workflow/image-pull-test.yaml`

该场景测试超级节点的镜像拉取性能，主要流程包括：
- **镜像准备**：准备不同大小的测试镜像（小、中、大型镜像）
- **并发拉取**：并发拉取多个镜像，模拟实际业务场景
- **性能测量**：记录镜像拉取时间和成功率
- **缓存测试**：测试镜像缓存机制的效果
- **优化建议**：基于测试结果提供镜像拉取优化建议

**参数说明**

| 参数名称 | 类型 | 默认值 | 说明 |
|---------|---------|------|--------|
| `image-sizes` | `string` | `small,medium,large` | 测试镜像大小类型 |
| `concurrent-pulls` | `int` | `5` | 并发拉取数量 |
| `test-images` | `string` | `nginx:alpine,ubuntu:20.04,tensorflow/tensorflow:latest` | 测试镜像列表 |
| `supernode-selector` | `string` | `node.kubernetes.io/instance-type=eklet` | 超级节点选择器 |
| `kubeconfig-secret-name` | `string` | `dest-cluster-kubeconfig` | 目标集群 kubeconfig secret 名称 |
| `image-pull-policy` | `string` | `Always` | 镜像拉取策略 |
| `timeout-per-image` | `int` | `600` | 单个镜像拉取超时时间（秒） |

## 资源弹性测试

**playbook**：`workflow/resource-elasticity-test.yaml`

该场景测试超级节点的资源弹性扩展能力，主要流程包括：
- **基线测试**：建立资源使用基线
- **逐步加压**：逐步增加 Pod 数量和资源消耗
- **弹性监控**：监控节点资源使用率和 Pod 调度情况
- **极限测试**：测试资源超配情况下的性能表现
- **恢复验证**：验证资源释放后的恢复能力

**参数说明**

| 参数名称 | 类型 | 默认值 | 说明 |
|---------|---------|------|--------|
| `initial-pod-count` | `int` | `10` | 初始 Pod 数量 |
| `max-pod-count` | `int` | `100` | 最大 Pod 数量 |
| `increment-step` | `int` | `10` | 每次增加的 Pod 数量 |
| `step-duration` | `string` | `60s` | 每个步骤的持续时间 |
| `resource-stress-cpu` | `string` | `500m` | CPU 压力测试资源 |
| `resource-stress-memory` | `string` | `512Mi` | 内存压力测试资源 |
| `supernode-selector` | `string` | `node.kubernetes.io/instance-type=eklet` | 超级节点选择器 |
| `kubeconfig-secret-name` | `string` | `dest-cluster-kubeconfig` | 目标集群 kubeconfig secret 名称 |

## 超级节点综合演练

**playbook**：`workflow/supernode-scenario.yaml`

该场景提供超级节点的综合演练测试，支持多种演练场景：

### 演练场景类型

1. **调度压力测试 (schedule-pressure)**：批量创建 Pod 到超级节点，测试调度能力和承载能力
2. **资源限制测试 (resource-limit)**：创建高 CPU 和内存消耗的 Pod，测试资源管理能力
3. **故障模拟测试 (failure-simulation)**：创建会失败的 Pod，测试异常处理能力

**参数说明**

| 参数名称 | 类型 | 默认值 | 说明 |
|---------|---------|------|--------|
| `scenario-type` | `string` | `schedule-pressure` | 演练场景类型 |
| `supernode-selector` | `string` | `node.kubernetes.io/instance-type=eklet` | 超级节点选择器 |
| `test-duration` | `string` | `60s` | 测试持续时间 |
| `test-pod-count` | `int` | `10` | 测试 Pod 数量 |
| `kubeconfig-secret-name` | `string` | `dest-cluster-kubeconfig` | 目标集群 kubeconfig secret 名称 |

## 项目结构

```
tke-chaos-playbook/
├── playbook/                    # 核心测试组件
│   ├── template/               # 工作流模板
│   │   ├── supernode-pod-benchmark-template.yaml  # Pod 创建基准测试模板
│   │   ├── network-performance-template.yaml      # 网络性能测试模板
│   │   ├── image-pull-template.yaml              # 镜像拉取测试模板
│   │   ├── resource-elasticity-template.yaml     # 资源弹性测试模板
│   │   ├── supernode-template.yaml               # 超级节点综合测试模板
│   │   ├── kubectl-cmd-template.yaml             # kubectl 命令执行模板
│   │   └── precheck-template.yaml                # 预检查模板
│   ├── workflow/               # 测试场景定义
│   │   ├── supernode-pod-benchmark.yaml          # Pod 创建基准测试工作流
│   │   ├── network-performance-test.yaml         # 网络性能测试工作流
│   │   ├── image-pull-test.yaml                  # 镜像拉取测试工作流
│   │   ├── resource-elasticity-test.yaml         # 资源弹性测试工作流
│   │   └── supernode-scenario.yaml               # 超级节点综合演练工作流
│   ├── scripts/                # 自动化脚本
│   │   ├── deploy-all-templates.sh               # 部署所有模板
│   │   ├── deploy-supernode-benchmark.sh         # 部署基准测试环境
│   │   ├── test-network-performance.sh           # 网络性能测试脚本
│   │   ├── validate-project.sh                   # 项目验证脚本
│   │   └── validate-supernode-allocation.sh      # 超级节点分配验证脚本
│   ├── config/                 # 配置文件
│   │   ├── supernode-config.yaml                 # 超级节点配置
│   │   ├── network-test-config.yaml              # 网络测试配置
│   │   └── performance-thresholds.yaml           # 性能阈值配置
│   ├── install-argo.yaml      # Argo Workflows 安装配置
│   ├── rbac.yaml              # RBAC 权限配置
│   └── README_zh.md           # 项目说明文档（中文）
├── README.md                   # 项目主文档（英文）
├── read.md                     # 演练场景说明文档
└── LICENSE                     # 许可证文件
```

## 快速开始

### 环境准备

1. **腾讯云 TKE 集群**：已创建并配置好的 TKE 集群，包含至少一个超级节点
2. **kubectl**：已安装并配置好访问 TKE 集群的权限
3. **Shell 环境**：支持 bash 的终端环境 (Linux/MacOS)
4. **网络访问**：能够访问腾讯云容器服务和镜像仓库

### 安装部署

```bash
# 1. 克隆项目
git clone <repository-url>
cd tke-chaos-playbook

# 2. 安装 Argo Workflows
kubectl apply -f playbook/install-argo.yaml
kubectl apply -f playbook/rbac.yaml

# 3. 部署测试模板
./playbook/scripts/deploy-supernode-benchmark.sh

# 4. 验证安装
./playbook/scripts/validate-project.sh
```

### 运行测试

```bash
# Pod 创建基准测试
kubectl apply -f playbook/workflow/supernode-pod-benchmark.yaml

# 网络性能测试
kubectl apply -f playbook/workflow/network-performance-test.yaml

# 镜像拉取测试
kubectl apply -f playbook/workflow/image-pull-test.yaml

# 资源弹性测试
kubectl apply -f playbook/workflow/resource-elasticity-test.yaml

# 超级节点综合演练
kubectl apply -f playbook/workflow/supernode-scenario.yaml
```

### 查看测试结果

```bash
# 查看工作流状态
kubectl get workflows -n tke-chaos-test

# 查看测试日志
kubectl logs -n tke-chaos-test -l workflows.argoproj.io/workflow=<workflow-name> -f

# 查看详细结果
kubectl describe workflow <workflow-name> -n tke-chaos-test
```

## 性能指标说明

### 关键指标

- **Pod 创建时间**：从 Pod 创建到 Running 状态的时间
- **端到端时间**：从 Pod 创建到 Ready 状态的完整时间
- **P99 延迟**：99% 的操作延迟小于此值
- **成功率**：成功完成操作的百分比
- **网络延迟**：Pod 间通信的往返时延（RTT）
- **网络吞吐量**：网络数据传输速率
- **镜像拉取时间**：镜像下载完成时间
- **资源利用率**：CPU 和内存资源使用情况

### 性能基准

**优秀级别**：
- Pod 创建 P99 < 10s，成功率 > 95%
- 网络延迟 < 1ms，吞吐量 > 1Gbps
- 镜像拉取 P99 < 30s

**良好级别**：
- Pod 创建 P99 < 20s，成功率 > 90%
- 网络延迟 < 5ms，吞吐量 > 500Mbps
- 镜像拉取 P99 < 60s

**需要优化**：
- Pod 创建 P99 > 30s，成功率 < 85%
- 网络延迟 > 10ms，吞吐量 < 100Mbps
- 镜像拉取 P99 > 120s

## 配置说明

### 超级节点配置

修改 `playbook/config/supernode-config.yaml` 文件：

```yaml
# 超级节点选择器
supernodes:
  auto_discovery: true
  selector: "node.kubernetes.io/instance-type=eklet"

# Pod 资源配置
pod_config:
  resources:
    requests:
      cpu: "100m"
      memory: "128Mi"
    limits:
      cpu: "200m"
      memory: "256Mi"
```

### 测试参数配置

修改工作流文件中的参数：

```yaml
# playbook/workflow/supernode-pod-benchmark.yaml
arguments:
  parameters:
  - name: target-pod-count
    value: "50"  # 增加 Pod 数量
  - name: benchmark-type
    value: "concurrent-creation"  # 选择测试类型
```

## 故障排除

### 常见问题

1. **模板未找到**
   ```bash
   # 解决方案：重新部署模板
   ./playbook/scripts/deploy-all-templates.sh
   ```

2. **Pod 创建失败**
   ```bash
   # 检查超级节点状态
   kubectl get nodes -l node.kubernetes.io/instance-type=eklet
   
   # 检查资源配额
   kubectl describe quota -n tke-supernode-benchmark
   ```

3. **网络测试失败**
   ```bash
   # 检查网络策略
   kubectl get networkpolicies -n tke-supernode-benchmark
   
   # 检查服务状态
   kubectl get svc -n tke-supernode-benchmark
   ```

4. **权限问题**
   ```bash
   # 检查 RBAC 配置
   kubectl get clusterrolebinding | grep tke-chaos
   
   # 重新应用权限配置
   kubectl apply -f playbook/rbac.yaml
   ```

### 调试命令

```bash
# 查看 Pod 详细信息
kubectl describe pod <pod-name> -n tke-supernode-benchmark

# 查看节点资源使用情况
kubectl top nodes -l node.kubernetes.io/instance-type=eklet

# 查看工作流执行详情
kubectl get workflow <workflow-name> -n tke-chaos-test -o yaml

# 监控测试进度
kubectl get pods -n tke-supernode-benchmark -w
```

## 最佳实践

### 测试建议

1. **分阶段测试**：先进行小规模功能验证，再进行大规模性能测试
2. **基线建立**：在业务低峰期建立性能基线，作为后续对比参考
3. **定期监控**：定期执行性能测试，监控超级节点性能变化趋势
4. **环境隔离**：在专用测试环境中进行压力测试，避免影响生产业务

### 优化建议

1. **资源配置优化**：根据测试结果调整 Pod 资源请求和限制
2. **镜像优化**：使用镜像缓存和本地镜像仓库提升拉取速度
3. **网络优化**：配置合适的网络插件和策略提升网络性能
4. **监控告警**：建立性能监控和告警机制，及时发现性能问题

## 清理资源

```bash
# 删除测试工作流
kubectl delete workflow --all -n tke-chaos-test

# 清理测试命名空间
kubectl delete namespace tke-supernode-benchmark --ignore-not-found=true
kubectl delete namespace tke-supernode-test --ignore-not-found=true

# 清理模板（可选）
kubectl delete clusterworkflowtemplate --all
```

## 注意事项

1. **资源消耗**：大规模测试会消耗较多集群资源，请合理规划测试规模
2. **网络影响**：网络性能测试可能对集群网络产生一定影响
3. **成本控制**：超级节点按使用量计费，请注意控制测试成本
4. **安全考虑**：测试过程中会创建大量资源，确保测试环境安全隔离
5. **版本兼容**：确保 Argo Workflows 版本与 Kubernetes 集群版本兼容

---

**项目状态**：生产就绪 ✅  
**技术支持**：已在实际 TKE 环境中验证  
**持续改进**：与 TKE 超级节点最新特性保持同步