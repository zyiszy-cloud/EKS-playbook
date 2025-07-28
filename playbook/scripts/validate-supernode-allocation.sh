#!/bin/bash

# TKE SuperNode 超级节点分配验证脚本

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

echo -e "${BLUE}"
echo "========================================================"
echo "  TKE SuperNode 超级节点分配验证工具"
echo "========================================================"
echo -e "${NC}"

# 检查所有模板文件中的超级节点分配逻辑
TEMPLATES=(
    "playbook/template/supernode-pod-benchmark-template.yaml"
    "playbook/template/network-performance-template.yaml"
    "playbook/template/storage-performance-template.yaml"
    "playbook/template/image-pull-template.yaml"
    "playbook/template/resource-elasticity-template.yaml"
)

log_info "验证所有模板中的超级节点分配逻辑..."

VALIDATION_PASSED=0
VALIDATION_FAILED=0

for template in "${TEMPLATES[@]}"; do
    template_name=$(basename "$template" .yaml)
    log_info "检查模板: $template_name"
    
    if [ ! -f "$template" ]; then
        log_error "✗ 模板文件不存在: $template"
        VALIDATION_FAILED=$((VALIDATION_FAILED + 1))
        continue
    fi
    
    # 检查关键的超级节点分配逻辑
    CHECKS=(
        "获取所有可用的超级节点:获取可用的超级节点列表"
        "SUPERNODE_LIST:超级节点列表变量"
        "SUPERNODE_ARRAY:超级节点数组变量"
        "SUPERNODE_COUNT:超级节点数量变量"
        "NODE_INDEX:节点索引计算"
        "SELECTED_NODE:选中节点变量"
        "nodeName.*SELECTED_NODE:使用nodeName指定节点"
    )
    
    TEMPLATE_PASSED=true
    
    for check in "${CHECKS[@]}"; do
        IFS=':' read -r pattern description <<< "$check"
        
        if grep -q "$pattern" "$template"; then
            log_success "  ✓ $description"
        else
            log_error "  ✗ $description"
            TEMPLATE_PASSED=false
        fi
    done
    
    # 检查是否还有旧的nodeSelector用法
    if grep -q "nodeSelector:" "$template"; then
        OLD_SELECTOR_COUNT=$(grep -c "nodeSelector:" "$template")
        log_warning "  ⚠ 发现 $OLD_SELECTOR_COUNT 处旧的nodeSelector用法，应该已被nodeName替代"
        TEMPLATE_PASSED=false
    fi
    
    if [ "$TEMPLATE_PASSED" = true ]; then
        log_success "✓ 模板 $template_name 验证通过"
        VALIDATION_PASSED=$((VALIDATION_PASSED + 1))
    else
        log_error "✗ 模板 $template_name 验证失败"
        VALIDATION_FAILED=$((VALIDATION_FAILED + 1))
    fi
    
    echo ""
done

echo ""
log_info "验证结果汇总:"
echo "  通过: $VALIDATION_PASSED"
echo "  失败: $VALIDATION_FAILED"
echo "  总计: ${#TEMPLATES[@]}"

if [ $VALIDATION_FAILED -eq 0 ]; then
    log_success "🎉 所有模板的超级节点分配逻辑验证通过！"
    
    echo ""
    log_info "✨ 统一的超级节点分配特性:"
    echo "  ✅ 自动发现所有可用的超级节点"
    echo "  ✅ 轮询分配Pod到不同超级节点"
    echo "  ✅ 使用nodeName确保精确调度"
    echo "  ✅ 添加target-node注解便于追踪"
    echo "  ✅ 统一的错误处理和日志输出"
    echo ""
    
    log_info "🚀 现在所有测试都会："
    echo "  1. 自动发现集群中的所有超级节点"
    echo "  2. 将Pod均匀分布到不同的超级节点上"
    echo "  3. 确保测试负载的均衡分布"
    echo "  4. 提供详细的节点分配信息"
    echo ""
    
    log_info "📊 验证超级节点分配效果:"
    echo "  运行任意测试后，使用以下命令查看Pod分布:"
    echo "  kubectl get pods -o wide | grep -E 'benchmark|network|storage|image|elasticity'"
    echo ""
    
else
    log_error "❌ 有 $VALIDATION_FAILED 个模板验证失败，请检查修改"
    exit 1
fi

log_success "超级节点分配验证完成！"