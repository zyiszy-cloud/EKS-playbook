# 演练场景说明

[English](README.md) | [中文](README_zh.md)

## kube-apiserver高负载

**playbook**：`workflow/apiserver-overload-scenario.yaml`

该场景构造`kube-apiserver`高负载，主要流程包括：
- **演练校验**：对被演练的`目标集群`做健康检查，检查演练集群中的`Node`和`Pod`的健康比例，低于阈值将不允许演练，您可以通过修改`precheck-pods-health-ratio`和`precheck-nodes-health-ratio`参数调整阈值。同时会校验`目标集群`中是否存在`tke-chaos-test/tke-chaos-precheck-resource ConfigMap`，如不存在将不允许演练。
- **资源预热**：在集群中创建资源(`pods/configmaps`)，模拟现网环境资源规模。
- **故障注入**：对apiserver发起洪泛`list pod/configmaps`请求，模拟`kube-apiserver`高负载压力。
- **资源清理**：演练测试完成后清理演练过程中创建的资源。

支持演练过程中开启`etcd过载保护`和`APF流控策略`[APF限流](https://kubernetes.io/zh-cn/docs/concepts/cluster-administration/flow-control/)，您可以通过配置`enable-etcd-overload-protect`，`enable-apf`参数来开启和关闭这两个特性。`etcd过载保护`和`APF流控策略`可以有效的防护`kube-apiserver/etcd`被大流量冲击，您可以开启和禁用`etcd过载保护`、`APF流控策略`进行演练，以此来对比防护效果，并结合具体业务场景来决策是否对您的`K8s`集群开启防护策略。

**参数说明**

| 参数名称 | 类型 | 默认值 | 说明 |
|---------|---------|------|--------|
| `kubeconfig-secret-name` | `string` | `dest-cluster-kubeconfig` | `目标集群`接入`kubeconfig`的`secret名称`，如果为空，则演练当前集群 |
| `webhook-url` | `string` | "" | 企业微信群`webhook地址`，如果为空，将不进行企微通知 |
| `enable-apf` | `bool` | "false" | 演练时，是否启用`APF限速` |
| `enable-etcd-overload-protect` | `bool` | "false" | 演练时，是否启用`etcd`过载保护 |
| `precheck-pods-health-ratio` | `float` | "0.9" | `目标集群`中`Pod`健康率(0.9表示90%)，低于该值将不允许演练 |
| `precheck-nodes-health-ratio` | `float` | "0.9" | `目标集群`中`Node`健康率(0.9表示90%)，低于该值将不允许演练 |
| `enable-resource-create` | `bool` | "false" | 演练开始前是否进行资源预热，创建资源，模拟集群规模 |
| `resource-create-object-size-bytes` | `int` | "10000" | 预热阶段创建资源大小(单位字节) |
| `resource-create-object-count` | `int` | "10" | 预热阶段创建资源数量 |
| `resource-create-qps` | `int` | "10" | 预热创建资源`QPS` |
| `from-cache` | `bool` | "true" | 压测走`kube-apiserver`缓存时，设置为`true`；请求击穿到`etcd`时，设置为`false` |
| `inject-stress-concurrency` | `int` | "1" | 发压的`Pod`数量 |
| `inject-stress-list-qps` | `int` | "100" | 每个发压`Pod`的`QPS` |
| `inject-stress-total-duration` | `string` | "30s" | 发压执行总时长(如30s，5m等) |

**etcd过载保护&增强apf限流说明**

腾讯云TKE团队在社区版本基础上开发了以下核心保护特性：

1. **etcd过载保护**： 防止`etcd`因业务组件`List`请求（未查询`kube-apiserver`缓存）过载而不可用。
2. **增强APF(API优先级和公平性)限流**： 针对`expensive list`提供基于`List`开销的精细化流控。

支持的版本：

| TKE版本           |
|-------------------|
| v1.30.0-tke.9+    |
| v1.28.3-tke.14+   |
| v1.26.1-tke.17+   |
| v1.24.4-tke.26+   |
| v1.22.5-tke.35+   |
| v1.20.6-tke.54+   |

## coredns停服

**playbook**：`workflow/coredns-disruption-scenario.yaml`

该场景通过以下方式构造`coredns`服务中断：
1. 将`coredns Deployment`副本数缩容到`0`
2. 维持指定时间副本数为`0`
3. 恢复原有副本数

**参数说明**

| 参数名称 | 类型 | 默认值 | 说明 |
|---------|------|--------|------|
| `disruption-duration` | `string` | `30s` | 服务中断持续时间(如30s，5m等) |
| `kubeconfig-secret-name` | `string` | `dest-cluster-kubeconfig` | `目标集群kubeconfig secret`名称，如为空，则演练当前集群 |

## kubernetes-proxy停服

**playbook**：`workflow/kubernetes-proxy-disruption-scenario.yaml`

该场景通过以下方式构造`kubernetes-proxy`服务中断：
1. 将`kubernetes-proxy` `Deployment`副本数缩容到0
2. 维持指定时间副本数为`0`
3. 恢复原有副本数

**参数说明**

| 参数名称 | 类型 | 默认值 | 说明 |
|---------|------|--------|------|
| `disruption-duration` | `string` | `30s` | 服务中断持续时间(如30s，5m等) |
| `kubeconfig-secret-name` | `string` | `dest-cluster-kubeconfig` | `目标集群kubeconfig secret`名称，如为空，则演练当前集群 |

## TKE Master自维护集群kube-apiserver停服
TODO

## TKE Master自维护集群etcd停服
TODO

## TKE Master自维护集群kube-controller-manager停服
TODO

## TKE Master自维护集群kube-scheduler停服
TODO

## 托管集群kube-apiserver组件停服
TODO

## 托管集群kube-controller-manager停服
TODO

## 托管集群kube-scheduler停服
TODO
