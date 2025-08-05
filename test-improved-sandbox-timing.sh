#!/bin/bash

echo "🧪 测试改进的沙箱时间计算功能"
echo "========================================"

# 测试精确时间计算函数
test_precise_timing_calculation() {
    echo "📊 测试精确时间计算函数..."
    
    # 模拟时间戳（基于您脚本的格式）
    POD_CREATE_TIME="2025-01-08T10:30:15.123Z"
    CONTAINER_START_TIME="2025-01-08T10:30:18.456Z"
    
    echo "📅 测试数据:"
    echo "  Pod创建时间: $POD_CREATE_TIME"
    echo "  容器启动时间: $CONTAINER_START_TIME"
    
    # 精确时间计算函数（与模板中相同）
    calculate_precise_timing() {
        local pod_create_time="$1"
        local container_start_time="$2"
        local pod_name="$3"
        
        if [ -z "$pod_create_time" ] || [ -z "$container_start_time" ]; then
            echo "0.000"
            return
        fi
        
        # 使用Python进行毫秒级精确计算
        python3 -c "
import datetime
try:
    # 解析时间戳
    start = datetime.datetime.fromisoformat('$pod_create_time'.replace('Z', '+00:00'))
    end = datetime.datetime.fromisoformat('$container_start_time'.replace('Z', '+00:00'))
    
    # 计算时间差
    duration = (end - start).total_seconds()
    
    # 确保非负数
    if duration < 0:
        duration = 0
    
    # 输出结果
    print(f'{duration:.3f}')
except Exception as e:
    print('0.000')
" 2>/dev/null || echo "0.000"
    }
    
    # 执行计算
    RESULT=$(calculate_precise_timing "$POD_CREATE_TIME" "$CONTAINER_START_TIME" "test-pod")
    
    echo "⏱️  计算结果:"
    echo "  沙箱初始化耗时: ${RESULT}秒"
    echo "  毫秒精度: $(echo "$RESULT * 1000" | bc 2>/dev/null || python3 -c "print(f'{float('$RESULT')*1000:.1f}')")ms"
    
    # 验证结果
    EXPECTED="3.333"
    if [ "$RESULT" = "$EXPECTED" ]; then
        echo "✅ 计算结果正确"
    else
        echo "❌ 计算结果异常，期望: $EXPECTED，实际: $RESULT"
    fi
}

test_precise_timing_calculation

echo ""
echo "✅ 改进的沙箱时间计算功能测试完成"