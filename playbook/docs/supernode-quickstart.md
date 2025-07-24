# 超级节点演练快速开始指南

## 前置条件

1. 确保你的TKE集群中有超级节点
2. 已按照主README完成基础环境配置
3. 源集群和目标集群已正确配置

## 检查超级节点

首先检查你的集群中是否有超级节点：

```bash
# 检查超级节点
kubectl get nodes -l node.kubernetes.io/instance-type=eklet

# 如果使用其他标签，可以自定义查询
kubectl get nodes -l <your-supernode-label>
```

## 快速演练步骤

### 1. 部署模板和RBAC

```bash
# 部署必要的模板和权限
kubectl create -f playbook/rbac.yaml
kubectl create -f playbook/all-in-one-template.yaml
```

### 2. 选择演练场景

#### 场景一：调度压力测试

测试超级节点的Pod调度能力：

```bash
# 使用示例配置
kubectl create -f playbook/workflow/examples/supernode-schedule-pressure-example.yaml

# 或使用默认配置
kubectl create -f playbook/workflow/supernode-scenario.yaml
```

#### 场景二：资源限制测试

测试超级节点的资源管理能力：

```bash
# 使用示例配置（推荐）
kubectl create -f playbook/workflow/examples/supernode-resource-limit-example.yaml
```

#### 场景三：故障模拟测试

测试超级节点对异常Pod的处理：

```bash
# 修改supernode-scenario.yaml中的scenario-type为failure-simulation
# 然后执行
kubectl create -f playbook/workflow/supernode-scenario.yaml
```

### 3. 监控演练过程

```bash
# 查看工作流状态
kubectl get workflow -n tke-chaos-test

# 查看演练Pod状态
kubectl get pods -n tke-chaos-test -w

# 查看测试资源（演练过程中）
kubectl get pods -n tke-supernode-test -o wide
```

### 4. 查看演练结果

- 访问Argo Server UI查看详细流程
- 或使用命令行查看：

```bash
kubectl describe workflow <workflow-name> -n tke-chaos-test
```

### 5. 清理演练

```bash
# 删除演练工作流
kubectl delete workflow <workflow-name> -n tke-chaos-test

# 测试资源会自动清理，如需手动清理：
kubectl delete namespace tke-supernode-test --ignore-not-found=true
```

## 参数自定义

### 常用参数修改

在演练YAML文件中修改以下参数：

```yaml
# 集群信息
- name: cluster-id
  value: "你的集群ID"

# 超级节点选择器（如果不是默认标签）
- name: supernode-selector
  value: "your-label-key=your-label-value"

# 调度压力测试参数
- name: test-pod-count
  value: "100"  # Pod数量

# 资源限制测试参数
- name: cpu-stress-cores
  value: "4"    # CPU核心数
- name: memory-stress-size
  value: "2G"   # 内存大小

# 测试持续时间
- name: test-duration
  value: "120s"
```

## 故障排查

### 常见问题

1. **未找到超级节点**
   ```bash
   # 检查节点标签
   kubectl get nodes --show-labels | grep eklet
   ```

2. **权限不足**
   ```bash
   # 检查RBAC配置
   kubectl get clusterrole tke-chaos
   kubectl get clusterrolebinding tke-chaos
   ```

3. **演练失败**
   ```bash
   # 查看演练Pod日志
   kubectl logs -n tke-chaos-test <pod-name>
   ```

### 日志查看

```bash
# 查看Argo Workflow Controller日志
kubectl logs -n tke-chaos-test deployment/tke-chaos-argo-workflows-workflow-controller

# 查看演练执行日志
kubectl logs -n tke-chaos-test -l workflows.argoproj.io/workflow=<workflow-name>
```

## 最佳实践

1. **测试环境优先**：建议先在测试环境验证演练效果
2. **逐步增加压力**：从小规模开始，逐步增加Pod数量或资源消耗
3. **监控集群状态**：演练过程中关注集群整体健康状态
4. **定期演练**：建立定期演练机制，持续验证超级节点稳定性