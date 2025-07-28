#!/bin/bash

# TKE SuperNode 环境检验和模板部署脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 默认参数
DEFAULT_SECRET_NAME="dest-cluster-kubeconfig"
DEFAULT_SECRET_NAMESPACE="tke-chaos-test"
DEFAULT_SUPERNODE_SELECTOR="node.kubernetes.io/instance-type=eklet"

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 显示帮助信息
show_help() {
    echo ""
    echo -e "${BLUE}TKE SuperNode 环境检验和模板部署工具${NC}"
    echo ""
    echo -e "${YELLOW}用法:${NC}"
    echo "  $0 [选项]"
    echo ""
    echo -e "${YELLOW}选项:${NC}"
    echo "  -h, --help                   显示帮助信息"
    echo ""
}

# 解析命令行参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# 检查kubectl连接
check_kubectl() {
    log_info "检查kubectl连接..."
    if ! kubectl cluster-info &> /dev/null; then
        log_error "无法连接到Kubernetes集群"
        log_error "请确保kubectl已正确配置"
        exit 1
    fi
    log_success "kubectl连接正常"
}

# 部署模板
deploy_templates() {
    log_info "部署必要的模板..."

    # 创建命名空间
    log_info "创建测试命名空间..."
    kubectl create namespace tke-supernode-benchmark --dry-run=client -o yaml | kubectl apply -f -
    kubectl create namespace tke-chaos-test --dry-run=client -o yaml | kubectl apply -f -

    # 部署所有测试模板
    log_info "部署所有测试模板..."
    if ./playbook/scripts/deploy-all-templates.sh; then
        log_success "所有测试模板部署成功"
    else
        log_error "测试模板部署失败"
        exit 1
    fi
}

# 验证部署并获取模板日志
verify_deployment() {
    log_info "验证模板部署状态..."

    TEMPLATES=(
        "kubectl-cmd"
        "precheck-template"
        "supernode-pod-benchmark-template"
        "supernode-template"
    )

    for template in "${TEMPLATES[@]}"; do
        if kubectl get clusterworkflowtemplate "$template" &> /dev/null; then
            log_success "✓ 模板 $template 部署成功"
        else
            log_error "✗ 模板 $template 部署失败"
            exit 1
        fi
    done
}

# 主函数
main() {
    echo -e "${BLUE}"
    echo "========================================================"
    echo "  TKE SuperNode 环境检验和模板部署工具"
    echo "========================================================"
    echo -e "${NC}"

    # 解析参数
    parse_args "$@"

    check_kubectl
    deploy_templates
    verify_deployment

    log_success "环境检验和模板部署完成！"
    echo ""
    log_info "先查看是否已经存在该工作流"
    if kubectl get workflow -n tke-chaos-test | grep -q "supernode-pod-benchmark"; then
        log_info "工作流已存在，跳过创建"
    else
        log_info "工作流不存在，继续创建"
    fi
    log_info "🎯 可用的测试工作流:"
    echo "  Pod创建基准测试:"
    echo "    kubectl apply -f playbook/workflow/supernode-pod-benchmark.yaml"
    echo "  网络性能测试:"
    echo "    kubectl apply -f playbook/workflow/network-performance-test.yaml"
    echo "    或使用验证脚本: ./playbook/scripts/test-network-performance.sh -t all -w"

    echo "  镜像拉取测试:"
    echo "    kubectl apply -f playbook/workflow/image-pull-test.yaml"
    echo "  资源弹性测试:"
    echo "    kubectl apply -f playbook/workflow/resource-elasticity-test.yaml"
    echo ""

    log_info "🔧 测试验证工具:"
    echo "    网络性能测试: ./playbook/scripts/test-network-performance.sh"
    echo "    超级节点分配验证: ./playbook/scripts/validate-supernode-allocation.sh"
    echo ""
    log_info "📊 查看测试结果:"
    echo "    kubectl logs -n tke-chaos-test -l workflows.argoproj.io/workflow=<workflow-name> -f"
    echo ""
}

# 执行主函数
main "$@"