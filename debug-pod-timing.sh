#!/bin/bash

# 调试Pod时间计算的脚本

echo "========================================"
echo "  调试Pod时间计算"
echo "========================================"

# 1. 清理现有资源
echo "1. 清理现有资源..."
./scripts/cleanup.sh quick

# 2. 重新部署模板
echo "2. 重新部署模板..."
./scripts/deploy-all.sh --skip-test

# 3. 运行一个简单的测试（2个Pod）
echo "3. 运行调试测试（2个Pod）..."

# 创建临时测试文件
cat > /tmp/debug-timing.yaml << EOF
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: debug-timing-
  namespace: tke-chaos-test
spec:
  serviceAccountName: tke-chaos
  entrypoint: deployment-sandbox-test
  arguments:
    parameters:
    - name: cluster-id
      value: "debug-cluster"
    - name: webhook-url
      value: ""
    - name: kubeconfig-secret-name
      value: ""
    - name: namespace
      value: "tke-chaos-test"
    - name: deployment-name-prefix
      value: "debug-timing"
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
      value: "1"
    - name: delay-between-tests
      value: "10s"
  workflowTemplateRef:
    name: supernode-sandbox-deployment-template
    clusterScope: true
EOF

kubectl apply -f /tmp/debug-timing.yaml

echo "4. 等待测试启动..."
sleep 10

echo "5. 监控工作流状态..."
kubectl get workflows -n tke-chaos-test

echo "6. 查看实时日志（关注时间计算部分）..."
kubectl logs -l workflows.argoproj.io/workflow -n tke-chaos-test --tail=100 -f &
LOG_PID=$!

echo "7. 等待30秒后停止日志监控..."
sleep 30
kill $LOG_PID 2>/dev/null

echo ""
echo "========================================"
echo "  手动验证Pod时间："
echo "========================================"

# 手动检查Pod状态
echo "8. 手动检查Pod状态..."
PODS=$(kubectl get pods -n tke-chaos-test -l sandbox-reuse-test=true --no-headers -o custom-columns=NAME:.metadata.name 2>/dev/null || echo "")

if [ -n "$PODS" ]; then
  for pod in $PODS; do
    echo ""
    echo "Pod: $pod"
    echo "  创建时间: $(kubectl get pod $pod -n tke-chaos-test -o jsonpath='{.metadata.creationTimestamp}' 2>/dev/null || echo '未知')"
    echo "  容器启动时间: $(kubectl get pod $pod -n tke-chaos-test -o jsonpath='{.status.containerStatuses[0].state.running.startedAt}' 2>/dev/null || echo '未知')"
    echo "  Pod状态: $(kubectl get pod $pod -n tke-chaos-test -o jsonpath='{.status.phase}' 2>/dev/null || echo '未知')"
    echo "  Ready条件: $(kubectl get pod $pod -n tke-chaos-test -o jsonpath='{.status.conditions[?(@.type=="Ready")].lastTransitionTime}' 2>/dev/null || echo '未知')"
    
    echo "  相关Events:"
    kubectl get events -n tke-chaos-test --field-selector involvedObject.name=$pod --sort-by='.firstTimestamp' -o custom-columns=TIME:.firstTimestamp,REASON:.reason,MESSAGE:.message --no-headers 2>/dev/null | head -5
  done
else
  echo "  没有找到测试Pod"
fi

echo ""
echo "========================================"
echo "  检查要点："
echo "  1. Pod创建时间和容器启动时间是否都有值"
echo "  2. 时间戳转换是否正确"
echo "  3. Events是否包含必要的信息"
echo "  4. 时间差计算是否合理"
echo "========================================"

# 清理测试文件
rm -f /tmp/debug-timing.yaml