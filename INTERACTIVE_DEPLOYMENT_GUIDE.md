# 交互式部署指南

## 🎯 概述

TKE Chaos Playbook现在支持完全交互式的配置部署，让您可以轻松自定义所有测试参数，包括webhook、测试次数、Pod个数、资源配置等。

## 🚀 使用方法

### 1. 交互式配置模式（推荐）

```bash
# 启动交互式配置向导
./scripts/deploy-all.sh --interactive
```

这将启动一个友好的配置向导，引导您完成所有配置：

```
========================================
  交互式配置向导
========================================

1. 集群配置
集群ID (默认: tke-cluster): my-test-cluster
命名空间 (默认: tke-chaos-test): 

2. 测试配置
测试迭代次数 (1-20, 默认: 3): 5
Deployment副本数 (默认: 1): 2
测试间隔时间 (默认: 30s): 45s

3. Pod配置
Pod镜像 (默认: nginx:alpine): nginx:1.25-alpine

4. 资源配置
当前配置: CPU请求=100m, 内存请求=128Mi
          CPU限制=200m, 内存限制=256Mi

是否修改资源配置? (y/N): y
CPU请求 (默认: 100m): 200m
内存请求 (默认: 128Mi): 256Mi
CPU限制 (默认: 200m): 500m
内存限制 (默认: 256Mi): 512Mi

5. 企业微信通知配置
是否配置企业微信通知? (y/N): y
请输入企业微信群机器人的webhook URL:
格式: https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=YOUR_KEY
Webhook URL: https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=abc123
✅ 企业微信通知已配置

========================================
  配置确认
========================================
集群ID: my-test-cluster
命名空间: tke-chaos-test
测试迭代: 5 次
副本数: 2 个
Pod镜像: nginx:1.25-alpine
资源配置: CPU=200m/500m, 内存=256Mi/512Mi
测试间隔: 45s
企业微信通知: 已配置

确认以上配置并开始部署? (y/N): y
```

### 2. 命令行参数模式

```bash
# 基础配置
./scripts/deploy-all.sh -i 5 -r 2

# 完整配置
./scripts/deploy-all.sh \
  -i 10 \
  -r 3 \
  -w "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=YOUR_KEY" \
  -c "my-cluster" \
  --image "nginx:1.25" \
  --cpu-request "200m" \
  --memory-request "256Mi" \
  --cpu-limit "1000m" \
  --memory-limit "1Gi" \
  --delay "60s"

# 快速部署（跳过确认）
./scripts/deploy-all.sh -q -i 3 -r 1 -w "YOUR_WEBHOOK"
```

### 3. 默认配置模式

```bash
# 使用默认配置
./scripts/deploy-all.sh

# 快速部署默认配置
./scripts/deploy-all.sh -q
```

## 📋 配置参数详解

### 基础配置
| 参数 | 说明 | 默认值 | 范围 |
|------|------|--------|------|
| `-c, --cluster-id` | 集群ID | tke-cluster | 任意字符串 |
| `-n, --namespace` | 命名空间 | tke-chaos-test | 有效的K8s命名空间名 |

### 测试配置
| 参数 | 说明 | 默认值 | 范围 |
|------|------|--------|------|
| `-i, --iterations` | 测试迭代次数 | 3 | 1-20 |
| `-r, --replicas` | Deployment副本数 | 1 | 无限制 |
| `--delay` | 测试间隔时间 | 30s | 如: 30s, 1m, 2m30s |

### Pod配置
| 参数 | 说明 | 默认值 | 示例 |
|------|------|--------|------|
| `--image` | Pod镜像 | nginx:alpine | nginx:1.25, busybox:latest |

### 资源配置
| 参数 | 说明 | 默认值 | 示例 |
|------|------|--------|------|
| `--cpu-request` | CPU请求 | 100m | 100m, 0.1, 1 |
| `--memory-request` | 内存请求 | 128Mi | 128Mi, 1Gi |
| `--cpu-limit` | CPU限制 | 200m | 500m, 1, 2 |
| `--memory-limit` | 内存限制 | 256Mi | 512Mi, 2Gi |

### 通知配置
| 参数 | 说明 | 默认值 | 示例 |
|------|------|--------|------|
| `-w, --webhook` | 企业微信webhook | 空 | https://qyapi.weixin.qq.com/... |

### 模式配置
| 参数 | 说明 |
|------|------|
| `--interactive` | 启动交互式配置向导 |
| `-q, --quick` | 快速模式，跳过确认 |
| `--skip-test` | 只部署组件，不启动测试 |

## 🎨 使用场景示例

### 场景1: 性能压测
```bash
# 高强度测试：10次迭代，3个副本，更多资源
./scripts/deploy-all.sh \
  -i 10 \
  -r 3 \
  --cpu-limit "1000m" \
  --memory-limit "1Gi" \
  --delay "60s"
```

### 场景2: 快速验证
```bash
# 快速验证：3次迭代，1个副本，默认资源
./scripts/deploy-all.sh -q -i 3
```

### 场景3: 生产环境模拟
```bash
# 模拟生产环境：使用生产镜像和资源配置
./scripts/deploy-all.sh \
  --image "my-app:v1.2.3" \
  --cpu-request "500m" \
  --memory-request "1Gi" \
  --cpu-limit "2000m" \
  --memory-limit "4Gi" \
  -w "YOUR_WEBHOOK"
```

### 场景4: 批量测试
```bash
# 批量测试：多次迭代，多个副本
./scripts/deploy-all.sh \
  -i 15 \
  -r 5 \
  --delay "2m" \
  -w "YOUR_WEBHOOK"
```

## 📊 配置建议

### 资源配置建议
| 测试类型 | CPU请求 | 内存请求 | CPU限制 | 内存限制 |
|----------|---------|----------|---------|----------|
| **轻量测试** | 50m | 64Mi | 100m | 128Mi |
| **标准测试** | 100m | 128Mi | 200m | 256Mi |
| **性能测试** | 200m | 256Mi | 500m | 512Mi |
| **压力测试** | 500m | 512Mi | 1000m | 1Gi |

### 迭代次数建议
| 目标 | 迭代次数 | 说明 |
|------|----------|------|
| **快速验证** | 3-5次 | 验证基本功能 |
| **性能分析** | 5-10次 | 获得稳定的性能数据 |
| **深度测试** | 10-15次 | 详细的性能分析 |
| **压力测试** | 15-20次 | 极限性能测试 |

### 副本数建议
| 场景 | 副本数 | 说明 |
|------|--------|------|
| **单点测试** | 1个 | 测试单个Pod的沙箱复用 |
| **并发测试** | 2-3个 | 测试并发场景下的复用效果 |
| **负载测试** | 3-5个 | 测试高负载下的性能 |

## 🔍 监控和验证

### 查看配置生效
```bash
# 查看工作流配置
kubectl get workflow -n tke-chaos-test -o yaml | grep -A 20 "parameters:"

# 查看实际运行的Pod配置
kubectl get pods -n tke-chaos-test -o yaml | grep -A 10 "resources:"
```

### 监控测试进度
```bash
# 实时查看工作流状态
kubectl get workflows -n tke-chaos-test -w

# 查看详细日志
kubectl logs -l workflows.argoproj.io/workflow -n tke-chaos-test -f
```

## 🎯 最佳实践

1. **首次使用**: 建议使用`--interactive`模式熟悉各项配置
2. **生产测试**: 使用与生产环境相似的资源配置
3. **性能分析**: 至少进行5次迭代以获得稳定数据
4. **通知配置**: 配置企业微信通知以便及时获得结果
5. **资源规划**: 根据集群资源情况合理设置副本数和资源限制

## 🚀 快速开始

```bash
# 第一次使用 - 交互式配置
./scripts/deploy-all.sh --interactive

# 日常使用 - 命令行配置
./scripts/deploy-all.sh -i 5 -r 2 -w "YOUR_WEBHOOK"

# 快速验证 - 默认配置
./scripts/deploy-all.sh -q
```

现在您可以根据具体需求灵活配置和部署TKE超级节点沙箱复用测试了！