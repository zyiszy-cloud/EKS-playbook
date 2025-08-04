#!/bin/bash

# 项目健康检查脚本

echo "========================================"
echo "  TKE Chaos Playbook 项目健康检查"
echo "========================================"

# 检查计数器
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# 检查函数
check_item() {
    local description="$1"
    local command="$2"
    local expected_result="$3"
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    echo -n "检查 $description... "
    
    if eval "$command" >/dev/null 2>&1; then
        echo "✅ 通过"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        echo "❌ 失败"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
}

echo ""
echo "📁 文件结构检查"
echo "----------------------------------------"

# 检查关键目录
check_item "playbook/template目录存在" "[ -d playbook/template ]"
check_item "examples目录存在" "[ -d examples ]"
check_item "scripts目录存在" "[ -d scripts ]"

# 检查关键文件
check_item "主模板文件存在" "[ -f playbook/template/supernode-sandbox-deployment-template.yaml ]"
check_item "部署脚本存在" "[ -f scripts/deploy-all.sh ]"
check_item "清理脚本存在" "[ -f scripts/cleanup.sh ]"
check_item "README文件存在" "[ -f README.md ]"

echo ""
echo "📝 YAML文件语法检查"
echo "----------------------------------------"

# 检查主要YAML文件的基本结构
for file in examples/*.yaml; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        check_item "$filename 基本结构" "head -5 '$file' | grep -q 'apiVersion:'"
    fi
done

echo ""
echo "🔧 脚本语法检查"
echo "----------------------------------------"

# 检查shell脚本语法
for file in scripts/*.sh test-*.sh; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        check_item "$filename 语法" "bash -n '$file'"
    fi
done

echo ""
echo "📋 配置文件检查"
echo "----------------------------------------"

# 检查关键配置
check_item "主模板包含正确的apiVersion" "grep -q 'apiVersion: argoproj.io/v1alpha1' playbook/template/supernode-sandbox-deployment-template.yaml"
check_item "主模板包含正确的kind" "grep -q 'kind: ClusterWorkflowTemplate' playbook/template/supernode-sandbox-deployment-template.yaml"
check_item "部署脚本可执行" "[ -x scripts/deploy-all.sh ]"
check_item "清理脚本可执行" "[ -x scripts/cleanup.sh ]"

echo ""
echo "🔍 内容完整性检查"
echo "----------------------------------------"

# 检查关键功能
check_item "主模板包含时间计算逻辑" "grep -q 'date +%s%3N' playbook/template/supernode-sandbox-deployment-template.yaml"
check_item "主模板包含企业微信通知" "grep -q 'wechat_notification.json' playbook/template/supernode-sandbox-deployment-template.yaml"
check_item "主模板包含Pod副本数配置" "grep -q 'replicas.*REPLICAS' playbook/template/supernode-sandbox-deployment-template.yaml"
check_item "部署脚本包含参数替换逻辑" "grep -q 'sed.*replicas' scripts/deploy-all.sh"

echo ""
echo "📊 检查结果汇总"
echo "========================================"
echo "总检查项: $TOTAL_CHECKS"
echo "通过: $PASSED_CHECKS"
echo "失败: $FAILED_CHECKS"

if [ $FAILED_CHECKS -eq 0 ]; then
    echo "🎉 所有检查都通过！项目状态良好。"
    echo ""
    echo "✅ 可以安全地运行以下命令："
    echo "   ./scripts/deploy-all.sh"
    echo "   ./test-time-and-wechat.sh"
    exit 0
else
    echo "⚠️ 发现 $FAILED_CHECKS 个问题，建议修复后再使用。"
    echo ""
    echo "🔧 建议的修复步骤："
    echo "1. 检查失败的项目"
    echo "2. 修复相关文件"
    echo "3. 重新运行此检查脚本"
    exit 1
fi