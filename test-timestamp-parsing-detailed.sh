#!/bin/bash

# 详细测试时间戳解析的脚本

echo "========================================"
echo "  详细测试时间戳解析"
echo "========================================"

# 1. 本地测试时间戳解析
echo "1. 本地测试时间戳解析..."
TEST_TIME="2025-08-05T06:11:40Z"
echo "测试时间: $TEST_TIME"
echo ""

echo "方法1 - date -d:"
RESULT1=$(date -d "$TEST_TIME" +%s 2>/dev/null || echo "")
echo "  结果: '$RESULT1'"
echo "  是否为空: $([ -z "$RESULT1" ] && echo "是" || echo "否")"

echo ""
echo "方法2 - gdate -d:"
RESULT2=$(gdate -d "$TEST_TIME" +%s 2>/dev/null || echo "")
echo "  结果: '$RESULT2'"
echo "  是否为空: $([ -z "$RESULT2" ] && echo "是" || echo "否")"

echo ""
echo "方法3 - Python:"
RESULT3=$(python3 -c "
import datetime
try:
    dt = datetime.datetime.fromisoformat('$TEST_TIME'.replace('Z', '+00:00'))
    print(int(dt.timestamp()))
except:
    print('0')
" 2>/dev/null || echo "0")
echo "  结果: '$RESULT3'"
echo "  是否为0: $([ "$RESULT3" = "0" ] && echo "是" || echo "否")"

echo ""
echo "预期Unix时间戳: $(date +%s)"
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

# 4. 创建测试工作流（1个Pod，便于调试）
echo "4. 创建测试工作流（1个Pod，1次迭代）..."
cat > /tmp/timestamp-detailed-test.yaml << EOF
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: timestamp-detailed-test-
  namespace: tke-chaos-test
spec:
  serviceAccountName: tke-chaos
  entrypoint: deployment-sandbox-test
  arguments:
    parameters:
    - name: cluster-id
      value: "test-cluster"
    - name: webhook-url
      value: ""
    - name: kubeconfig-secret-name
      value: ""
    - name: namespace
      value: "tke-chaos-test"
    - name: deployment-name-prefix
      value: "timestamp-detailed-test"
    - name: replicas
      value: "1"
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
      value: "1"
    - name: delay-between-tests
      value: "10s"
  workflowTemplateRef:
    name: supernode-sandbox-deployment-template
    clusterScope: true
EOF

kubectl apply -f /tmp/timestamp-detailed-test.yaml

echo "5. 等待测试启动..."
sleep 10

echo "6. 显示工作流状态..."
kubectl get workflows -n tke-chaos-test

echo ""
echo "7. 监控测试进度（重点关注时间戳解析详情）..."
echo "   🔍 关键检查点："
echo "   - 🔍 时间戳解析调试: 应该显示每种方法的结果"
echo "   - 原始时间: 应该是ISO格式"
echo "   - 方法1/2/3: 至少一种方法应该成功"
echo "   - 最终结果: 应该不是0"
echo ""

# 监控日志
kubectl logs -l workflows.argoproj.io/workflow -n tke-chaos-test --tail=200 -f &
LOG_PID=$!

echo "8. 等待60秒后停止日志监控..."
sleep 60
kill $LOG_PID 2>/dev/null

echo ""
echo "========================================"
echo "  分析结果："
echo "========================================"
echo "请检查日志中的时间戳解析调试信息："
echo ""
echo "1. 原始时间: 应该是ISO格式（如：2025-08-05T06:11:40Z）"
echo "2. 方法1 (date -d): 可能为空（系统不支持）"
echo "3. 方法2 (gdate -d): 可能为空（macOS上可能有值）"
echo "4. 方法3 (Python): 应该有值（通用方案）"
echo "5. 最终结果: 应该不是0"
echo ""
echo "如果最终结果仍然是0，说明所有解析方法都失败了"
echo ""
echo "查看完整日志："
echo "kubectl logs -l workflows.argoproj.io/workflow -n tke-chaos-test -f"

# 清理测试文件
rm -f /tmp/timestamp-detailed-test.yaml