#!/bin/bash

echo "🧪 测试时区修复"
echo "========================================"

# 使用Python生成时间戳（跨平台兼容）
DEPLOYMENT_START_TS=$(date +%s)

# 生成模拟的Kubernetes时间戳
POD_CREATE_TIME=$(python3 -c "
import datetime
now = datetime.datetime.now(datetime.timezone.utc)
pod_time = now + datetime.timedelta(seconds=2)
print(pod_time.isoformat().replace('+00:00', 'Z'))
")

CONTAINER_START_TIME=$(python3 -c "
import datetime
now = datetime.datetime.now(datetime.timezone.utc)
container_time = now + datetime.timedelta(seconds=5)
print(container_time.isoformat().replace('+00:00', 'Z'))
")

echo "📊 模拟数据:"
echo "  Deployment开始时间戳: $DEPLOYMENT_START_TS"
echo "  Pod创建时间: $POD_CREATE_TIME"
echo "  容器启动时间: $CONTAINER_START_TIME"

echo ""
echo "🔍 测试修复后的Pod创建时间计算:"

POD_CREATION_RESULT=$(python3 -c "
import datetime
import sys
try:
    # 使用UTC时区创建deployment_start时间
    deployment_start = datetime.datetime.fromtimestamp($DEPLOYMENT_START_TS, tz=datetime.timezone.utc)
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

echo "完整输出:"
echo "$POD_CREATION_RESULT"
echo ""

POD_CREATION_DURATION=$(echo "$POD_CREATION_RESULT" | tail -1)
echo "Pod创建时间: $POD_CREATION_DURATION 秒"

echo ""
echo "🔍 测试端到端时间计算:"

END_TO_END_RESULT=$(python3 -c "
import datetime
import sys
try:
    # 使用UTC时区创建deployment_start时间
    deployment_start = datetime.datetime.fromtimestamp($DEPLOYMENT_START_TS, tz=datetime.timezone.utc)
    container_start = datetime.datetime.fromisoformat('$CONTAINER_START_TIME'.replace('Z', '+00:00'))
    duration = (container_start - deployment_start).total_seconds()
    
    print(f'DEBUG: deployment_start={deployment_start}', file=sys.stderr)
    print(f'DEBUG: container_start={container_start}', file=sys.stderr)
    print(f'DEBUG: end_to_end_duration={duration}', file=sys.stderr)
    
    if duration < 0: duration = 0
    print(f'{duration:.3f}')
except Exception as e:
    print(f'DEBUG: End-to-end Exception={e}', file=sys.stderr)
    print('0.000')
" 2>&1)

echo "完整输出:"
echo "$END_TO_END_RESULT"
echo ""

END_TO_END_DURATION=$(echo "$END_TO_END_RESULT" | tail -1)
echo "端到端时间: $END_TO_END_DURATION 秒"

echo ""
echo "📊 验证结果:"
if [ "$POD_CREATION_DURATION" != "0.000" ] && [ "$END_TO_END_DURATION" != "0.000" ]; then
    echo "✅ 时区问题修复成功！"
    echo "  Pod创建时间: ${POD_CREATION_DURATION}秒"
    echo "  端到端时间: ${END_TO_END_DURATION}秒"
else
    echo "❌ 时区问题仍未解决"
    echo "  Pod创建时间: ${POD_CREATION_DURATION}秒"
    echo "  端到端时间: ${END_TO_END_DURATION}秒"
fi