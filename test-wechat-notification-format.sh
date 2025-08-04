#!/bin/bash

# 測試新的企業微信通知格式
echo "🧪 測試新的企業微信通知格式..."

# 模擬測試數據
CLUSTER_ID="tke-cluster"
node_name="eklet-subnet-coaj153k-jwc0uafb"
REPLICAS="10"
TOTAL_TESTS="1"
SUCCESSFUL_TESTS="1"
FAILED_TESTS="0"
TEST_STATUS="SUCCESS"
AVERAGE_TIME="0"
FIRST_TIME="0.0"
SECOND_TIME="0.0"

# 構建符合新格式的通知消息
NOTIFICATION_MESSAGE=$(cat <<EOF
{
"msgtype": "markdown",
"markdown": {
"content": "✅ 超级节点沙箱复用测试完成\\n\\n📋 基础信息\\n- 集群ID: \`$CLUSTER_ID\`\\n- 完成时间: \`$(date '+%Y-%m-%d %H:%M:%S')\`\\n- 测试节点: \`$node_name\`\\n- Pod副本数: $REPLICAS个\\n\\n📊 测试结果\\n- 状态: 全部成功\\n- 总测试: $TOTAL_TESTS次\\n- 成功: $SUCCESSFUL_TESTS次\\n- 失败: $FAILED_TESTS次\\n\\n📋 Pod创建耗时（沙箱初始化）:\\n- 平均: $AVERAGE_TIME秒\\n- 最快: $FIRST_TIME秒\\n- 最慢: $SECOND_TIME秒\\n\\n📊 沙箱复用效果分析:\\n- 基准测试: $FIRST_TIME秒\\n- 沙箱复用: $SECOND_TIME秒\\n- 结论: 两次创建时间相同，沙箱复用可能生效但提升不明显\\n\\n📈 详细分析数据请查看工作流日志"
}
}
EOF
)

echo "📋 生成的通知消息:"
echo "$NOTIFICATION_MESSAGE"

echo ""
echo "✅ 測試完成！新的通知格式已準備就緒。"