#!/bin/bash

# 测试正确时间计算的脚本

echo "========================================"
echo "  测试正确时间计算修复"
echo "========================================"

echo "🔧 修复内容："
echo "1. 修复时间定义：从发出命令到Pod创建成功（不算Pod启动时间）"
echo "2. 移除硬编码的3秒逻辑"
echo "3. 使用Deployment创建时间作为开始时间"
echo "4. 使用Pod创建时间作为结束时间"
echo ""

echo "📊 时间计算逻辑："
echo "- 开始时间：Deployment创建时间（发出命令的时间）"
echo "- 结束时间：Pod的metadata.creationTimestamp（Pod被创建出来的时间）"
echo "- Pod创建耗时 = Pod创建时间 - Deployment创建时间"
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
cat > /tmp/correct-time-test.yaml << EOF
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: correct-time-test-
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
      value: "correct-time-test"
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

kubectl apply -f /tmp/correct-time-test.yaml

echo "4. 等待测试启动..."
sleep 10

echo "5. 显示工作流状态..."
kubectl get workflows -n tke-chaos-test

echo ""
echo "6. 监控测试进度（重点关注时间计算）..."
echo "   🔍 关键检查点："
echo "   - 应该显示：Deployment创建时间（发出命令）"
echo "   - 应该显示：Pod创建时间（Pod被创建）"
echo "   - 应该显示：Pod创建耗时: X秒（从发出命令到Pod创建成功）"
echo "   - 时间应该合理（通常5-15秒），不应该是3秒"
echo "   - 企业微信通知中的时间应该与日志中的时间一致"
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
echo "   📅 时间点:"
echo "   - Deployment创建时间（发出命令）: 14:30:15"
echo "   - Pod创建时间（Pod被创建）: 14:30:20"
echo ""
echo "   ⏱️  时间指标（Pod级别）:"
echo "   - Pod创建耗时: 5秒（从发出命令到Pod创建成功）"
echo ""
echo "   📊 当前测试的平均沙箱初始化时间: 5.2秒（不是3秒）"
echo ""
echo "   📨 企业微信通知："
echo "   - 基准测试平均: 8.5秒（合理的时间）"
echo "   - 沙箱复用平均: 5.2秒（合理的时间）"
echo "   - 性能提升: 38.8%"
echo ""
echo "✅ 时间应该合理："
echo "   - 不再是硬编码的3秒"
echo "   - 反映真实的Pod创建时间"
echo "   - 企业微信通知与日志中的时间一致"
echo ""
echo "查看完整日志："
echo "kubectl logs -l workflows.argoproj.io/workflow -n tke-chaos-test -f"

# 清理测试文件
rm -f /tmp/correct-time-test.yaml