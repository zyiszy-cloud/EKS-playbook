#!/bin/bash

# 最终时间计算测试脚本

echo "========================================"
echo "  最终时间计算测试"
echo "========================================"

echo "🔧 最新修复内容："
echo "1. 修复Python时间解析的缩进问题"
echo "2. 添加详细的时间戳解析调试信息"
echo "3. 修复条件判断逻辑（处理空字符串）"
echo "4. 确保至少Python方法能成功解析时间戳"
echo ""

# 1. 本地验证时间戳解析
echo "1. 本地验证时间戳解析..."
TEST_TIME="2025-08-05T06:11:40Z"
PYTHON_RESULT=$(python3 -c "
import datetime
try:
    dt = datetime.datetime.fromisoformat('$TEST_TIME'.replace('Z', '+00:00'))
    print(int(dt.timestamp()))
except:
    print('0')
" 2>/dev/null || echo "0")

echo "测试时间: $TEST_TIME"
echo "Python解析结果: $PYTHON_RESULT"

if [ "$PYTHON_RESULT" != "0" ] && [ -n "$PYTHON_RESULT" ]; then
    echo "✅ Python时间解析正常"
else
    echo "❌ Python时间解析失败，测试可能仍然失败"
fi
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

# 4. 创建测试工作流（2个Pod，2次迭代）
echo "4. 创建最终测试工作流（2个Pod，2次迭代）..."
cat > /tmp/final-time-test.yaml << EOF
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: final-time-test-
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
      value: "final-time-test"
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

kubectl apply -f /tmp/final-time-test.yaml

echo "5. 等待测试启动..."
sleep 10

echo "6. 显示工作流状态..."
kubectl get workflows -n tke-chaos-test

echo ""
echo "7. 监控测试进度（关注完整流程）..."
echo "   🔍 关键检查点："
echo "   - 🔍 时间戳解析调试: 方法3 (Python) 应该成功"
echo "   - 最终结果: 应该不是0"
echo "   - 计算结果: 应该显示合理的时间差"
echo "   - 📊 当前测试的平均时间: 应该不是0秒"
echo "   - 企业微信通知: 应该显示正确的时间数据"
echo ""

# 监控日志
kubectl logs -l workflows.argoproj.io/workflow -n tke-chaos-test --tail=400 -f &
LOG_PID=$!

echo "8. 等待180秒后停止日志监控..."
sleep 180
kill $LOG_PID 2>/dev/null

echo ""
echo "========================================"
echo "  最终验证结果："
echo "========================================"
echo "如果修复成功，应该看到："
echo ""
echo "✅ 时间戳解析调试:"
echo "   - 原始时间: 2025-08-05T06:11:40Z"
echo "   - 方法1 (date -d): [空]"
echo "   - 方法2 (gdate -d): [空]"
echo "   - 方法3 (Python): 1754374300"
echo "   - 最终结果: 1754374300"
echo ""
echo "✅ 调试信息:"
echo "   - POD_CREATE_TS: 1754374300（不再是0）"
echo "   - DEPLOYMENT_START_SEC: 1754374295"
echo "   - 计算结果: 5 = 1754374300 - 1754374295"
echo ""
echo "✅ 当前测试的平均时间: 5.2秒（不再是0）"
echo ""
echo "✅ 企业微信通知:"
echo "   - 基准测试平均: 8.5秒"
echo "   - 沙箱复用平均: 5.2秒"
echo "   - 性能提升: 38.8%"
echo ""
echo "如果仍然是0秒，请检查："
echo "- Python时间解析是否真的成功"
echo "- 条件判断是否通过"
echo "- CURRENT_SANDBOX_INIT_TIMES是否有数据"
echo ""
echo "查看完整日志："
echo "kubectl logs -l workflows.argoproj.io/workflow -n tke-chaos-test -f"

# 清理测试文件
rm -f /tmp/final-time-test.yaml