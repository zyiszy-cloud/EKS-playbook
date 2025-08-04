#!/bin/bash

# 测试企业微信通知格式的脚本

echo "========================================"
echo "  测试企业微信通知格式"
echo "========================================"

# 1. 清理现有资源
echo "1. 清理现有资源..."
./scripts/cleanup.sh quick

# 2. 重新部署模板
echo "2. 重新部署模板..."
./scripts/deploy-all.sh --skip-test

# 3. 运行一个小规模测试（2个Pod，2次迭代）来测试沙箱复用效果
echo "3. 运行测试（2个Pod，2次迭代）验证通知格式..."

# 创建临时测试文件
cat > /tmp/test-wechat-format.yaml << EOF
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: test-wechat-format-
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
      value: "test-wechat-format"
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
      value: "15s"
  workflowTemplateRef:
    name: supernode-sandbox-deployment-template
    clusterScope: true
EOF

kubectl apply -f /tmp/test-wechat-format.yaml

echo "4. 等待测试完成..."
sleep 20

echo "5. 查看最新的工作流日志..."
kubectl logs -l workflows.argoproj.io/workflow -n tke-chaos-test --tail=300

echo ""
echo "========================================"
echo "  检查要点："
echo "  1. 是否显示详细的时间指标统计"
echo "  2. 是否包含沙箱复用效果分析"
echo "  3. 企业微信通知内容是否包含完整指标"
echo "  4. 通知格式是否清晰易读"
echo "========================================"

echo ""
echo "如需查看完整日志，请运行："
echo "kubectl logs -l workflows.argoproj.io/workflow -n tke-chaos-test -f"

# 清理测试文件
rm -f /tmp/test-wechat-format.yaml