#!/bin/bash

# TKE Chaos Playbook 项目状态检查脚本
# 功能：检查项目完整性和功能状态

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✅]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[⚠️]${NC} $1"; }
log_error() { echo -e "${RED}[❌]${NC} $1"; }

# 检查文件是否存在
check_file() {
    local file="$1"
    local description="$2"
    
    if [ -f "$file" ]; then
        log_success "$description: $file"
        return 0
    else
        log_error "$description: $file (缺失)"
        return 1
    fi
}

# 检查目录是否存在
check_directory() {
    local dir="$1"
    local description="$2"
    
    if [ -d "$dir" ]; then
        log_success "$description: $dir"
        return 0
    else
        log_error "$description: $dir (缺失)"
        return 1
    fi
}

# 检查项目结构
check_project_structure() {
    echo -e "${CYAN}========================================"
    echo "  项目结构检查"
    echo "========================================${NC}"
    
    local missing_count=0
    
    # 检查主要目录
    check_directory "docs" "文档目录" || ((missing_count++))
    check_directory "examples" "示例目录" || ((missing_count++))
    check_directory "playbook" "工作流目录" || ((missing_count++))
    check_directory "playbook/template" "模板目录" || ((missing_count++))
    check_directory "playbook/workflow" "工作流定义目录" || ((missing_count++))
    check_directory "scripts" "脚本目录" || ((missing_count++))
    
    # 检查主要文件
    check_file "README.md" "主README文件" || ((missing_count++))
    check_file "README_zh.md" "中文README文件" || ((missing_count++))
    check_file "LICENSE" "许可证文件" || ((missing_count++))
    
    echo ""
    if [ $missing_count -eq 0 ]; then
        log_success "项目结构完整"
    else
        log_warning "发现 $missing_count 个缺失项"
    fi
    
    return $missing_count
}

# 检查模板文件
check_templates() {
    echo -e "${CYAN}========================================"
    echo "  模板文件检查"
    echo "========================================${NC}"
    
    local missing_count=0
    
    # 核心模板
    check_file "playbook/template/supernode-sandbox-deployment-template.yaml" "基础沙箱测试模板" || ((missing_count++))
    check_file "playbook/template/supernode-rolling-update-template.yaml" "滚动更新测试模板" || ((missing_count++))
    check_file "playbook/template/kubectl-cmd-template.yaml" "kubectl命令模板" || ((missing_count++))
    check_file "playbook/template/sandbox-wechat-notify-template.yaml" "微信通知模板" || ((missing_count++))
    
    echo ""
    if [ $missing_count -eq 0 ]; then
        log_success "所有模板文件完整"
    else
        log_warning "发现 $missing_count 个缺失的模板文件"
    fi
    
    return $missing_count
}

# 检查工作流文件
check_workflows() {
    echo -e "${CYAN}========================================"
    echo "  工作流文件检查"
    echo "========================================${NC}"
    
    local missing_count=0
    
    check_file "playbook/workflow/supernode-sandbox-deployment-scenario.yaml" "基础测试工作流" || ((missing_count++))
    check_file "playbook/workflow/supernode-rolling-update-scenario.yaml" "滚动更新工作流" || ((missing_count++))
    
    echo ""
    if [ $missing_count -eq 0 ]; then
        log_success "所有工作流文件完整"
    else
        log_warning "发现 $missing_count 个缺失的工作流文件"
    fi
    
    return $missing_count
}

# 检查示例文件
check_examples() {
    echo -e "${CYAN}========================================"
    echo "  示例文件检查"
    echo "========================================${NC}"
    
    local missing_count=0
    
    check_file "examples/basic-deployment-test.yaml" "基础测试示例" || ((missing_count++))
    check_file "examples/performance-test.yaml" "性能测试示例" || ((missing_count++))
    check_file "examples/sandbox-reuse-precise-test.yaml" "精确沙箱复用测试示例" || ((missing_count++))
    check_file "examples/rolling-update-test.yaml" "滚动更新测试示例" || ((missing_count++))
    check_file "examples/test-wechat-notification.yaml" "微信通知测试示例" || ((missing_count++))
    check_file "examples/README.md" "示例说明文档" || ((missing_count++))
    
    echo ""
    if [ $missing_count -eq 0 ]; then
        log_success "所有示例文件完整"
    else
        log_warning "发现 $missing_count 个缺失的示例文件"
    fi
    
    return $missing_count
}

# 检查文档文件
check_documentation() {
    echo -e "${CYAN}========================================"
    echo "  文档文件检查"
    echo "========================================${NC}"
    
    local missing_count=0
    
    check_file "docs/USAGE.md" "使用指南" || ((missing_count++))
    check_file "docs/WECHAT_NOTIFICATION_SETUP.md" "微信通知设置指南" || ((missing_count++))
    check_file "docs/INTERACTIVE_DEPLOYMENT_GUIDE.md" "交互式部署指南" || ((missing_count++))
    check_file "docs/SANDBOX_REUSE_TEST_GUIDE.md" "沙箱复用测试指南" || ((missing_count++))
    check_file "docs/ROLLING_UPDATE_TEST_GUIDE.md" "滚动更新测试指南" || ((missing_count++))
    
    echo ""
    if [ $missing_count -eq 0 ]; then
        log_success "所有文档文件完整"
    else
        log_warning "发现 $missing_count 个缺失的文档文件"
    fi
    
    return $missing_count
}

# 检查脚本文件
check_scripts() {
    echo -e "${CYAN}========================================"
    echo "  脚本文件检查"
    echo "========================================${NC}"
    
    local missing_count=0
    
    check_file "scripts/deploy-all.sh" "一键部署脚本" || ((missing_count++))
    check_file "scripts/cleanup.sh" "清理脚本" || ((missing_count++))
    check_file "scripts/diagnose.sh" "诊断脚本" || ((missing_count++))
    
    # 检查脚本可执行权限
    for script in scripts/*.sh; do
        if [ -f "$script" ]; then
            if [ -x "$script" ]; then
                log_success "脚本可执行: $(basename "$script")"
            else
                log_warning "脚本不可执行: $(basename "$script")"
                chmod +x "$script" 2>/dev/null && log_info "已修复执行权限: $(basename "$script")" || log_error "无法修复执行权限: $(basename "$script")"
            fi
        fi
    done
    
    echo ""
    if [ $missing_count -eq 0 ]; then
        log_success "所有脚本文件完整"
    else
        log_warning "发现 $missing_count 个缺失的脚本文件"
    fi
    
    return $missing_count
}

# 检查功能完整性
check_functionality() {
    echo -e "${CYAN}========================================"
    echo "  功能完整性检查"
    echo "========================================${NC}"
    
    local issues=0
    
    # 检查README中的功能描述
    if grep -q "滚动更新测试" README.md; then
        log_success "README包含滚动更新功能描述"
    else
        log_warning "README缺少滚动更新功能描述"
        ((issues++))
    fi
    
    # 检查examples/README中的滚动更新说明
    if grep -q "rolling-update-test.yaml" examples/README.md; then
        log_success "示例文档包含滚动更新测试说明"
    else
        log_warning "示例文档缺少滚动更新测试说明"
        ((issues++))
    fi
    
    # 检查部署脚本是否包含滚动更新模板
    if grep -q "supernode-rolling-update-template" scripts/deploy-all.sh; then
        log_success "部署脚本包含滚动更新模板"
    else
        log_warning "部署脚本缺少滚动更新模板"
        ((issues++))
    fi
    
    # 检查清理脚本是否包含滚动更新模板清理
    if grep -q "supernode-rolling-update" scripts/cleanup.sh; then
        log_success "清理脚本包含滚动更新模板清理"
    else
        log_warning "清理脚本缺少滚动更新模板清理"
        ((issues++))
    fi
    
    echo ""
    if [ $issues -eq 0 ]; then
        log_success "所有功能完整"
    else
        log_warning "发现 $issues 个功能问题"
    fi
    
    return $issues
}

# 生成项目统计
generate_statistics() {
    echo -e "${CYAN}========================================"
    echo "  项目统计"
    echo "========================================${NC}"
    
    # 文件统计
    local total_files=$(find . -type f -name "*.yaml" -o -name "*.md" -o -name "*.sh" | grep -v ".git" | wc -l)
    local yaml_files=$(find . -type f -name "*.yaml" | grep -v ".git" | wc -l)
    local md_files=$(find . -type f -name "*.md" | grep -v ".git" | wc -l)
    local sh_files=$(find . -type f -name "*.sh" | grep -v ".git" | wc -l)
    
    echo "📁 总文件数: $total_files"
    echo "📄 YAML文件: $yaml_files"
    echo "📖 Markdown文档: $md_files"
    echo "🔧 Shell脚本: $sh_files"
    
    # 代码行数统计
    local total_lines=$(find . -type f \( -name "*.yaml" -o -name "*.md" -o -name "*.sh" \) -exec wc -l {} + | grep -v ".git" | tail -1 | awk '{print $1}')
    echo "📏 总代码行数: $total_lines"
    
    # 功能统计
    echo ""
    echo "🎯 功能模块:"
    echo "  ✅ 基础沙箱复用测试"
    echo "  ✅ 精确沙箱复用测试"
    echo "  ✅ 滚动更新沙箱复用测试"
    echo "  ✅ 性能对比分析"
    echo "  ✅ 企业微信通知"
    echo "  ✅ 交互式部署"
    echo "  ✅ 一键清理"
    echo "  ✅ 诊断工具"
}

# 主函数
main() {
    echo "========================================"
    echo "  TKE Chaos Playbook 项目状态检查"
    echo "========================================"
    echo ""
    
    local total_issues=0
    
    # 执行各项检查
    check_project_structure || ((total_issues+=$?))
    echo ""
    
    check_templates || ((total_issues+=$?))
    echo ""
    
    check_workflows || ((total_issues+=$?))
    echo ""
    
    check_examples || ((total_issues+=$?))
    echo ""
    
    check_documentation || ((total_issues+=$?))
    echo ""
    
    check_scripts || ((total_issues+=$?))
    echo ""
    
    check_functionality || ((total_issues+=$?))
    echo ""
    
    generate_statistics
    echo ""
    
    # 总结
    echo -e "${CYAN}========================================"
    echo "  检查总结"
    echo "========================================${NC}"
    
    if [ $total_issues -eq 0 ]; then
        log_success "🎉 项目状态完美！所有功能和文件都已完整实现"
        echo ""
        echo -e "${GREEN}项目已准备好：${NC}"
        echo "  📦 上传到GitHub"
        echo "  🚀 生产环境部署"
        echo "  👥 团队协作使用"
    else
        log_warning "⚠️ 发现 $total_issues 个问题需要修复"
        echo ""
        echo -e "${YELLOW}建议：${NC}"
        echo "  🔧 修复上述问题"
        echo "  🧪 运行功能测试"
        echo "  📝 更新相关文档"
    fi
    
    echo ""
    echo -e "${BLUE}下一步操作：${NC}"
    echo "  ./scripts/deploy-all.sh --interactive  # 交互式部署测试"
    echo "  ./scripts/cleanup.sh quick             # 快速清理"
    echo "  kubectl apply -f examples/rolling-update-test.yaml  # 测试滚动更新功能"
    
    return $total_issues
}

# 执行主函数
main "$@"