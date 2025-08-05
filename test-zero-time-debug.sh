#!/bin/bash

# 测试0秒问题的调试脚本

echo "========================================"
echo "  测试0秒问题调试"
echo "========================================"

echo "🔧 修复内容："
echo "1. 移除重复的Pod分析逻辑（旧逻辑覆盖了新逻辑）"
echo "2. 添加详细的调试信息"
echo "3. 确保使用正确的时间计算方式"
echo ""

echo "🔍 调试重点："
echo "- 检查DEPLOYMENT_START_SEC变量是否正确"
echo "- 检查POD_CREATE_TS是否能正确获取"
echo "- 检查时间差计算是否正确"
echo "- 检查CURRENT_SANDBOX_INIT_TIMES是否有数据"
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

# 3. 创建测试工作流（2个Pod，便于调试）
echo "3. 创建测试工作流（2个Pod，2次迭代）..."
cat > /tmp/zero-time-debug-test.yaml << EOF
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: zero-time-debug-test-
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
      value: "zero-time-debug-test"
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
      value: "30s"
  workflowTemplateRef:
    name: supernode-sandbox-deployment-template
    clusterScope: true
EOF

kubectl apply -f /tmp/zero-time-debug-test.yaml

echo "4. 等待测试启动..."
sleep 10

echo "5. 显示工作流状态..."
kubectl get workflows -n tke-chaos-test

echo ""
echo "6. 监控测试进度（重点关注调试信息）..."
echo "   🔍 关键调试信息："
echo "   - 🔍 调试信息: POD_CREATE_TIME, POD_CREATE_TS, DEPLOYMENT_START_SEC"
echo "   - 计算结果: POD_CREATION_TIME = POD_CREATE_TS - DEPLOYMENT_START_SEC"
echo "   - 🔍 调试：CURRENT_SANDBOX_INIT_TIMES = '...'"
echo "   - 📊 当前测试的平均沙箱初始化时间: X.X秒（不应该是0）"
echo ""

# 监控日志
kubectl logs -l workflows.argoproj.io/workflow -n tke-chaos-test --tail=400 -f &
LOG_PID=$!

echo "7. 等待120秒后停止日志监控..."
sleep 120
kill $LOG_PID 2>/dev/null

echo ""
echo "========================================"
echo "  调试分析："
echo "========================================"
echo "请检查日志中的以下信息："
echo ""
echo "1. 🔍 调试信息部分："
echo "   - POD_CREATE_TIME: 应该是ISO格式时间"
echo "   - POD_CREATE_TS: 应该是Unix时间戳（大于0）"
echo "   - DEPLOYMENT_START_SEC: 应该是Unix时间戳（大于0）"
echo "   - 计算结果: 应该是合理的正数（5-15秒）"
echo ""
echo "2. 🔍 CURRENT_SANDBOX_INIT_TIMES:"
echo "   - 应该包含每个Pod的时间数据"
echo "   - 不应该为空"
echo ""
echo "3. 📊 当前测试的平均时间:"
echo "   - 不应该是0秒"
echo "   - 应该是合理的时间（5-15秒）"
echo ""
echo "如果仍然是0秒，请检查："
echo "- Pod是否在分析时还存在"
echo "- 时间戳解析是否成功"
echo "- 变量作用域是否正确"
echo ""
echo "查看完整日志："
echo "kubectl logs -l workflows.argoproj.io/workflow -n tke-chaos-test -f"

# 清理测试文件
rm -f /tmp/zero-time-debug-test.yaml