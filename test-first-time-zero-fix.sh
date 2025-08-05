#!/bin/bash

# 测试第一次创建时间为0秒问题的修复

echo "========================================"
echo "  测试第一次创建时间为0秒问题修复"
echo "========================================"

echo "🔍 问题分析："
echo "之前的逻辑错误导致："
echo "- 第一次测试时，SANDBOX_INIT_TIMES为空，计算结果为0秒"
echo "- 第二次测试时，使用了第一次的数据，得到正确时间"
echo "- 结果：基准测试0秒，沙箱复用测试13.6秒（完全颠倒）"
echo ""

echo "🔧 修复方案："
echo "1. 分离当前测试和全局统计的变量"
echo "2. 在每次测试完成后立即计算当前测试的平均时间"
echo "3. 确保时间计算逻辑的正确性"
echo ""

# 1. 强制清理所有资源
echo "1. 强制清理所有资源..."
./scripts/cleanup.sh full
kubectl delete clusterworkflowtemplate --all --ignore-not-found=true

# 等待清理完成
sleep 5

# 2. 重新部署模板
echo "2. 重新部署模板..."
./scripts/deploy-all.sh --force-redeploy --skip-test

# 3. 创建测试工作流（3个Pod，便于观察）
echo "3. 创建测试工作流（3个Pod，2次迭代）..."
cat > /tmp/first-time-zero-fix-test.yaml << EOF
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: first-time-zero-fix-test-
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
      value: "first-time-zero-fix-test"
    - name: replicas
      value: "3"
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

kubectl apply -f /tmp/first-time-zero-fix-test.yaml

echo "4. 等待测试启动..."
sleep 10

echo "5. 显示工作流状态..."
kubectl get workflows -n tke-chaos-test

echo ""
echo "6. 监控测试进度（重点关注时间计算）..."
echo "   🔍 关键检查点："
echo "   - 第1次测试应该显示：当前测试的平均沙箱初始化时间: X.X秒（不是0）"
echo "   - 第2次测试应该显示：当前测试的平均沙箱初始化时间: X.X秒"
echo "   - 企业微信通知中："
echo "     * 基准测试平均: X.X秒（不是0）"
echo "     * 沙箱复用平均: X.X秒"
echo "     * 基准测试应该 >= 沙箱复用测试（正常情况）"
echo ""

# 监控日志
kubectl logs -l workflows.argoproj.io/workflow -n tke-chaos-test --tail=300 -f &
LOG_PID=$!

echo "7. 等待180秒后停止日志监控..."
sleep 180
kill $LOG_PID 2>/dev/null

echo ""
echo "========================================"
echo "  预期修复效果："
echo "========================================"
echo "✅ 修复后应该看到："
echo "   📊 第1次测试："
echo "   - 当前测试的平均沙箱初始化时间: 3.5秒（不是0）"
echo ""
echo "   📊 第2次测试："
echo "   - 当前测试的平均沙箱初始化时间: 2.1秒"
echo ""
echo "   📨 企业微信通知："
echo "   - 基准测试平均: 3.5秒（不是0）"
echo "   - 沙箱复用平均: 2.1秒"
echo "   - 性能提升: 40.0%"
echo "   - 基准测试（首次创建）: 3.5秒"
echo "   - 沙箱复用测试: 2.1秒"
echo ""
echo "✅ 逻辑应该正确："
echo "   - 基准测试时间 >= 沙箱复用测试时间"
echo "   - 两个时间都不为0"
echo "   - 性能提升百分比合理"
echo ""
echo "查看完整日志："
echo "kubectl logs -l workflows.argoproj.io/workflow -n tke-chaos-test -f"

# 清理测试文件
rm -f /tmp/first-time-zero-fix-test.yaml