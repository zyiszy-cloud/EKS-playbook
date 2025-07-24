#!/bin/bash

echo "=== 超级节点演练故障诊断脚本 ==="
echo

# 1. 检查工作流状态
echo "1. 检查工作流状态："
kubectl get workflow -n tke-chaos-test | grep supernode
echo

# 2. 检查超级节点
echo "2. 检查超级节点："
SUPERNODE_COUNT=$(kubectl get nodes -l node.kubernetes.io/instance-type=eklet --no-headers 2>/dev/null | wc -l)
if [ "$SUPERNODE_COUNT" -eq 0 ]; then
  echo "❌ 未找到超级节点 (标签: node.kubernetes.io/instance-type=eklet)"
  echo "   所有节点标签："
  kubectl get nodes --show-labels | head -5
else
  echo "✅ 发现 $SUPERNODE_COUNT 个超级节点"
  kubectl get nodes -l node.kubernetes.io/instance-type=eklet
fi
echo

# 3. 检查预检查资源
echo "3. 检查预检查资源："
if kubectl get -n tke-chaos-test configmap tke-chaos-precheck-resource >/dev/null 2>&1; then
  echo "✅ 预检查资源存在"
else
  echo "❌ 预检查资源不存在"
  echo "   创建命令: kubectl create -n tke-chaos-test configmap tke-chaos-precheck-resource --from-literal=empty=\"\""
fi
echo

# 4. 检查集群健康率
echo "4. 检查集群健康率："
TOTAL_PODS=$(kubectl get pods --all-namespaces --no-headers 2>/dev/null | wc -l)
RUNNING_PODS=$(kubectl get pods --all-namespaces --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)

if [ "$TOTAL_PODS" -gt 0 ]; then
  POD_HEALTH_RATIO=$(echo "scale=2; $RUNNING_PODS / $TOTAL_PODS" | bc -l)
  echo "   Pod健康率: $POD_HEALTH_RATIO ($RUNNING_PODS/$TOTAL_PODS)"
  if (( $(echo "$POD_HEALTH_RATIO < 0.9" | bc -l) )); then
    echo "   ⚠️  Pod健康率低于90%"
  else
    echo "   ✅ Pod健康率正常"
  fi
fi

TOTAL_NODES=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
READY_NODES=$(kubectl get nodes --no-headers 2>/dev/null | grep " Ready " | wc -l)

if [ "$TOTAL_NODES" -gt 0 ]; then
  NODE_HEALTH_RATIO=$(echo "scale=2; $READY_NODES / $TOTAL_NODES" | bc -l)
  echo "   节点健康率: $NODE_HEALTH_RATIO ($READY_NODES/$TOTAL_NODES)"
  if (( $(echo "$NODE_HEALTH_RATIO < 0.9" | bc -l) )); then
    echo "   ⚠️  节点健康率低于90%"
  else
    echo "   ✅ 节点健康率正常"
  fi
fi
echo

# 5. 检查RBAC权限
echo "5. 检查RBAC权限："
if kubectl get clusterrole tke-chaos >/dev/null 2>&1; then
  echo "✅ ClusterRole tke-chaos 存在"
else
  echo "❌ ClusterRole tke-chaos 不存在"
fi

if kubectl get clusterrolebinding tke-chaos >/dev/null 2>&1; then
  echo "✅ ClusterRoleBinding tke-chaos 存在"
else
  echo "❌ ClusterRoleBinding tke-chaos 不存在"
fi
echo

# 6. 检查失败的Pod日志
echo "6. 检查最近的演练Pod："
FAILED_PODS=$(kubectl get pods -n tke-chaos-test -l workflows.argoproj.io/workflow --no-headers | grep -E "(Error|Failed|CrashLoopBackOff)" | head -3)
if [ -n "$FAILED_PODS" ]; then
  echo "   发现失败的Pod："
  echo "$FAILED_PODS"
  echo
  echo "   查看日志命令："
  echo "$FAILED_PODS" | while read pod status rest; do
    echo "   kubectl logs -n tke-chaos-test $pod"
  done
else
  echo "   未发现明显失败的Pod"
fi
echo

# 7. 检查Argo Workflow Controller
echo "7. 检查Argo Workflow Controller："
CONTROLLER_STATUS=$(kubectl get deployment -n tke-chaos-test tke-chaos-argo-workflows-workflow-controller --no-headers 2>/dev/null | awk '{print $2}')
if [ -n "$CONTROLLER_STATUS" ]; then
  echo "   Controller状态: $CONTROLLER_STATUS"
  if [[ "$CONTROLLER_STATUS" != *"1/1"* ]]; then
    echo "   ⚠️  Controller可能有问题"
    echo "   查看日志: kubectl logs -n tke-chaos-test deployment/tke-chaos-argo-workflows-workflow-controller"
  else
    echo "   ✅ Controller运行正常"
  fi
else
  echo "   ❌ 未找到Workflow Controller"
fi

echo
echo "=== 诊断完成 ==="
echo "如果问题仍未解决，请提供具体的Pod日志进行进一步分析"