定义与实现

## 📊 标准时间指标

根据超级节点的性能测试需求，我们实现了以下标准时间指标：

### 1. Pod创建耗时（沙箱初始化耗时）

**定义**: 沙箱初始化耗时，包括沙箱匹配、缓存盘创建和挂载的时间，不包含Pod创建出来后调度及等待处理的时间

**计算范围**:
- **开始时间**: Pod的`metadata.creationTimestamp`（kubelet接收到Pod创建指令）
- **结束时间**: 容器开始运行的时间（通过容器状态或Events中的`Started`事件标识）

**实现方式**:
```bash
# 获取Pod创建时间（沙箱初始化开始）
POD_CREATE_TIME=$(kubectl get pod $pod -o jsonpath='{.metadata.creationTimestamp}')
POD_CREATE_TS=$(date -d "$POD_CREATE_TIME" +%s)

# 获取容器启动时间（沙箱初始化完成）
CONTAINER_START_TIME=$(kubectl get pod $pod -o jsonpath='{.status.containerStatuses[0].state.running.startedAt}')
CONTAINER_START_TS=$(date -d "$CONTAINER_START_TIME" +%s)

# 计算沙箱初始化耗时
SANDBOX_INIT_TIME=$((CONTAINER_START_TS - POD_CREATE_TS))
```

### 2. 端到端耗时

**定义**: 从Pod创建时间到PodReady的完整时间

**计算范围**:
- **开始时间**: `metadata.creationTimestamp`
- **结束时间**: Pod状态中conditions包含`type: Ready`且`status: "True"`的时间

**实现方式**:
```bash
# 获取Pod Ready时间
POD_READY_TIME=$(kubectl get pod $pod -o jsonpath='{.status.conditions[?(@.type=="Ready")].lastTransitionTime}')
POD_READY_TS=$(date -d "$POD_READY_TIME" +%s)

# 计算端到端耗时
END_TO_END_TIME=$((POD_READY_TS - POD_CREATE_TS))
```

### 3. 调度等待耗时

**定义**: 派生计算值，表示除沙箱初始化外的其他等待时间（调度+网络配置等）

**计算方式**:
```
调度等待耗时 = 端到端耗时 - 沙箱初始化耗时
```

**实现方式**:
```bash
SCHEDULING_WAIT_TIME=$((END_TO_END_TIME - SANDBOX_INIT_TIME))
```

## 📈 统计信息

对于每种时间指标，我们都计算以下统计信息：

- **平均值**: 所有Pod的平均时间
- **最小值**: 最快的Pod时间
- **最大值**: 最慢的Pod时间

这些统计信息有助于：
- 评估沙箱复用的性能提升效果
- 识别性能异常的Pod
- 计算P99等百分位数指标

## 🎯 输出示例

```
📊 准确时间指标统计:
  📋 沙箱初始化耗时（不含调度等待）:
    平均: 2.3秒
    最快: 1.8秒
    最慢: 2.7秒
  📋 端到端耗时（Pod创建→PodReady）:
    平均: 5.1秒
    最快: 4.2秒
    最慢: 6.3秒
  📋 调度等待耗时（端到端 - 沙箱初始化）:
    平均: 2.8秒
    最快: 2.1秒
    最慢: 3.6秒
✅ 使用沙箱初始化耗时（Pod创建耗时）: 2.3秒
```

## 🔍 测试流程说明

### 沙箱复用测试流程
**✅ 确认实现了"先创建Pod后销毁Pod然后再创建Pod再销毁后统计时间"**

1. **第一次创建**：基准测试（首次创建沙箱）
2. **销毁**：清理Deployment和Pod
3. **第二次创建**：沙箱复用测试
4. **销毁**：最终清理
5. **统计对比**：比较两次的沙箱初始化时间差异

### 时间计算流程
1. **监控Pod创建**：从Deployment创建开始监控
2. **记录关键时间点**：
   - Pod创建时间（metadata.creationTimestamp）
   - 容器启动时间（沙箱初始化完成）
   - Pod Ready时间（端到端完成）
3. **计算时间指标**：基于准确的时间点计算各项指标
4. **统计分析**：计算平均值、最小值、最大值

## 🔍 沙箱复用效果分析

通过对比基准测试和沙箱复用测试的沙箱初始化耗时，可以评估沙箱复用的效果：

- **性能提升**: 如果沙箱复用测试的时间明显短于基准测试
- **性能持平**: 如果两次测试时间相近，可能沙箱复用未生效或提升不明显
- **性能下降**: 如果沙箱复用测试时间更长，可能存在问题需要排查

## 📝 注意事项

1. **时间精度**: 使用秒级精度，适合大多数场景
2. **事件监控**: 通过Kubernetes Events和容器状态获取准确时间点
3. **容错处理**: 当无法获取准确时间时，使用合理的近似值
4. **负值处理**: 确保时间差不为负数
5. **兼容性**: 支持不同Kubernetes版本的事件格式

## 🔄 与旧版本的区别

**旧版本**：
- 计算从Deployment创建到Pod创建完成的时间
- 包含了调度等待时间
- 指标定义不够准确

**新版本**：
- 准确计算沙箱初始化时间（不含调度等待）
- 分离端到端耗时和调度等待耗时
- 提供更详细的时间指标分析