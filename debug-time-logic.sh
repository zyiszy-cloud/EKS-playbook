#!/bin/bash

echo "🔍 调试时间获取逻辑问题"
echo "========================================"

# 分析问题的可能原因
echo "📊 分析可能的问题原因:"
echo "1. Pod创建后立即获取时间，但容器可能还未启动"
echo "2. kubectl jsonpath查询可能返回空值"
echo "3. Python时间计算可能进入except分支"
echo "4. 时间戳格式解析可能失败"

echo ""
echo "🧪 模拟调试kubectl获取Pod信息..."

# 模拟kubectl命令测试
echo "测试kubectl命令是否能获取到时间信息:"

# 创建一个测试脚本来模拟kubectl获取时间的过程
cat << 'EOF' > test-kubectl-timing.sh
#!/bin/bash

echo "🔍 测试kubectl获取Pod时间信息的逻辑"

# 模拟Pod刚创建时的状态
echo "📊 模拟Pod刚创建时的状态:"
echo "  Pod创建时间: 有值 (metadata.creationTimestamp)"
echo "  容器启动时间: 可能为空 (status.containerStatuses[0].state.running.startedAt)"
echo "  Pod状态条件: 可能部分为空"

echo ""
echo "🚨 问题分析:"
echo "1. Pod创建后立即获取时间，容器可能还在拉取镜像"
echo "2. containerStatuses[0].state.running.startedAt 在容器未启动时为空"
echo "3. 如果CONTAINER_START_TIME为空，Python计算会进入except分支返回0.000"

echo ""
echo "💡 解决方案:"
echo "1. 等待容器启动后再获取时间"
echo "2. 使用Pod事件时间作为备用"
echo "3. 使用metrics API获取更准确的时间"
echo "4. 增加重试机制"

EOF

chmod +x test-kubectl-timing.sh
./test-kubectl-timing.sh

echo ""
echo "🔧 问题根本原因分析:"
echo "当Pod刚创建时:"
echo "  ✅ POD_CREATE_TIME: 有值"
echo "  ❌ CONTAINER_START_TIME: 为空（容器还未启动）"
echo "  ❌ 其他状态时间: 大部分为空"

echo ""
echo "📋 这导致了以下问题:"
echo "1. if [ -n \"\$POD_CREATE_TIME\" ] && [ -n \"\$CONTAINER_START_TIME\" ] 条件不满足"
echo "2. 进入 elif [ -n \"\$POD_CREATE_TIME\" ] 分支"
echo "3. 只能计算Pod创建时间，沙箱初始化时间设为0.000"
echo "4. 最终所有时间指标都是0.000"

echo ""
echo "🎯 修复策略:"
echo "1. 等待容器启动后再获取时间"
echo "2. 使用Pod Ready事件作为容器启动的标志"
echo "3. 增加重试机制，多次尝试获取容器启动时间"
echo "4. 使用Kubernetes Events API获取更详细的时间信息"