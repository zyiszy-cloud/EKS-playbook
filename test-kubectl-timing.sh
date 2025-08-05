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

