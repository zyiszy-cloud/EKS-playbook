#!/bin/bash

# 测试unary operator错误修复的脚本

echo "========================================"
echo "  测试unary operator错误修复"
echo "========================================"

echo "🔧 修复内容："
echo "1. 修复SUCCESS_RATE计算中的unary operator错误"
echo "2. 修复COUNT变量使用错误（改为ITERATIONS）"
echo "3. 修复STARTUP_TIMES变量的收集和使用"
echo "4. 修复硬编码的除数问题"
echo "5. 增加变量安全检查"
echo ""

# 1. 清理现有资源
echo "1. 清理现有资源..."
./scripts/cleanup.sh quick

# 2. 重新部署模板
echo "2. 重新部署模板..."
./scripts/deploy-all.sh --skip-test

# 3. 运行修复后的测试（2次迭代，3个Pod）
echo "3. 运行修复后的测试（2次迭代，3个Pod）..."

# 创建测试工作流
cat > /tmp/unary-fix-test.yaml << EOF
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: unary-fix-test-
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
      value: "unary-fix-test"
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

kubectl apply -f /tmp/unary-fix-test.yaml

echo "4. 等待测试启动..."
sleep 10

echo "5. 显示工作流状态..."
kubectl get workflows -n tke-chaos-test

echo ""
echo "6. 监控测试进度（关注错误修复）..."
echo "   关注以下修复点："
echo "   - 不再出现 'unary operator expected' 错误"
echo "   - 成功率计算正常"
echo "   - 显示2次测试（基准测试 + 沙箱复用测试）"
echo "   - 企业微信通知中的时间数据正确"
echo ""

# 监控日志
kubectl logs -l workflows.argoproj.io/workflow -n tke-chaos-test --tail=200 -f &
LOG_PID=$!

echo "7. 等待90秒后停止日志监控..."
sleep 90
kill $LOG_PID 2>/dev/null

echo ""
echo "========================================"
echo "  预期修复效果："
echo "========================================"
echo "✅ 不再出现 'unary operator expected' 错误"
echo "✅ 成功率计算正常显示（如：成功率: 100%）"
echo "✅ 应该看到2次测试执行"
echo "✅ 企业微信通知中应该显示："
echo "   - 总测试: 2次"
echo "   - 基准测试和沙箱复用测试有具体的时间数据"
echo "   - 最快/最慢时间不再是0秒"
echo ""
echo "如需查看完整日志，请运行："
echo "kubectl logs -l workflows.argoproj.io/workflow -n tke-chaos-test -f"

# 清理测试文件
rm -f /tmp/unary-fix-test.yaml