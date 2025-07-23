# TKE Serverless 性能测试 Playbook

[English](README.md) | [中文](README_zh.md)

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![TKE](https://img.shields.io/badge/TKE-Serverless-green.svg)](https://cloud.tencent.com/product/tke)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.20+-blue.svg)](https://kubernetes.io/)

## 🚀 项目简介

本项目专门为**腾讯云TKE Serverless**（弹性容器服务EKS）提供全面的性能测试解决方案。基于Argo Workflow构建，提供自动化的性能测试流水线，帮助您评估和优化Serverless容器的性能表现。

### 🎯 核心价值

- **性能基准测试**：建立TKE Serverless的性能基线
- **自动化测试**：一键执行完整的性能测试套件
- **成本优化**：通过性能数据优化资源配置和成本
- **生产就绪**：为生产环境提供性能保障

### ✨ 主要特性

#### 🏃‍♂️ Pod启动性能测试
- 多规格Pod启动速度测试（0.25C/0.5Gi ~ 2C/4Gi）
- 不同镜像大小对启动时间的影响分析
- 批量Pod启动的并发性能测试
- 启动成功率和稳定性验证

#### 📈 弹性扩缩容性能测试
- HPA自动扩容响应时间测试
- 负载降低后的自动缩容测试
- 扩缩容稳定性和抖动分析
- 资源利用率优化建议

#### 🌐 网络性能测试（规划中）
- Pod间通信延迟测试
- Service负载均衡性能
- Ingress吞吐量测试
- 外网访问性能评估

#### 💾 存储性能测试（规划中）
- PVC挂载性能测试
- 不同存储类型的I/O性能
- 数据持久化验证

## 🎯 适用场景

### 业务场景
- **突发流量应用**：电商促销、直播带货等
- **批处理任务**：数据处理、机器学习训练
- **微服务架构**：云原生应用部署
- **CI/CD流水线**：构建和部署任务
- **事件驱动应用**：消息处理、函数计算

### 测试目标
- 验证TKE Serverless在不同负载下的性能表现
- 为容量规划提供数据支撑
- 优化资源配置以降低成本
- 建立性能监控和告警基线

## 📋 前置条件

### 环境要求
- **TKE Serverless集群**：腾讯云弹性容器服务EKS集群
- **源集群**：用于执行测试流程的Kubernetes集群（可以是普通TKE集群）
- **kubectl**：已配置并能访问两个集群
- **Argo Workflow**：v3.4.0+

### 集群准备

#### 1. TKE Serverless集群（目标集群）

```bash
# 在TKE Serverless集群中创建测试标识
kubectl create ns tke-serverless-test
kubectl create -n tke-serverless-test configmap tke-serverless-precheck-resource --from-literal=ready="true"

# 确保集群已启用Serverless节点池
# 在腾讯云TKE控制台验证Serverless配置
```

#### 2. 源集群（测试执行集群）

```bash
# 获取TKE Serverless集群的kubeconfig
# 从腾讯云TKE控制台下载内网访问kubeconfig

# 在源集群中创建目标集群访问凭证
kubectl create ns tke-serverless-test
kubectl create -n tke-serverless-test secret generic serverless-cluster-kubeconfig \
  --from-file=config=./serverless-cluster-kubeconfig

# 部署Argo Workflow
kubectl create -f playbook/install-argo.yaml

# 验证Argo Workflow运行状态
kubectl get po -n tke-serverless-test
```

#### 3. 配置Argo UI访问

```bash
# 开启Argo Server UI公网访问（在腾讯云TKE控制台）
# 或配置内网访问

# 获取访问token
kubectl exec -it -n tke-serverless-test deployment/tke-serverless-argo-workflows-server -- argo auth token
```

## 🚀 快速开始

### 一键测试（推荐）

```bash
# 克隆项目
git clone https://github.com/wi1123/EKS-playbook.git
cd EKS-playbook

# 赋予执行权限
chmod +x run-serverless-tests.sh

# 执行Pod启动性能测试
./run-serverless-tests.sh startup

# 执行弹性扩缩容性能测试
./run-serverless-tests.sh scaling

# 执行所有性能测试
./run-serverless-tests.sh all
```

### 手动部署步骤

#### 1. 使用自动化脚本（推荐）

```bash
# 赋予执行权限
chmod +x run-serverless-tests.sh

# 执行Pod启动性能测试
./run-serverless-tests.sh startup

# 执行弹性扩缩容性能测试
./run-serverless-tests.sh scaling

# 执行所有性能测试
./run-serverless-tests.sh all

# 查看测试状态
./run-serverless-tests.sh --status

# 清理测试资源
./run-serverless-tests.sh --cleanup
```

#### 2. 手动执行测试

**Pod启动性能测试**：
```bash
# 部署必要的模板和RBAC
kubectl create -f playbook/rbac.yaml && kubectl create -f playbook/all-in-one-template.yaml

# 执行Pod启动性能测试
kubectl create -f playbook/workflow/serverless-pod-startup-performance.yaml

# 监控测试进度
kubectl get workflow -n tke-chaos-test
kubectl describe workflow serverless-pod-startup-performance -n tke-chaos-test
```

**弹性扩缩容性能测试**：
```bash
# 执行扩缩容性能测试
kubectl create -f playbook/workflow/serverless-scaling-performance.yaml

# 监控HPA和Pod状态
kubectl get hpa -n tke-serverless-scaling-test -w
kubectl get pods -n tke-serverless-scaling-test -w
```

### 测试场景说明

| 测试场景 | 测试文件 | 测试内容 | 关键指标 |
|---------|---------|---------|---------|
| Pod启动性能 | `serverless-pod-startup-performance.yaml` | 不同规格Pod启动速度测试 | 启动时间、成功率、并发能力 |
| 弹性扩缩容 | `serverless-scaling-performance.yaml` | HPA自动扩缩容响应测试 | 扩缩容响应时间、稳定性 |

### 性能测试参数配置

**Pod启动性能测试参数**：
```yaml
pod-count-small: "10"      # 小规格Pod数量 (0.25C/0.5Gi)
pod-count-medium: "5"      # 中规格Pod数量 (1C/2Gi)
pod-count-large: "3"       # 大规格Pod数量 (2C/4Gi)
startup-timeout: "120s"    # Pod启动超时时间
test-duration: "300s"      # 测试持续时间
```

**弹性扩缩容测试参数**：
```yaml
initial-replicas: "2"      # 初始副本数
max-replicas: "20"         # 最大副本数
target-cpu-percent: "50"   # CPU目标使用率
load-duration: "300s"      # 负载持续时间
cooldown-duration: "180s"  # 冷却时间
```

### 查看测试结果

1. **通过Argo UI查看**（推荐）：
   - 访问 `LoadBalancer IP:2746`
   - 使用token登录查看详细的测试流程和结果

2. **通过命令行查看**：
   ```bash
   # 查看工作流状态
   kubectl get workflow -n tke-chaos-test
   
   # 查看详细结果
   kubectl describe workflow <workflow-name> -n tke-chaos-test
   ```

3. **查看详细测试指南**：
   ```bash
   cat playbook/TKE_SERVERLESS_PERFORMANCE_GUIDE.md
   ```

### 性能基准参考

**Pod启动性能**：
- 小规格Pod (0.25C/0.5Gi)：通常 < 10秒
- 中规格Pod (1C/2Gi)：通常 < 15秒
- 大规格Pod (2C/4Gi)：通常 < 30秒
- 启动成功率：应 > 95%

**扩缩容性能**：
- 扩容响应时间：通常 < 60秒
- 缩容响应时间：通常 < 120秒
- 扩缩容稳定性：无频繁抖动

## 🗓️ 功能规划路线图

| 测试功能                         | 优先级  | 当前状态     | 计划发布时间  | 描述                                                |
|------------------------------|--------|------------|---------------|---------------------------------------------------|
| Pod启动性能测试                   | P0    |    ✅ 完成    |      -       | 多规格Pod启动速度、成功率、并发性能测试                        |
| 弹性扩缩容性能测试                 | P0    |    ✅ 完成    |      -       | HPA自动扩缩容响应时间、稳定性测试                          |
| 网络性能测试                      | P1    |    🚧 开发中  |  2025-02-28  | Pod间通信延迟、Service负载均衡、Ingress吞吐量测试           |
| 存储性能测试                      | P1    |    📋 规划中  |  2025-03-31  | PVC挂载性能、不同存储类型I/O性能测试                       |
| 冷启动vs热启动对比测试             | P1    |    📋 规划中  |  2025-02-15  | 镜像缓存对启动性能的影响分析                              |
| 成本效益分析测试                  | P2    |    📋 规划中  |  2025-04-30  | 不同规格Pod的成本效益比分析                             |
| 批量任务性能测试                  | P2    |    📋 规划中  |  2025-05-31  | Job/CronJob在Serverless环境下的性能表现               |
| 多租户隔离性能测试                | P2    |    📋 规划中  |  2025-06-30  | 多租户场景下的资源隔离和性能影响                           |
| GPU工作负载性能测试               | P3    |    📋 规划中  |  2025-07-31  | GPU加速工作负载在Serverless环境下的性能                 |
| 监控和告警集成                    | P1    |    📋 规划中  |  2025-03-15  | 集成Prometheus、Grafana监控和告警                    |

## ❓ 常见问题

### 1. 为什么需要两个集群进行性能测试？

**答**：性能测试基于`Argo Workflow`进行编排，`Argo Workflow`强依赖`kube-apiserver`。为了确保测试过程的稳定性和准确性：
- **源集群**：运行Argo Workflow，负责测试编排和结果收集
- **目标集群**：TKE Serverless集群，作为被测试对象

这样可以避免测试过程中对控制平面的影响，确保测试结果的可靠性。

### 2. 如何监控性能测试的执行进度？

**答**：您可以通过多种方式监控测试进度：

```bash
# 方法1：查看工作流状态
kubectl get workflow -n tke-serverless-test

# 方法2：查看详细执行信息
kubectl describe workflow <workflow-name> -n tke-serverless-test

# 方法3：实时监控Pod状态
kubectl get pods -n tke-serverless-test -w

# 方法4：使用自动化脚本
./run-serverless-tests.sh --status

# 方法5：访问Argo UI（推荐）
# 浏览器访问 LoadBalancer IP:2746
```

### 3. 性能测试失败的常见原因有哪些？

**答**：常见的失败原因包括：

**环境配置问题**：
- TKE Serverless集群配置不正确
- kubeconfig凭证过期或权限不足
- 网络连接问题

**资源问题**：
- 集群资源配额不足
- Serverless节点池未正确配置
- 镜像拉取失败

**权限问题**：
- RBAC权限配置不当
- ServiceAccount权限不足

**排查方法**：
```bash
# 检查Pod日志
kubectl logs <pod-name> -n tke-serverless-test

# 检查事件
kubectl get events -n tke-serverless-test --sort-by='.lastTimestamp'

# 检查工作流详情
kubectl describe workflow <workflow-name> -n tke-serverless-test
```

### 4. 如何解读性能测试结果？

**答**：性能测试结果包含多个关键指标：

**Pod启动性能**：
- **启动时间**：从Pod创建到Running状态的时间
- **成功率**：成功启动的Pod占总数的比例
- **并发能力**：同时启动多个Pod的性能表现

**扩缩容性能**：
- **扩容响应时间**：从负载增加到新Pod就绪的时间
- **缩容响应时间**：从负载降低到Pod终止的时间
- **稳定性**：扩缩容过程中是否出现抖动

**基准对比**：
```
优秀：Pod启动 < 10s，扩容响应 < 30s
良好：Pod启动 < 20s，扩容响应 < 60s
需优化：Pod启动 > 30s，扩容响应 > 90s
```

### 5. 如何优化TKE Serverless的性能？

**答**：基于测试结果，您可以从以下方面优化：

**镜像优化**：
- 使用轻量级基础镜像（如alpine）
- 减少镜像层数和大小
- 启用镜像缓存功能

**资源配置优化**：
- 根据实际需求设置合适的CPU/内存规格
- 避免过度配置资源
- 使用资源预留功能

**扩缩容策略优化**：
- 调整HPA的CPU/内存阈值
- 配置合适的扩缩容策略和冷却时间
- 考虑使用VPA进行垂直扩缩容

### 6. 测试环境的最佳实践是什么？

**答**：建议遵循以下最佳实践：

**环境隔离**：
- 使用专门的测试环境，避免影响生产
- 为不同类型的测试创建独立的命名空间

**定期测试**：
- 建立定期的性能基准测试
- 在重大变更前后进行对比测试

**监控告警**：
- 配置性能监控和告警
- 建立性能趋势分析

**成本控制**：
- 及时清理测试资源
- 监控测试成本

### 7. 如何集成到CI/CD流水线？

**答**：您可以将性能测试集成到CI/CD流水线中：

```yaml
# GitHub Actions示例
name: TKE Serverless Performance Test
on:
  schedule:
    - cron: '0 2 * * *'  # 每日凌晨2点执行
  workflow_dispatch:     # 手动触发

jobs:
  performance-test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - name: Setup kubectl
      uses: azure/setup-kubectl@v3
    - name: Run Performance Tests
      run: |
        chmod +x run-serverless-tests.sh
        ./run-serverless-tests.sh all
    - name: Upload Results
      uses: actions/upload-artifact@v3
      with:
        name: performance-results
        path: test-results/
```

### 8. 如何获得技术支持？

**答**：如果遇到问题，您可以：

- 📖 查看详细文档：`playbook/TKE_SERVERLESS_PERFORMANCE_GUIDE.md`
- 🐛 提交Issue：[GitHub Issues](https://github.com/wi1123/EKS-playbook/issues)
- 💬 参与讨论：[GitHub Discussions](https://github.com/wi1123/EKS-playbook/discussions)
- 📧 联系维护者：通过GitHub联系项目维护者

## 📚 相关文档

- [TKE Serverless性能测试详细指南](playbook/TKE_SERVERLESS_PERFORMANCE_GUIDE.md)
- [贡献指南](CONTRIBUTING.md)
- [Argo Workflow官方文档](https://argoproj.github.io/argo-workflows/)
- [腾讯云TKE Serverless文档](https://cloud.tencent.com/document/product/457)

## 🤝 贡献

欢迎贡献代码、文档或提出建议！请查看[贡献指南](CONTRIBUTING.md)了解详细信息。

## 📄 许可证

本项目采用Apache License 2.0许可证 - 详见[LICENSE](LICENSE)文件。

---

**为Kubernetes和Serverless社区而生 ❤️**
