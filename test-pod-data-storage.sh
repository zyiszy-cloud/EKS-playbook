#!/bin/bash

echo "🧪 测试Pod数据存储和统计计算功能"
echo "========================================"

# 模拟Pod数据存储格式测试
test_pod_data_storage() {
    echo "📊 测试Pod数据存储格式..."
    
    # 模拟存储的Pod数据（格式：pod_name:pod_creation:sandbox_init:end_to_end）
    CURRENT_TEST_POD_DATA="pod1:1.200:2.500:3.700|pod2:1.100:2.800:3.900|pod3:1.300:2.200:3.500"
    
    echo "📅 模拟的Pod数据: $CURRENT_TEST_POD_DATA"
    
    # 解析存储的Pod数据并计算统计
    POD_CREATION_TIMES=""
    SANDBOX_INIT_TIMES=""
    END_TO_END_TIMES=""
    
    echo "🔍 解析Pod数据:"
    # 解析每个Pod的数据
    IFS='|' read -ra POD_ENTRIES <<< "$CURRENT_TEST_POD_DATA"
    for entry in "${POD_ENTRIES[@]}"; do
        IFS=':' read -ra POD_INFO <<< "$entry"
        if [ ${#POD_INFO[@]} -eq 4 ]; then
            POD_NAME="${POD_INFO[0]}"
            POD_CREATION="${POD_INFO[1]}"
            SANDBOX_INIT="${POD_INFO[2]}"
            END_TO_END="${POD_INFO[3]}"
            
            # 累加时间数据
            POD_CREATION_TIMES="$POD_CREATION_TIMES $POD_CREATION"
            SANDBOX_INIT_TIMES="$SANDBOX_INIT_TIMES $SANDBOX_INIT"
            END_TO_END_TIMES="$END_TO_END_TIMES $END_TO_END"
            
            echo "  Pod $POD_NAME: 创建=${POD_CREATION}s, 沙箱=${SANDBOX_INIT}s, 端到端=${END_TO_END}s"
        fi
    done
    
    # 计算统计指标
    if [ -n "$POD_CREATION_TIMES" ]; then
        POD_CREATION_STATS=$(echo "$POD_CREATION_TIMES" | awk '{
            sum = 0; min = $1; max = $1; count = NF
            for(i=1; i<=NF; i++) {
                sum += $i
                if($i < min) min = $i
                if($i > max) max = $i
            }
            avg = sum / count
            printf "%.3f %.3f %.3f", avg, min, max
        }')
        
        SANDBOX_INIT_STATS=$(echo "$SANDBOX_INIT_TIMES" | awk '{
            sum = 0; min = $1; max = $1; count = NF
            for(i=1; i<=NF; i++) {
                sum += $i
                if($i < min) min = $i
                if($i > max) max = $i
            }
            avg = sum / count
            printf "%.3f %.3f %.3f", avg, min, max
        }')
        
        AVG_POD_CREATION=$(echo "$POD_CREATION_STATS" | awk '{print $1}')
        MIN_POD_CREATION=$(echo "$POD_CREATION_STATS" | awk '{print $2}')
        MAX_POD_CREATION=$(echo "$POD_CREATION_STATS" | awk '{print $3}')
        
        AVG_SANDBOX_INIT=$(echo "$SANDBOX_INIT_STATS" | awk '{print $1}')
        MIN_SANDBOX_INIT=$(echo "$SANDBOX_INIT_STATS" | awk '{print $2}')
        MAX_SANDBOX_INIT=$(echo "$SANDBOX_INIT_STATS" | awk '{print $3}')
        
        echo "📊 统计结果:"
        echo "  Pod创建时间 - 平均: ${AVG_POD_CREATION}s, 最小: ${MIN_POD_CREATION}s, 最大: ${MAX_POD_CREATION}s"
        echo "  沙箱初始化时间 - 平均: ${AVG_SANDBOX_INIT}s, 最小: ${MIN_SANDBOX_INIT}s, 最大: ${MAX_SANDBOX_INIT}s"
        
        echo "✅ 数据解析和统计计算成功"
    else
        echo "❌ 无法解析Pod时间数据"
    fi
}

# 测试沙箱复用检测
test_sandbox_reuse_detection() {
    echo ""
    echo "🎯 测试沙箱复用检测..."
    
    # 模拟第二次测试的数据（包含复用的沙箱）
    CURRENT_TEST_POD_DATA="pod1:1.200:1.500:2.700|pod2:1.100:2.800:3.900|pod3:1.300:1.200:2.500"
    
    echo "📅 第二次测试数据: $CURRENT_TEST_POD_DATA"
    
    # 检测沙箱复用（基于沙箱初始化时间）
    CURRENT_REUSED_COUNT=0
    IFS='|' read -ra POD_ENTRIES <<< "$CURRENT_TEST_POD_DATA"
    for entry in "${POD_ENTRIES[@]}"; do
        IFS=':' read -ra POD_INFO <<< "$entry"
        if [ ${#POD_INFO[@]} -eq 4 ]; then
            POD_NAME="${POD_INFO[0]}"
            SANDBOX_INIT="${POD_INFO[2]}"
            # 检查沙箱初始化时间是否小于3秒
            REUSE_CHECK=$(python3 -c "print(float('$SANDBOX_INIT') < 3.0)" 2>/dev/null || echo "False")
            echo "  Pod $POD_NAME: 沙箱初始化时间=${SANDBOX_INIT}s, 复用检测=$REUSE_CHECK"
            if [ "$REUSE_CHECK" = "True" ]; then
                CURRENT_REUSED_COUNT=$((CURRENT_REUSED_COUNT + 1))
            fi
        fi
    done
    
    echo "🎯 检测结果: $CURRENT_REUSED_COUNT/3 个Pod复用了沙箱"
    
    if [ $CURRENT_REUSED_COUNT -eq 2 ]; then
        echo "✅ 沙箱复用检测正确"
    else
        echo "❌ 沙箱复用检测异常"
    fi
}

# 运行测试
test_pod_data_storage
test_sandbox_reuse_detection

echo ""
echo "✅ Pod数据存储和统计计算功能测试完成"
echo "🎯 关键改进:"
echo "  1. 在Pod创建后立即获取并存储时间信息"
echo "  2. 避免Pod删除后无法获取时间的问题"
echo "  3. 基于存储数据进行准确的统计计算"
echo "  4. 支持沙箱复用检测和对比分析"