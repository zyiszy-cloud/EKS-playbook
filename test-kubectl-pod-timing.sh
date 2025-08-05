#!/bin/bash

echo "🧪 测试kubectl Pod时间计算功能"
echo "========================================"

# 模拟kubectl命令输出的测试函数
test_kubectl_pod_timing() {
    echo "📊 测试kubectl获取Pod信息并计算时间的功能..."
    
    # 模拟时间戳
    DEPLOYMENT_START_SEC=$(date +%s)
    echo "🔍 Deployment开始时间戳: $DEPLOYMENT_START_SEC"
    
    # 模拟Pod信息（使用真实的Kubernetes时间戳格式）
    POD_CREATE_TIME="2025-01-08T10:30:15Z"
    CONTAINER_START_TIME="2025-01-08T10:30:18Z"
    POD_SCHEDULED_TIME="2025-01-08T10:30:16Z"
    
    echo "📅 模拟的Pod时间信息:"
    echo "  Pod创建时间: $POD_CREATE_TIME"
    echo "  Pod调度时间: $POD_SCHEDULED_TIME"
    echo "  容器启动时间: $CONTAINER_START_TIME"
    
    # 🔧 多层时间戳解析策略（兼容不同系统）
    parse_timestamp() {
        local timestamp="$1"
        local result=""
        
        if [ -z "$timestamp" ]; then
            echo "0"
            return
        fi
        
        echo "  🔍 解析时间戳: $timestamp" >&2
        
        # 方法1: 使用date -d (GNU date)
        result=$(date -d "$timestamp" +%s 2>/dev/null || echo "")
        if [ -n "$result" ] && [ "$result" != "0" ] && [[ "$result" =~ ^[0-9]+$ ]]; then
            echo "    方法1 (date -d): $result" >&2
            echo "$result"
            return
        fi
        
        # 方法2: 使用gdate -d (macOS with GNU coreutils)
        result=$(gdate -d "$timestamp" +%s 2>/dev/null || echo "")
        if [ -n "$result" ] && [ "$result" != "0" ] && [[ "$result" =~ ^[0-9]+$ ]]; then
            echo "    方法2 (gdate -d): $result" >&2
            echo "$result"
            return
        fi
        
        # 方法3: 使用Python解析ISO 8601格式
        result=$(python3 -c "
import datetime
try:
    # 处理Kubernetes时间戳格式
    ts = '$timestamp'
    if ts.endswith('Z'):
        ts = ts[:-1] + '+00:00'
    dt = datetime.datetime.fromisoformat(ts)
    print(int(dt.timestamp()))
except Exception as e:
    print('0')
" 2>/dev/null || echo "0")
        
        echo "    方法3 (Python): $result" >&2
        
        # 验证结果是纯数字
        if [[ "$result" =~ ^[0-9]+$ ]]; then
            echo "$result"
        else
            echo "0"
        fi
    }
    
    # 解析各个时间戳
    echo "🔧 解析时间戳..."
    POD_CREATE_TS=$(parse_timestamp "$POD_CREATE_TIME")
    POD_SCHEDULED_TS=$(parse_timestamp "$POD_SCHEDULED_TIME")
    CONTAINER_START_TS=$(parse_timestamp "$CONTAINER_START_TIME")
    
    echo "📊 解析结果:"
    echo "  Pod创建时间戳: $POD_CREATE_TS"
    echo "  Pod调度时间戳: $POD_SCHEDULED_TS"
    echo "  容器启动时间戳: $CONTAINER_START_TS"
    echo "  Deployment开始时间戳: $DEPLOYMENT_START_SEC"
    
    # 🎯 计算关键时间指标
    if [ "$POD_CREATE_TS" -gt 0 ] && [ "$DEPLOYMENT_START_SEC" -gt 0 ]; then
        # 1. Pod创建时间（从发出命令到Pod被创建）
        POD_CREATION_TIME=$((POD_CREATE_TS - DEPLOYMENT_START_SEC))
        [ $POD_CREATION_TIME -lt 0 ] && POD_CREATION_TIME=0
        
        # 2. 沙箱初始化时间（从Pod创建到容器启动）
        SANDBOX_INIT_TIME=0
        if [ "$CONTAINER_START_TS" -gt 0 ] && [ "$POD_CREATE_TS" -gt 0 ]; then
            SANDBOX_INIT_TIME=$((CONTAINER_START_TS - POD_CREATE_TS))
            [ $SANDBOX_INIT_TIME -lt 0 ] && SANDBOX_INIT_TIME=0
        fi
        
        # 3. 端到端时间（从发出命令到容器启动）
        END_TO_END_TIME=0
        if [ "$CONTAINER_START_TS" -gt 0 ] && [ "$DEPLOYMENT_START_SEC" -gt 0 ]; then
            END_TO_END_TIME=$((CONTAINER_START_TS - DEPLOYMENT_START_SEC))
            [ $END_TO_END_TIME -lt 0 ] && END_TO_END_TIME=0
        fi
        
        # 格式化时间显示
        format_time() {
            local ts="$1"
            if [ "$ts" -gt 0 ]; then
                date -d "@$ts" +"%H:%M:%S" 2>/dev/null || echo "$(date -r $ts +"%H:%M:%S" 2>/dev/null || echo "未知")"
            else
                echo "未知"
            fi
        }
        
        DEPLOYMENT_START_DISPLAY=$(format_time "$DEPLOYMENT_START_SEC")
        POD_CREATE_DISPLAY=$(format_time "$POD_CREATE_TS")
        CONTAINER_START_DISPLAY=$(format_time "$CONTAINER_START_TS")
        
        echo "⏱️  时间线分析:"
        echo "  ${DEPLOYMENT_START_DISPLAY} - 发出Deployment创建命令"
        echo "  ${POD_CREATE_DISPLAY} - Pod被创建 (耗时: ${POD_CREATION_TIME}秒)"
        if [ "$CONTAINER_START_TS" -gt 0 ]; then
            echo "  ${CONTAINER_START_DISPLAY} - 容器启动 (沙箱初始化: ${SANDBOX_INIT_TIME}秒)"
        fi
        
        echo "📊 时间指标计算结果:"
        echo "  Pod创建耗时: ${POD_CREATION_TIME}秒（从命令到Pod创建）"
        echo "  沙箱初始化耗时: ${SANDBOX_INIT_TIME}秒（从Pod创建到容器启动）"
        echo "  端到端耗时: ${END_TO_END_TIME}秒（从命令到容器启动）"
        
        # 验证计算逻辑
        echo "🔍 验证计算逻辑:"
        echo "  Pod创建时间 = $POD_CREATE_TS - $DEPLOYMENT_START_SEC = $POD_CREATION_TIME"
        echo "  沙箱初始化时间 = $CONTAINER_START_TS - $POD_CREATE_TS = $SANDBOX_INIT_TIME"
        echo "  端到端时间 = $CONTAINER_START_TS - $DEPLOYMENT_START_SEC = $END_TO_END_TIME"
        
        if [ $((POD_CREATION_TIME + SANDBOX_INIT_TIME)) -eq $END_TO_END_TIME ]; then
            echo "✅ 时间计算逻辑正确"
        else
            echo "❌ 时间计算逻辑有误"
        fi
        
    else
        echo "❌ 无法获取有效的时间戳"
    fi
}

# 测试时间戳解析兼容性
test_timestamp_parsing() {
    echo ""
    echo "🧪 测试时间戳解析兼容性..."
    
    # 测试不同格式的时间戳
    test_timestamps=(
        "2025-01-08T10:30:15Z"
        "2025-01-08T10:30:15.123Z"
        "2025-01-08T10:30:15+00:00"
        "2025-01-08T10:30:15.123456Z"
    )
    
    for ts in "${test_timestamps[@]}"; do
        echo "📅 测试时间戳: $ts"
        
        # 方法1: date -d
        result1=$(date -d "$ts" +%s 2>/dev/null || echo "失败")
        echo "  date -d: $result1"
        
        # 方法2: gdate -d
        result2=$(gdate -d "$ts" +%s 2>/dev/null || echo "失败")
        echo "  gdate -d: $result2"
        
        # 方法3: Python
        result3=$(python3 -c "
import datetime
try:
    ts = '$ts'
    if ts.endswith('Z'):
        ts = ts[:-1] + '+00:00'
    dt = datetime.datetime.fromisoformat(ts)
    print(int(dt.timestamp()))
except:
    print('失败')
" 2>/dev/null || echo "失败")
        echo "  Python: $result3"
        echo ""
    done
}

# 运行测试
test_kubectl_pod_timing
test_timestamp_parsing

echo "✅ kubectl Pod时间计算功能测试完成"