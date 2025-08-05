#!/bin/bash

echo "🎯 改进的沙箱时间计算方法（基于您的脚本思路）"
echo "========================================"

# 基于您脚本思路的改进版本，适配Kubernetes Pod环境
improved_sandbox_timing() {
    local POD=$1
    local NS=${2:-default}
    
    echo "🔍 获取Pod详细时间信息..."
    
    # 1. 获取Pod基本信息（与您的脚本相同的起点）
    POD_CREATE_TIME=$(kubectl get pod $POD -n $NS -o jsonpath='{.metadata.creationTimestamp}')
    NODE_NAME=$(kubectl get pod $POD -n $NS -o jsonpath='{.spec.nodeName}')
    
    echo "📊 基础信息:"
    echo "  Pod名称: $POD"
    echo "  命名空间: $NS"
    echo "  Pod创建时间: $POD_CREATE_TIME"
    echo "  运行节点: $NODE_NAME"
    
    # 2. 获取Pod状态条件时间（更详细的时间点）
    echo ""
    echo "🔍 获取Pod状态条件时间..."
    
    SCHEDULED_TIME=$(kubectl get pod $POD -n $NS -o jsonpath='{.status.conditions[?(@.type=="PodScheduled")].lastTransitionTime}')
    INITIALIZED_TIME=$(kubectl get pod $POD -n $NS -o jsonpath='{.status.conditions[?(@.type=="Initialized")].lastTransitionTime}')
    READY_TIME=$(kubectl get pod $POD -n $NS -o jsonpath='{.status.conditions[?(@.type=="Ready")].lastTransitionTime}')
    CONTAINERS_READY_TIME=$(kubectl get pod $POD -n $NS -o jsonpath='{.status.conditions[?(@.type=="ContainersReady")].lastTransitionTime}')
    
    # 3. 获取容器状态时间（类似您脚本中的END_TIME）
    CONTAINER_STARTED_AT=$(kubectl get pod $POD -n $NS -o jsonpath='{.status.containerStatuses[0].state.running.startedAt}')
    
    echo "📅 详细时间点:"
    echo "  Pod创建时间: $POD_CREATE_TIME"
    echo "  Pod调度时间: $SCHEDULED_TIME"
    echo "  Pod初始化时间: $INITIALIZED_TIME"
    echo "  容器启动时间: $CONTAINER_STARTED_AT"
    echo "  容器就绪时间: $CONTAINERS_READY_TIME"
    echo "  Pod就绪时间: $READY_TIME"
    
    # 4. 获取Pod事件（包含更详细的沙箱相关事件）
    echo ""
    echo "📅 Pod事件时间线（查找沙箱相关事件）:"
    kubectl get events -n $NS --field-selector involvedObject.name=$POD --sort-by='.firstTimestamp' -o custom-columns=TIME:.firstTimestamp,REASON:.reason,MESSAGE:.message | grep -E "(Pulling|Pulled|Created|Started|Sandbox)" | head -10
    
    # 5. 精确时间计算（使用Python，类似您脚本中的bc计算）
    if [ -n "$POD_CREATE_TIME" ] && [ -n "$CONTAINER_STARTED_AT" ]; then
        echo ""
        echo "⏱️  精确时间计算:"
        
        # 使用Python进行毫秒级精确计算（替代您脚本中的bc）
        TIMING_RESULT=$(python3 -c "
import datetime
try:
    # 解析时间戳
    start = datetime.datetime.fromisoformat('$POD_CREATE_TIME'.replace('Z', '+00:00'))
    end = datetime.datetime.fromisoformat('$CONTAINER_STARTED_AT'.replace('Z', '+00:00'))
    
    # 计算时间差
    duration = (end - start).total_seconds()
    
    # 格式化输出
    print(f'起始时间: {start.strftime(\"%Y-%m-%d %H:%M:%S.%f\")}')
    print(f'结束时间: {end.strftime(\"%Y-%m-%d %H:%M:%S.%f\")}')
    print(f'沙箱初始化耗时: {duration:.3f}秒')
    print(f'毫秒精度: {duration*1000:.1f}ms')
    
    # 返回耗时
    print(f'DURATION:{duration:.3f}')
except Exception as e:
    print(f'时间计算错误: {e}')
    print('DURATION:0.000')
")
        
        echo "$TIMING_RESULT"
        
        # 提取耗时值
        DURATION=$(echo "$TIMING_RESULT" | grep "DURATION:" | cut -d: -f2)
        
        echo ""
        echo "🎯 沙箱初始化报告:"
        echo "--------------------------------"
        echo "Pod: $POD | Node: $NODE_NAME"
        echo "API 接收时间: $POD_CREATE_TIME"
        echo "容器启动时间: $CONTAINER_STARTED_AT"
        printf "初始化耗时: %s 秒\n" "$DURATION"
        
        # 沙箱复用判断
        if [ -n "$DURATION" ] && [ "$(echo "$DURATION < 3" | bc 2>/dev/null || python3 -c "print($DURATION < 3)")" = "True" ]; then
            echo "🎯 检测结果: 可能复用了沙箱（耗时 < 3秒）"
        else
            echo "🔧 检测结果: 新建沙箱（耗时 >= 3秒）"
        fi
    else
        echo "❌ 无法获取完整的时间信息"
        echo "  Pod创建时间: $POD_CREATE_TIME"
        echo "  容器启动时间: $CONTAINER_STARTED_AT"
    fi
}

# 测试函数
test_with_mock_data() {
    echo ""
    echo "🧪 使用模拟数据测试计算逻辑..."
    
    # 模拟时间戳
    MOCK_POD_CREATE="2025-01-08T10:30:15.123Z"
    MOCK_CONTAINER_START="2025-01-08T10:30:18.456Z"
    
    echo "📊 模拟数据:"
    echo "  Pod创建时间: $MOCK_POD_CREATE"
    echo "  容器启动时间: $MOCK_CONTAINER_START"
    
    # 计算时间差
    MOCK_RESULT=$(python3 -c "
import datetime
try:
    start = datetime.datetime.fromisoformat('$MOCK_POD_CREATE'.replace('Z', '+00:00'))
    end = datetime.datetime.fromisoformat('$MOCK_CONTAINER_START'.replace('Z', '+00:00'))
    duration = (end - start).total_seconds()
    print(f'沙箱初始化耗时: {duration:.3f}秒')
    print(f'毫秒精度: {duration*1000:.1f}ms')
except Exception as e:
    print(f'计算错误: {e}')
")
    
    echo "⏱️  计算结果:"
    echo "$MOCK_RESULT"
}

# 运行测试
echo "📋 功能说明:"
echo "1. 使用Pod创建时间作为起点（与您的脚本相同）"
echo "2. 使用容器启动时间作为终点（替代journalctl方法）"
echo "3. 使用Python进行毫秒级精确计算（替代bc）"
echo "4. 通过kubectl获取所有时间信息（适配Kubernetes环境）"

test_with_mock_data

echo ""
echo "💡 使用方法:"
echo "  improved_sandbox_timing <pod_name> [namespace]"
echo ""
echo "🔧 与您原脚本的对比:"
echo "  ✅ 保持了相同的计算逻辑和精度"
echo "  ✅ 适配了Kubernetes Pod环境"
echo "  ✅ 不需要SSH和节点访问权限"
echo "  ✅ 使用kubectl获取所有必要信息"