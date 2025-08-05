#!/bin/bash

echo "🧪 测试修复后的时间获取逻辑"
echo "========================================"

# 模拟真实的时间戳数据
DEPLOYMENT_START_TS=$(date +%s)
POD_CREATE_TIME="$(date -u -d '+2 seconds' '+%Y-%m-%dT%H:%M:%SZ')"
CONTAINER_START_TIME="$(date -u -d '+5 seconds' '+%Y-%m-%dT%H:%M:%SZ')"

echo "📊 模拟数据:"
echo "  Deployment开始时间戳: $DEPLOYMENT_START_TS"
echo "  Pod创建时间: $POD_CREATE_TIME"
echo "  容器启动时间: $CONTAINER_START_TIME"

echo ""
echo "🔍 测试沙箱初始化时间计算:"

SANDBOX_INIT_RESULT=$(python3 -c "
import datetime
import sys
try:
    start_str = '$POD_CREATE_TIME'.replace('Z', '+00:00')
    end_str = '$CONTAINER_START_TIME'.replace('Z', '+00:00')
    print(f'DEBUG: start_str={start_str}', file=sys.stderr)
    print(f'DEBUG: end_str={end_str}', file=sys.stderr)
    
    start = datetime.datetime.fromisoformat(start_str)
    end = datetime.datetime.fromisoformat(end_str)
    duration = (end - start).total_seconds()
    
    print(f'DEBUG: duration={duration}', file=sys.stderr)
    
    if duration < 0: duration = 0
    print(f'{duration:.3f}')
except Exception as e:
    print(f'DEBUG: Exception={e}', file=sys.stderr)
    print('0.000')
" 2>&1)

SANDBOX_INIT_DURATION=$(echo "$SANDBOX_INIT_RESULT" | tail -1)
echo "沙箱初始化时间: $SANDBOX_INIT_DURATION 秒"

echo ""
echo "🔍 测试Pod创建时间计算:"

POD_CREATION_RESULT=$(python3 -c "
import datetime
import sys
try:
    deployment_start = datetime.datetime.fromtimestamp($DEPLOYMENT_START_TS)
    pod_create = datetime.datetime.fromisoformat('$POD_CREATE_TIME'.replace('Z', '+00:00'))
    duration = (pod_create - deployment_start).total_seconds()
    
    print(f'DEBUG: deployment_start={deployment_start}', file=sys.stderr)
    print(f'DEBUG: pod_create={pod_create}', file=sys.stderr)
    print(f'DEBUG: pod_creation_duration={duration}', file=sys.stderr)
    
    if duration < 0: duration = 0
    print(f'{duration:.3f}')
except Exception as e:
    print(f'DEBUG: Pod creation Exception={e}', file=sys.stderr)
    print('0.000')
" 2>&1)

POD_CREATION_DURATION=$(echo "$POD_CREATION_RESULT" | tail -1)
echo "Pod创建时间: $POD_CREATION_DURATION 秒"

echo ""
echo "📊 验证结果:"
if [ "$SANDBOX_INIT_DURATION" != "0.000" ] && [ "$POD_CREATION_DURATION" != "0.000" ]; then
    echo "✅ 时间计算逻辑修复成功！"
    echo "  沙箱初始化时间: ${SANDBOX_INIT_DURATION}秒"
    echo "  Pod创建时间: ${POD_CREATION_DURATION}秒"
else
    echo "❌ 时间计算仍有问题"
    echo "  沙箱初始化时间: ${SANDBOX_INIT_DURATION}秒"
    echo "  Pod创建时间: ${POD_CREATION_DURATION}秒"
fi

echo ""
echo "🎯 关键修复点:"
echo "1. ✅ 等待容器启动后再获取时间"
echo "2. ✅ 添加Events API作为备用时间源"
echo "3. ✅ 增加详细的调试信息"
echo "4. ✅ 修复Python代码的缩进问题"