#!/bin/bash

echo "🔍 分析沙箱运行指标获取方法"
echo "========================================"

# 原始脚本分析
cat << 'EOF'
原始脚本方法分析:
#!/bin/bash
POD=$1
NS=${2:-default}

# 获取起点时间
START_TIME=$(kubectl get pod $POD -n $NS -o jsonpath='{.metadata.creationTimestamp}')
NODE=$(kubectl get pod $POD -n $NS -o jsonpath='{.spec.nodeName}')

# 在节点执行远程命令
END_TIME=$(ssh $NODE "SANDBOX=\$(crictl pods --name $POD -q) && \
journalctl -u containerd -q --since '5 min ago' | \
grep -m1 \"RunPodSandbox.*\$SANDBOX.*completed\" | \
awk '{print \$1\" \"\$2\" \"\$3}'")

# 时间计算
START_TS=$(date -d "$START_TIME" +%s.%N)
END_TS=$(date -d "$END_TIME" +%s.%N)
DURATION=$(echo "$END_TS - $START_TS" | bc)

echo "沙箱初始化报告:"
echo "--------------------------------"
echo "Pod: $POD | Node: $NODE"
echo "API 接收时间: $START_TIME"
echo "沙箱就绪时间: $END_TIME"
printf "初始化耗时: %.3f 秒\n" $DURATION
EOF

echo ""
echo "📊 方法优势分析:"
echo "1. ✅ 使用Pod创建时间作为起点 - 准确的API时间戳"
echo "2. ✅ 通过crictl获取沙箱ID - 直接访问容器运行时"
echo "3. ✅ 通过journalctl获取沙箱完成时间 - 系统级精确时间"
echo "4. ✅ 毫秒级精度计算 - 使用bc进行浮点运算"

echo ""
echo "🚨 潜在问题分析:"
echo "1. ❌ 需要SSH访问节点 - 在Kubernetes Pod中可能无法实现"
echo "2. ❌ 需要crictl命令 - 需要节点上有容器运行时工具"
echo "3. ❌ 需要journalctl访问 - 需要系统日志访问权限"
echo "4. ❌ 依赖外部工具 - bc, ssh, crictl等"

echo ""
echo "🔧 在Kubernetes Pod中的适配方案:"

# 方案1: 使用kubectl + 节点信息
echo "方案1: 通过kubectl获取更详细的Pod状态信息"
cat << 'EOF'
# 获取Pod的详细状态和事件
kubectl get pod $POD -n $NS -o yaml
kubectl describe pod $POD -n $NS
kubectl get events -n $NS --field-selector involvedObject.name=$POD

# 从Pod状态中提取关键时间点
SCHEDULED_TIME=$(kubectl get pod $POD -n $NS -o jsonpath='{.status.conditions[?(@.type=="PodScheduled")].lastTransitionTime}')
INITIALIZED_TIME=$(kubectl get pod $POD -n $NS -o jsonpath='{.status.conditions[?(@.type=="Initialized")].lastTransitionTime}')
READY_TIME=$(kubectl get pod $POD -n $NS -o jsonpath='{.status.conditions[?(@.type=="Ready")].lastTransitionTime}')
CONTAINER_READY_TIME=$(kubectl get pod $POD -n $NS -o jsonpath='{.status.conditions[?(@.type=="ContainersReady")].lastTransitionTime}')
EOF

echo ""
echo "方案2: 使用容器状态信息"
cat << 'EOF'
# 获取容器的详细状态
CONTAINER_STATE=$(kubectl get pod $POD -n $NS -o jsonpath='{.status.containerStatuses[0]}')
CONTAINER_STARTED_AT=$(kubectl get pod $POD -n $NS -o jsonpath='{.status.containerStatuses[0].state.running.startedAt}')
CONTAINER_FINISHED_AT=$(kubectl get pod $POD -n $NS -o jsonpath='{.status.containerStatuses[0].state.terminated.finishedAt}')

# 获取初始化容器状态（如果有）
INIT_CONTAINER_STATE=$(kubectl get pod $POD -n $NS -o jsonpath='{.status.initContainerStatuses[0]}')
EOF

echo ""
echo "方案3: 使用Pod事件时间线"
cat << 'EOF'
# 获取Pod相关的所有事件，按时间排序
kubectl get events -n $NS --field-selector involvedObject.name=$POD --sort-by='.firstTimestamp' -o custom-columns=TIME:.firstTimestamp,REASON:.reason,MESSAGE:.message
EOF

echo ""
echo "🎯 推荐的改进方案:"
echo "结合原脚本的思路，在Kubernetes环境中实现类似功能"

# 创建改进的脚本
cat << 'EOF'

improved_sandbox_timing() {
    local POD=$1
    local NS=${2:-default}
    
    echo "🔍 获取Pod详细时间信息..."
    
    # 1. 获取Pod基本信息
    POD_CREATE_TIME=$(kubectl get pod $POD -n $NS -o jsonpath='{.metadata.creationTimestamp}')
    NODE_NAME=$(kubectl get pod $POD -n $NS -o jsonpath='{.spec.nodeName}')
    
    # 2. 获取Pod状态条件时间
    SCHEDULED_TIME=$(kubectl get pod $POD -n $NS -o jsonpath='{.status.conditions[?(@.type=="PodScheduled")].lastTransitionTime}')
    INITIALIZED_TIME=$(kubectl get pod $POD -n $NS -o jsonpath='{.status.conditions[?(@.type=="Initialized")].lastTransitionTime}')
    READY_TIME=$(kubectl get pod $POD -n $NS -o jsonpath='{.status.conditions[?(@.type=="Ready")].lastTransitionTime}')
    CONTAINERS_READY_TIME=$(kubectl get pod $POD -n $NS -o jsonpath='{.status.conditions[?(@.type=="ContainersReady")].lastTransitionTime}')
    
    # 3. 获取容器状态时间
    CONTAINER_STARTED_AT=$(kubectl get pod $POD -n $NS -o jsonpath='{.status.containerStatuses[0].state.running.startedAt}')
    
    # 4. 获取Pod事件（包含更详细的时间信息）
    echo "📅 Pod事件时间线:"
    kubectl get events -n $NS --field-selector involvedObject.name=$POD --sort-by='.firstTimestamp' -o custom-columns=TIME:.firstTimestamp,REASON:.reason,MESSAGE:.message | head -10
    
    echo ""
    echo "📊 关键时间点:"
    echo "  Pod创建时间: $POD_CREATE_TIME"
    echo "  Pod调度时间: $SCHEDULED_TIME"
    echo "  Pod初始化时间: $INITIALIZED_TIME"
    echo "  容器启动时间: $CONTAINER_STARTED_AT"
    echo "  容器就绪时间: $CONTAINERS_READY_TIME"
    echo "  Pod就绪时间: $READY_TIME"
    echo "  运行节点: $NODE_NAME"
    
    # 5. 计算关键时间差
    if [ -n "$POD_CREATE_TIME" ] && [ -n "$CONTAINER_STARTED_AT" ]; then
        # 使用Python进行精确时间计算
        SANDBOX_INIT_DURATION=$(python3 -c "
import datetime
try:
    start = datetime.datetime.fromisoformat('$POD_CREATE_TIME'.replace('Z', '+00:00'))
    end = datetime.datetime.fromisoformat('$CONTAINER_STARTED_AT'.replace('Z', '+00:00'))
    duration = (end - start).total_seconds()
    print(f'{duration:.3f}')
except:
    print('0.000')
")
        
        echo ""
        echo "⏱️  沙箱初始化耗时: ${SANDBOX_INIT_DURATION}秒"
        echo "   (从Pod创建到容器启动)"
    fi
}

EOF

echo ""
echo "✅ 总结:"
echo "原脚本的方法非常准确，但在Kubernetes Pod环境中需要适配"
echo "推荐使用kubectl获取Pod状态和事件信息来实现类似的精确时间计算"