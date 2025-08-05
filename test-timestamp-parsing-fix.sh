#!/bin/bash

# 测试时间戳解析修复的脚本

echo "========================================"
echo "  测试时间戳解析修复"
echo "========================================"

echo "🔧 修复内容："
echo "1. 修复date -d命令无法解析ISO时间格式的问题"
echo "2. 添加多种时间戳解析方法（date, gdate, Python）"
echo "3. 确保POD_CREATE_TS不再是0"
echo ""

echo "🔍 问题分析："
echo "- POD_CREATE_TIME: 2025-08-05T06:11:40Z（有值）"
echo "- POD_CREATE_TS: 0（解析失败）"
echo "- 原因：date -d命令在某些系统上不支持ISO格式"
echo ""

# 1. 测试本地时间戳解析
echo "1. 测试本地时间戳解析能力..."
TEST_TIME="2025-08-05T06:11:40Z"
echo "测试时间: $TEST_TIME"

echo "方法1 - date -d:"
RESULT1=$(date -d "$TEST_TIME" +%s 2>/dev/null || echo "失败")
echo "  结果: $RESULT1"

echo "方法2 - gdate -d:"
RESULT2=$(gdate -d "$TEST_TIME" +%s 2>/dev/null || echo "失败")
echo "  结果: $RESULT2"

echo "方法3 - Python:"
RESULT3=$(python3 -c "
import datetime
try:
    dt = datetime.datetime.fromisoformat('$TEST_TIME'.replace('Z', '+00:00'))
    print(int(dt.timestamp()))
except:
    print('失败')
" 2>/dev/null || echo "失败")
echo "  结果: $RESULT3"

echo ""

# 2. 强制清理所有资源
echo "2. 强制清理所有资源..."
./scripts/cleanup.sh full
kubectl delete clusterworkflowtemplate --all --ignore-not-found=true

# 等待清理完成
sleep 5

# 3. 重新部署模板
echo "3. 重新部署模板..."
./scripts/deploy-all.sh --force-redeploy --skip-test

# 4. 创建测试工作流（2个Pod，便于观察）
echo "4. 创建测试工作流（2个Pod，2次迭代）..."
cat > /tmp/timestamp-parsing-test.yaml << EOF
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: timestamp-parsing-test-
  namespace: tke-chaos-test
spec:
  serviceAccountName: tke-chaos
  entrypoint: deployment-sandbox-test
  arguments:
    parameters:
    - name: cluster-id
      value: "test-cluster"
    - name: webhook-url
      value: "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=ddd60f9a-3044-498d-b44e-9f9e77ad834c"
    - name: kubeconfig-secret-name
      value: ""
    - name: namespace
      value: "tke-chaos-test"
    - name: deployment-name-prefix
      value: "timestamp-parsing-test"
    - name: replicas
      value: "2"
    - name: pod-image
      value: "nginx:alpine"
    - name: cpu-request
      value: "50m"
    - name: memory-request
      value: "64Mi"
    - name: cpu-limit
      value: "100m"
    - name: memory-limit
      value: "128Mi"
    - name: test-iterations
      value: "2"
    - name: delay-between-tests
      value: "30s"
  workflowTemplateRef:
    name: supernode-sandbox-deployment-template
    clusterScope: true
EOF

kubectl apply -f /tmp/timestamp-parsing-test.yaml

echo "5. 等待测试启动..."
sleep 10

echo "6. 显示工作流状态..."
kubectl get workflows -n tke-chaos-test

echo ""
echo "7. 监控测试进度（重点关注时间戳解析）..."
echo "   🔍 关键检查点："
echo "   - POD_CREATE_TS: 应该不再是0，应该是Unix时间戳"
echo "   - 不应该再看到'无法获取Pod的准确时间，跳过'"
echo "   - 应该看到'计算结果: X = timestamp1 - timestamp2'"
echo "   - 📊 当前测试的平均沙箱初始化时间: 应该不是0秒"
echo ""

# 监控日志
kubectl logs -l workflows.argoproj.io/workflow -n tke-chaos-test --tail=300 -f &
LOG_PID=$!

echo "8. 等待120秒后停止日志监控..."
sleep 120
kill $LOG_PID 2>/dev/null

echo ""
echo "========================================"
echo "  预期修复效果："
echo "========================================"
echo "✅ 修复后应该看到："
echo "   🔍 调试信息:"
echo "   - POD_CREATE_TIME: 2025-08-05T06:11:40Z"
echo "   - POD_CREATE_TS: 1754374300（不再是0）"
echo "   - DEPLOYMENT_START_SEC: 1754374295"
echo "   - 计算结果: 5 = 1754374300 - 1754374295"
echo ""
echo "   📊 当前测试的平均沙箱初始化时间: 5.2秒（不再是0）"
echo ""
echo "   📨 企业微信通知："
echo "   - 基准测试平均: 8.5秒（不再是0）"
echo "   - 沙箱复用平均: 5.2秒（不再是0）"
echo "   - 性能提升: 38.8%"
echo ""
echo "✅ 不应该再看到："
echo "   - POD_CREATE_TS: 0"
echo "   - ⚠️ 无法获取Pod的准确时间，跳过"
echo "   - 所有Pod都被跳过的情况"
echo ""
echo "查看完整日志："
echo "kubectl logs -l workflows.argoproj.io/workflow -n tke-chaos-test -f"

# 清理测试文件
rm -f /tmp/timestamp-parsing-test.yaml