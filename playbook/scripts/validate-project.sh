#!/bin/bash

# 项目验证脚本 - 检查项目文件的完整性和正确性

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 验证计数器
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# 验证函数
validate() {
    local description="$1"
    local command="$2"
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if eval "$command" &>/dev/null; then
        log_success "✓ $description"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        log_error "✗ $description"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
}

echo "🔍 开始项目验证..."
echo ""

# 1. 检查必需文件存在
log_info "检查必需文件..."
validate "主README文件存在" "[ -f README.md ]"
validate "许可证文件存在" "[ -f LICENSE ]"

# 2. 检查脚本文件
log_info "检查脚本文件..."
validate "部署脚本存在且可执行" "[ -x playbook/scripts/deploy-supernode-benchmark.sh ]"

# 3. 检查配置文件
log_info "检查配置文件..."
validate "超级节点配置文件存在" "[ -f config/supernode-config.yaml ]"

# 4. 检查模板文件
log_info "检查模板文件..."
validate "基准测试模板存在" "[ -f playbook/template/supernode-pod-benchmark-template.yaml ]"
validate "基础超级节点模板存在" "[ -f playbook/template/supernode-template.yaml ]"
validate "kubectl命令模板存在" "[ -f playbook/template/kubectl-cmd-template.yaml ]"
validate "预检查模板存在" "[ -f playbook/template/precheck-template.yaml ]"

# 5. 检查工作流文件
log_info "检查工作流文件..."
validate "基准测试工作流存在" "[ -f playbook/workflow/supernode-pod-benchmark.yaml ]"
validate "基础测试工作流存在" "[ -f playbook/workflow/supernode-scenario.yaml ]"

# 6. 检查YAML语法
log_info "检查YAML语法..."
if command -v yamllint &> /dev/null; then
    validate "配置文件YAML语法正确" "yamllint config/supernode-config.yaml"
    validate "基准测试模板YAML语法正确" "yamllint playbook/template/supernode-pod-benchmark-template.yaml"
    validate "工作流YAML语法正确" "yamllint playbook/workflow/supernode-pod-benchmark.yaml"
else
    log_warning "yamllint未安装，跳过YAML语法检查"
fi

# 7. 检查Shell脚本语法
log_info "检查Shell脚本语法..."
if command -v shellcheck &> /dev/null; then
    validate "部署脚本语法正确" "shellcheck playbook/scripts/deploy-supernode-benchmark.sh"
else
    log_warning "shellcheck未安装，跳过Shell脚本语法检查"
fi

# 8. 检查文档链接
log_info "检查文档完整性..."
validate "README包含项目结构" "grep -q '项目结构' README.md"
validate "README包含快速开始" "grep -q '快速开始' README.md"
validate "README包含配置说明" "grep -q '配置' README.md"

# 9. 检查脚本逻辑
log_info "检查脚本逻辑..."

validate "部署脚本包含验证步骤" "grep -q 'kubectl get clusterworkflowtemplate' playbook/scripts/deploy-supernode-benchmark.sh"

# 10. 检查模板逻辑
log_info "检查模板逻辑..."
validate "基准测试模板包含自定义函数" "grep -q 'calc_time_diff\|calc_p99\|calc_avg' playbook/template/supernode-pod-benchmark-template.yaml"
validate "模板包含错误处理" "grep -q 'exit 1' playbook/template/supernode-pod-benchmark-template.yaml"
validate "模板包含超时处理" "grep -q 'TIMEOUT' playbook/template/supernode-pod-benchmark-template.yaml"

echo ""
echo "📊 验证结果汇总:"
echo "  总检查项: $TOTAL_CHECKS"
echo "  通过: $PASSED_CHECKS"
echo "  失败: $FAILED_CHECKS"

if [ $FAILED_CHECKS -eq 0 ]; then
    log_success "🎉 所有检查项都通过了！项目状态良好。"
    exit 0
else
    log_error "❌ 发现 $FAILED_CHECKS 个问题，请修复后重新验证。"
    exit 1
fi