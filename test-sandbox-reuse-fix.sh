#!/bin/bash

# 测试沙箱复用修复效果的脚本

echo "========================================"
echo "  测试沙箱复用功能修复"
echo "========================================"

echo "🔧 修复内容："
echo "1. 将默认测试迭代次数从1改为2"
echo "2. 修复企业微信通知中的时间字段映射"
echo "3. 确保正确显示基准测试和沙箱复用测试的对比"
echo ""

# 1. 清理现有资源
echo "1. 清理现有资源..."
./scripts/cleanup.sh quick

# 2. 重新部署模板
echo "2. 重新部署模板..."
./scripts/deploy-all.sh --skip-test

# 3. 运行修复后的测试（2次迭代，5个Pod）
echo "3. 运行修复后的测试（2次迭代，5个Pod）..."

# 创建测试工作流
cat > /tmp/sandbox-reuse-test.yaml << EOF
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: sandbox-reuse-fix-test-
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
      value: "sandbox-reuse-fix-test"
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

kubectl apply -f /tmp/sandbox-reuse-test.yaml

echo "4. 等待测试启动..."
sleep 10

echo "5. 显示工作流状态..."
kubectl get workflows -n tke-chaos-test

echo ""
echo "6. 监控测试进度（显示关键日志）..."
echo "   关注以下关键信息："
echo "   - 第1次测试：基准测试（首次创建沙箱）"
echo "   - 第2次测试：沙箱复用测试"
echo "   - 两次测试的时间对比"
echo "   - 企业微信通知的正确数据"
echo ""

# 监控日志
kubectl logs -l workflows.argoproj.io/workflow -n tke-chaos-test --tail=100 -f &
LOG_PID=$!

echo "7. 等待60秒后停止日志监控..."
sleep 60
kill $LOG_PID 2>/dev/null

echo ""
echo "========================================"
echo "  预期修复效果："
echo "========================================"
echo "✅ 应该看到2次测试（基准测试 + 沙箱复用测试）"
echo "✅ 企业微信通知中应该显示："
echo "   - 总测试: 2次"
echo "   - 最快/最慢时间不再是0秒"
echo "   - 基准测试和沙箱复用测试有具体的时间数据"
echo "✅ 沙箱复用效果分析应该有实际的对比数据"
echo ""
echo "如需查看完整日志，请运行："
echo "kubectl logs -l workflows.argoproj.io/workflow -n tke-chaos-test -f"

# 清理测试文件
rm -f /tmp/sandbox-reuse-test.yaml