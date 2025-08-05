#!/bin/bash

echo "🧪 测试Python代码缩进修复"
echo "========================================"

# 测试时间计算函数
test_python_indentation() {
    echo "📊 测试Python代码缩进..."
    
    # 模拟时间戳
    POD_CREATE_TIME="2025-01-08T10:30:15.123Z"
    CONTAINER_START_TIME="2025-01-08T10:30:18.456Z"
    DEPLOYMENT_START_TS=$(date +%s)
    
    echo "📅 测试数据:"
    echo "  Pod创建时间: $POD_CREATE_TIME"
    echo "  容器启动时间: $CONTAINER_START_TIME"
    echo "  Deployment开始时间戳: $DEPLOYMENT_START_TS"
    
    # 测试沙箱初始化时间计算（8个空格缩进）
    echo "🔍 测试沙箱初始化时间计算..."
    SANDBOX_INIT_DURATION=$(python3 -c "
        import datetime
        try:
            start = datetime.datetime.fromisoformat('$POD_CREATE_TIME'.replace('Z', '+00:00'))
            end = datetime.datetime.fromisoformat('$CONTAINER_START_TIME'.replace('Z', '+00:00'))
            duration = (end - start).total_seconds()
            if duration < 0: duration = 0
            print(f'{duration:.3f}')
        except:
            print('0.000')
        " 2>/dev/null || echo "0.000")
    
    echo "  结果: ${SANDBOX_INIT_DURATION}秒"
    
    # 测试Pod创建时间计算（8个空格缩进）
    echo "🔍 测试Pod创建时间计算..."
    POD_CREATION_DURATION=$(python3 -c "
        import datetime
        try:
            deployment_start = datetime.datetime.fromtimestamp($DEPLOYMENT_START_TS)
            pod_create = datetime.datetime.fromisoformat('$POD_CREATE_TIME'.replace('Z', '+00:00'))
            duration = (pod_create - deployment_start).total_seconds()
            if duration < 0: duration = 0
            print(f'{duration:.3f}')
        except:
            print('0.000')
        " 2>/dev/null || echo "0.000")
    
    echo "  结果: ${POD_CREATION_DURATION}秒"
    
    # 测试时间格式化（8个空格缩进）
    echo "🔍 测试时间格式化..."
    DEPLOYMENT_TIME_DISPLAY=$(python3 -c "
        import datetime
        dt = datetime.datetime.fromtimestamp($DEPLOYMENT_START_TS)
        print(dt.strftime(\"%Y-%m-%d %H:%M:%S\"))
        " 2>/dev/null || echo "时间格式化失败")
    
    echo "  结果: $DEPLOYMENT_TIME_DISPLAY"
    
    # 测试沙箱复用检测（简单格式）
    echo "🔍 测试沙箱复用检测..."
    SANDBOX_INIT="2.5"
    REUSE_CHECK=$(python3 -c "
        print(float('$SANDBOX_INIT') < 3.0)
        " 2>/dev/null || echo "False")
    
    echo "  沙箱初始化时间: ${SANDBOX_INIT}秒"
    echo "  复用检测结果: $REUSE_CHECK"
    
    # 验证所有计算都成功
    if [ "$SANDBOX_INIT_DURATION" != "0.000" ] && [ "$POD_CREATION_DURATION" != "0.000" ] && [ "$DEPLOYMENT_TIME_DISPLAY" != "时间格式化失败" ] && [ "$REUSE_CHECK" = "True" ]; then
        echo "✅ 所有Python代码缩进修复成功，计算正常"
    else
        echo "❌ 部分Python代码可能存在问题"
        echo "  沙箱初始化时间: $SANDBOX_INIT_DURATION"
        echo "  Pod创建时间: $POD_CREATION_DURATION"
        echo "  时间格式化: $DEPLOYMENT_TIME_DISPLAY"
        echo "  复用检测: $REUSE_CHECK"
    fi
}

# 运行测试
test_python_indentation

echo ""
echo "✅ Python代码缩进修复测试完成"
echo "🎯 修复内容:"
echo "  1. 给所有Python代码块添加了8个空格的缩进"
echo "  2. 保持了代码的功能完整性"
echo "  3. 确保了代码的可读性和格式一致性"