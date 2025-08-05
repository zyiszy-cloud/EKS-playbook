#!/bin/bash

# 测试时间指标修复的脚本

echo "========================================"
echo "  测试时间指标修复"
echo "========================================"

echo "🔧 本次修复内容："
echo "1. 修复Pod创建时间定义：使用沙箱初始化时间（不含启动时间）"
echo "2. 修复企业微信通知中的时间指标含义"
echo "3. 添加沙箱复用覆盖率统计"
echo "4. 明确区分基准测试和沙箱复用测试的时间"
echo ""

echo "📊 时间指标说明："
echo "- Pod创建时间 = 容器启动时间 - Pod创建时间（不含Pod启动时间）"
echo "- 基准测试 = 第1次测试的平均时间"
echo "- 沙箱复用测试 = 第2次测试的平均时间"
echo "- 沙箱复用覆盖率 = 第2次测试中复用沙箱的Pod数量/总Pod数量"
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

# 3. 创建测试工作流
echo "3. 创建测试工作流（5个Pod，2次迭代）..."
cat > /tmp/time-metrics-test.yaml << EOF
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: time-metrics-test-
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
      value: "time-metrics-test"
    - name: replicas
      value: "5"
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

kubectl apply -f /tmp/time-metrics-test.yaml

echo "4. 等待测试启动..."
sleep 10

echo "5. 显示工作流状态..."
kubectl get workflows -n tke-chaos-test

echo ""
echo "6. 监控测试进度（重点关注时间指标）..."
echo "   🔍 关键检查点："
echo "   - 应该显示：测试迭代: 2"
echo "   - 应该显示：第1次测试：基准测试"
echo "   - 应该显示：第2次测试：沙箱复用测试"
echo "   - 应该显示：当前测试的平均沙箱初始化时间"
echo "   - 企业微信通知应该显示正确的时间指标和沙箱复用覆盖率"
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
echo "✅ 企业微信通知中应该显示："
echo "   📋 Pod创建时间（不含启动时间）:"
echo "   - 基准测试平均: X.X秒"
echo "   - 沙箱复用平均: X.X秒"
echo "   - 性能提升: XX.X%"
echo ""
echo "   📊 沙箱复用效果分析:"
echo "   - 基准测试（首次创建）: X.X秒"
echo "   - 沙箱复用测试: X.X秒"
echo "   - 沙箱复用覆盖率: XX% (X/5个Pod)"
echo "   - 结论: 沙箱复用生效，性能提升明显"
echo ""
echo "✅ 时间指标含义："
echo "   - Pod创建时间 = 沙箱初始化时间（不含Pod启动时间）"
echo "   - 基准测试 = 第1次测试的平均时间"
echo "   - 沙箱复用测试 = 第2次测试的平均时间"
echo ""
echo "查看完整日志："
echo "kubectl logs -l workflows.argoproj.io/workflow -n tke-chaos-test -f"

# 清理测试文件
rm -f /tmp/time-metrics-test.yaml