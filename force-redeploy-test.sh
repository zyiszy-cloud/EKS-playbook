#!/bin/bash

# 强制重新部署模板并测试的脚本

echo "========================================"
echo "  强制重新部署模板并测试"
echo "========================================"

echo "🔧 问题分析："
echo "从日志看到'测试迭代: 1'，说明模板可能没有重新部署"
echo "需要强制删除并重新部署所有模板"
echo ""

# 1. 强制清理所有资源
echo "1. 强制清理所有资源..."
./scripts/cleanup.sh full

# 2. 删除所有工作流模板
echo "2. 删除所有工作流模板..."
kubectl delete clusterworkflowtemplate --all --ignore-not-found=true

# 等待删除完成
echo "3. 等待模板删除完成..."
sleep 5

# 3. 强制重新部署
echo "4. 强制重新部署所有组件..."
./scripts/deploy-all.sh --force-redeploy --skip-test

# 4. 验证模板是否正确部署
echo "5. 验证模板配置..."
echo "检查supernode-sandbox-deployment-template的默认test-iterations值："
kubectl get clusterworkflowtemplate supernode-sandbox-deployment-template -o yaml | grep -A2 -B2 "test-iterations" || echo "未找到test-iterations配置"

# 5. 创建测试工作流（使用修复后的配置）
echo "6. 创建测试工作流..."
cat > /tmp/force-redeploy-test.yaml << EOF
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: force-redeploy-test-
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
      value: "force-redeploy-test"
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

kubectl apply -f /tmp/force-redeploy-test.yaml

echo "7. 等待测试启动..."
sleep 10

echo "8. 显示工作流状态..."
kubectl get workflows -n tke-chaos-test

echo ""
echo "9. 监控测试进度（重点关注迭代次数）..."
echo "   🔍 关键检查点："
echo "   - 应该显示：测试迭代: 2 次"
echo "   - 应该看到：第1次测试：基准测试"
echo "   - 应该看到：第2次测试：沙箱复用测试"
echo ""

# 监控日志
kubectl logs -l workflows.argoproj.io/workflow -n tke-chaos-test --tail=200 -f &
LOG_PID=$!

echo "10. 等待120秒后停止日志监控..."
sleep 120
kill $LOG_PID 2>/dev/null

echo ""
echo "========================================"
echo "  验证结果："
echo "========================================"
echo "如果仍然显示'测试迭代: 1 次'，请检查："
echo "1. 模板是否正确重新部署"
echo "2. 参数传递是否正确"
echo "3. 是否有缓存问题"
echo ""
echo "如果显示'测试迭代: 2 次'，说明修复成功！"
echo ""
echo "查看完整日志："
echo "kubectl logs -l workflows.argoproj.io/workflow -n tke-chaos-test -f"

# 清理测试文件
rm -f /tmp/force-redeploy-test.yaml