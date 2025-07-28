# TKE SuperNode Testing Toolkit

## 🔍 项目背景

随着云计算技术的发展，容器化部署已成为主流。腾讯云 TKE (Tencent Kubernetes Engine) 超级节点是一种新型计算资源，提供了更高密度的 Pod 部署能力和更优的资源利用率。

本项目旨在提供一套全面的性能测试工具包，帮助用户评估 TKE 超级节点的性能表现，包括 Pod 创建速度、网络性能、镜像拉取效率和资源弹性等关键指标，为业务部署决策提供数据支持。

## 📋 环境前提

1. **腾讯云 TKE 集群**：已创建并配置好的 TKE 集群，包含至少一个超级节点
2. **kubectl**：已安装并配置好访问 TKE 集群的权限
3. **Argo Workflows**：将通过本项目脚本自动安装
4. **Shell 环境**：支持 bash 的终端环境 (Linux/MacOS)
5. **网络访问**：能够访问腾讯云容器服务和 Docker Hub 等镜像仓库

## 🎯 核心功能

- **Pod 创建基准测试**: 并发和顺序 Pod 创建性能评估
- **网络性能测试**: Pod间通信延迟和吞吐量测试

- **镜像拉取测试**: 不同大小镜像的拉取性能分析
- **资源弹性测试**: 资源动态调整测试
- **智能节点分配**: 自动发现超级节点并均匀分布测试负载

## ✨ 特性

- **零依赖设计**: 纯Shell实现，无需外部工具
- **精确测量**: 毫秒级精度的性能计时
- **专业统计**: P99延迟、成功率等关键指标
- **自动化流程**: 一键部署，自动清理
- **智能分配**: 测试负载均匀分布到所有超级节点

## 💡 功能实现

### Pod 创建基准测试
通过 Argo Workflows 并行创建多个 Pod，并记录从创建到 Running 和 Ready 状态的时间。实现逻辑：
1. 自动发现集群中的所有超级节点
2. 根据节点数量均匀分配 Pod 创建任务
3. 并发或顺序创建指定数量的 Pod
4. 实时监控 Pod 状态并记录时间戳
5. 计算平均耗时、P99 延迟和成功率等指标

### 网络性能测试
通过在不同 Pod 之间发送测试流量，评估网络延迟和吞吐量。实现逻辑：
1. 在超级节点上部署客户端和服务端 Pod
2. 服务端监听指定端口，客户端发送测试流量
3. 支持 TCP 和 UDP 协议测试
4. 测量延迟（RTT）和吞吐量（带宽）
5. 生成网络性能报告

### 镜像拉取测试
测试不同大小镜像的拉取速度，评估容器启动性能。实现逻辑：
1. 准备不同大小的测试镜像（小、中、大）
2. 并发拉取镜像并记录时间
3. 分析拉取时间分布和影响因素
4. 提供镜像拉取优化建议

### 资源弹性测试
测试超级节点在资源紧张情况下的弹性扩展能力。实现逻辑：
1. 逐步增加 Pod 数量，直到达到资源限制
2. 监控节点资源使用率和 Pod 状态
3. 测试资源超配情况下的性能表现
4. 评估节点的资源调度效率

## 🚀 快速开始

### 安装
```bash
# 1. 克隆项目
git clone <repository-url>
cd tke-chaos-playbook

# 2. 安装 Argo Workflows
kubectl apply -f playbook/install-argo.yaml
kubectl apply -f playbook/rbac.yaml

# 3. 一键部署测试模板
./scripts/deploy-supernode-benchmark.sh
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

# 查看测试结果
kubectl logs -n tke-chaos-test -l workflows.argoproj.io/workflow=<workflow-name> -f
```

### 查看测试结果

测试完成后，可以通过以下方式查看和分析测试结果：

```bash
# 1. 查看工作流执行状态
kubectl get workflows -n tke-chaos-test

# 2. 查看详细测试日志
kubectl logs -n tke-chaos-test -l workflows.argoproj.io/workflow=<workflow-name> -f

# 3. 验证项目配置
./scripts/validate-project.sh
```

#### 测试结果解读

测试日志会输出详细的性能指标，以下是关键指标的解释：

- **总创建数**: 尝试创建的Pod总数
- **成功运行**: 成功达到Running状态的Pod数量
- **成功率**: 成功运行的Pod占总创建数的百分比
- **平均耗时**: 所有Pod创建的平均时间
- **P99耗时**: 99%的Pod创建时间小于此值
- **端到端耗时**: 从Pod创建到Ready状态的完整时间

#### 导出测试结果

可以将测试结果导出到文件中进行进一步分析：

```bash
# 导出日志到文件
kubectl logs -n tke-chaos-test -l workflows.argoproj.io/workflow=<workflow-name> > test-results.log

# 提取关键指标
grep -E '成功率|平均耗时|P99耗时' test-results.log > key-metrics.txt
```

#### 性能优化建议

根据测试结果，可以考虑以下优化方向：

1. **高P99延迟**: 检查节点资源使用情况，考虑增加节点数量或优化容器资源配置
2. **低成功率**: 检查资源配额和节点容量，确保有足够的资源供Pod使用
3. **网络性能问题**: 检查网络配置，考虑使用更高级的网络插件或优化网络策略
4. **镜像拉取缓慢**: 考虑使用镜像加速器或本地镜像仓库

### 项目整体流程

1. **环境准备**: 确保满足环境前提条件，包括TKE集群和kubectl配置
2. **安装部署**: 克隆项目并运行部署脚本安装必要组件
3. **配置调整**: 根据需求修改测试参数
4. **运行测试**: 选择并执行所需的测试工作流
5. **结果分析**: 查看测试日志，解读性能指标
6. **优化调整**: 根据测试结果进行系统优化
7. **重复测试**: 验证优化效果

## ⚙️ 配置

修改工作流文件中的测试参数：

```yaml
# playbook/workflow/supernode-pod-benchmark.yaml
arguments:
  parameters:
  - name: target-pod-count
    value: "20"  # Pod数量
  - name: benchmark-type
    value: "concurrent-creation"  # 或 "sequential-creation"
```

## 📁 项目结构

```
tke-chaos-playbook/
├── playbook/                    # 核心测试组件
│   ├── template/               # 工作流模板
│   │   ├── supernode-pod-benchmark-template.yaml
│   │   ├── network-performance-template.yaml

│   │   ├── image-pull-template.yaml
│   │   └── resource-elasticity-template.yaml
│   ├── workflow/               # 测试场景定义
│   │   ├── supernode-pod-benchmark.yaml
│   │   ├── network-performance-test.yaml

│   │   ├── image-pull-test.yaml
│   │   └── resource-elasticity-test.yaml
│   ├── install-argo.yaml      # Argo Workflows安装
│   └── rbac.yaml              # RBAC权限配置
├── scripts/                    # 自动化脚本
│   ├── deploy-all-templates.sh        # 部署所有模板
│   ├── deploy-supernode-benchmark.sh  # 部署基准测试
│   ├── test-network-performance.sh    # 网络性能测试
│   ├── validate-project.sh            # 项目验证
│   └── validate-supernode-allocation.sh # 节点分配验证
└── config/                     # 配置文件
    ├── supernode-config.yaml          # 超级节点配置
    ├── network-test-config.yaml       # 网络测试配置

    └── performance-thresholds.yaml    # 性能阈值配置
```

## 📊 测试结果示例

```
=== 超级节点Pod创建压测结果 ===
Pod创建统计:
  总创建数: 20
  成功运行: 19
  成功率: 95%

Pod创建耗时统计:
  平均耗时: 5.678s
  P99耗时: 12.345s

端到端耗时统计:
  平均耗时: 8.901s
  P99耗时: 18.234s
```

## 📈 性能指标

### 关键指标
- **Pod创建时间**: Pod创建到Running状态的时间
- **端到端时间**: Pod创建到Ready状态的完整时间
- **P99延迟**: 99%的操作延迟小于此值
- **成功率**: 成功完成操作的百分比

### 性能基准
- **优秀**: Pod创建P99 < 10s, 成功率 > 95%
- **良好**: Pod创建P99 < 20s, 成功率 > 90%
- **需要优化**: Pod创建P99 > 30s, 成功率 < 85%

## 🧹 清理

```bash
# 删除测试工作流
kubectl delete workflow supernode-pod-benchmark -n tke-chaos-test

# 清理测试资源
kubectl delete namespace tke-supernode-benchmark --ignore-not-found=true
```

## 🔍 故障排除

### 常见问题
- **模板未找到**: 运行 `./scripts/deploy-all-templates.sh`
- **Pod创建失败**: 检查超级节点资源和权限
- **高延迟**: 检查网络配置
- **低成功率**: 检查资源配额和节点容量

### 调试命令
```bash
# 检查Pod事件
kubectl describe pod <pod-name> -n tke-supernode-benchmark

# 查看节点资源
kubectl describe nodes -l node.kubernetes.io/instance-type=eklet

# 监控测试进度
kubectl get pods -n tke-supernode-benchmark -w
```

## 📄 许可证

详见 [LICENSE](LICENSE) 文件。

---

**项目状态**: 生产就绪 ✅  
**技术支持**: 已在实际TKE环境中验证  
**持续改进**: 与TKE超级节点最新特性保持同步