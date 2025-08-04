#!/bin/bash

# 测试修复效果的脚本

echo "========================================"
echo "  测试修复效果"
echo "========================================"

# 1. 清理现有资源
echo "1. 清理现有资源..."
./scripts/cleanup.sh quick

# 2. 重新部署模板
echo "2. 重新部署模板..."
./scripts/deploy-all.sh --skip-test

# 3. 测试5个Pod的部署
echo "3. 测试5个Pod的部署..."
cat > /tmp/test-5pods.yaml << EOF
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: test-5pods-
  namespace: tke-chaos-test
spec:
  serviceAccountName: tke-chaos
  entrypoint: deployment-sandbox-test
  arguments:
    parameters:
    - name: cluster-id
      value: "test-cluster"
    - name: webhook-url
      value: "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=test-key"
    - name: kubeconfig-secret-name
      value: ""
    - name: namespace
      value: "tke-chaos-test"
    - name: deployment-name-prefix
      value: "test-5pods"
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
      value: "1"
    - name: delay-between-tests
      value: "20s"
  workflowTemplateRef:
    name: supernode-sandbox-deployment-template
    clusterScope: true
EOF

echo "4. 启动测试工作流..."
kubectl apply -f /tmp/test-5pods.yaml

echo "5. 等待工作流启动..."
sleep 5

echo "6. 显示工作流状态..."
kubectl get workflows -n tke-chaos-test

echo "7. 显示实时日志（前50行）..."
kubectl logs -l workflows.argoproj.io/workflow -n tke-chaos-test --tail=50 -f &
LOG_PID=$!

echo "8. 等待30秒后停止日志监控..."
sleep 30
kill $LOG_PID 2>/dev/null

echo "测试完成！请检查上述日志确认修复效果。"
echo "如需查看完整日志，请运行："
echo "kubectl logs -l workflows.argoproj.io/workflow -n tke-chaos-test -f"

# 清理测试文件
rm -f /tmp/test-5pods.yaml