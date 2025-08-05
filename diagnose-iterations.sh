#!/bin/bash

# 诊断迭代次数配置的脚本

echo "========================================"
echo "  诊断迭代次数配置"
echo "========================================"

echo "🔍 检查当前配置状态..."
echo ""

# 1. 检查模板配置
echo "1. 检查ClusterWorkflowTemplate配置："
if kubectl get clusterworkflowtemplate supernode-sandbox-deployment-template &>/dev/null; then
    echo "✅ 模板存在"
    echo "📋 模板中的test-iterations默认值："
    kubectl get clusterworkflowtemplate supernode-sandbox-deployment-template -o yaml | grep -A2 -B2 "test-iterations" | head -10
else
    echo "❌ 模板不存在，需要重新部署"
fi

echo ""

# 2. 检查examples文件配置
echo "2. 检查examples文件配置："
echo "📋 sandbox-reuse-precise-test.yaml:"
grep -A1 "test-iterations" examples/sandbox-reuse-precise-test.yaml || echo "未找到配置"

echo ""

# 3. 检查一键部署脚本配置
echo "3. 检查一键部署脚本配置："
echo "📋 DEFAULT_ITERATIONS值:"
grep "DEFAULT_ITERATIONS" scripts/deploy-all.sh || echo "未找到配置"

echo ""

# 4. 检查当前运行的工作流
echo "4. 检查当前运行的工作流："
WORKFLOWS=$(kubectl get workflows -n tke-chaos-test --no-headers 2>/dev/null | awk '{print $1}')
if [ -n "$WORKFLOWS" ]; then
    for workflow in $WORKFLOWS; do
        echo "📋 工作流 $workflow 的test-iterations参数："
        kubectl get workflow $workflow -n tke-chaos-test -o yaml | grep -A1 -B1 "test-iterations" | head -5
        echo ""
    done
else
    echo "📋 当前没有运行的工作流"
fi

echo ""

# 5. 提供修复建议
echo "========================================"
echo "  修复建议："
echo "========================================"
echo "如果发现配置不正确，请按以下步骤修复："
echo ""
echo "1. 强制重新部署模板："
echo "   ./force-redeploy-test.sh"
echo ""
echo "2. 或者手动重新部署："
echo "   kubectl delete clusterworkflowtemplate --all"
echo "   ./scripts/deploy-all.sh --force-redeploy --skip-test"
echo ""
echo "3. 使用修复后的examples文件："
echo "   kubectl apply -f examples/sandbox-reuse-precise-test.yaml"
echo ""
echo "4. 验证配置："
echo "   kubectl logs -l workflows.argoproj.io/workflow -n tke-chaos-test -f"
echo "   # 应该看到：测试迭代: 2 次"