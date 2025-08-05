#!/bin/bash

# 测试迭代次数修复的脚本

echo "========================================"
echo "  测试迭代次数修复验证"
echo "========================================"

echo "🔧 修复内容："
echo "1. 修改默认迭代次数从1改为2"
echo "2. 修复所有examples文件中的test-iterations配置"
echo "3. 确保沙箱复用测试能正确执行2次迭代"
echo ""

# 1. 清理现有资源
echo "1. 清理现有资源..."
./scripts/cleanup.sh quick

# 2. 重新部署模板
echo "2. 重新部署模板..."
./scripts/deploy-all.sh --skip-test

# 3. 测试修复后的默认配置
echo "3. 测试修复后的默认配置（应该是2次迭代）..."

# 使用一键部署脚本的自定义模式
echo "4. 模拟自定义部署模式..."

# 创建测试工作流（使用修复后的默认配置）
cat > /tmp/iterations-test.yaml << EOF
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: iterations-test-
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
      value: "iterations-test"
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

kubectl apply -f /tmp/iterations-test.yaml

echo "5. 等待测试启动..."
sleep 10

echo "6. 显示工作流状态..."
kubectl get workflows -n tke-chaos-test

echo ""
echo "7. 监控测试进度（关注迭代次数）..."
echo "   关注以下关键信息："
echo "   - 应该显示：测试迭代: 2 次"
echo "   - 第1次测试：基准测试（首次创建沙箱）"
echo "   - 第2次测试：沙箱复用测试"
echo "   - 企业微信通知中应该显示：总测试: 2次"
echo ""

# 监控日志
kubectl logs -l workflows.argoproj.io/workflow -n tke-chaos-test --tail=100 -f &
LOG_PID=$!

echo "8. 等待120秒后停止日志监控..."
sleep 120
kill $LOG_PID 2>/dev/null

echo ""
echo "========================================"
echo "  预期修复效果："
echo "========================================"
echo "✅ 应该看到：测试迭代: 2 次"
echo "✅ 应该看到2次完整的测试执行："
echo "   - 第1次测试：基准测试（首次创建沙箱）"
echo "   - 第2次测试：沙箱复用测试"
echo "✅ 企业微信通知中应该显示："
echo "   - 总测试: 2次"
echo "   - 基准测试和沙箱复用测试有具体的时间数据"
echo "   - 沙箱复用效果分析有实际的对比"
echo ""
echo "如需查看完整日志，请运行："
echo "kubectl logs -l workflows.argoproj.io/workflow -n tke-chaos-test -f"

# 清理测试文件
rm -f /tmp/iterations-test.yaml