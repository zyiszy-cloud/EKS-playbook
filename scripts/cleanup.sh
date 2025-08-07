#!/bin/bash

# TKE Chaos Playbook 智能清理脚本
# 功能：清理测试相关资源

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 配置
NAMESPACE="tke-chaos-test"

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 检查kubectl
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl未安装"
        exit 1
    fi
    
    if ! kubectl cluster-info &> /dev/null; then
        log_error "无法连接到集群"
        exit 1
    fi
}

# 显示资源状态
show_resources() {
    echo -e "${CYAN}当前资源状态：${NC}"
    echo ""
    
    # 工作流
    local workflows=$(kubectl get workflows -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l)
    echo "📋 工作流: $workflows 个"
    
    # Pod
    local pods=$(kubectl get pods -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l)
    echo "🚀 Pod: $pods 个"
    
    # Deployment
    local deployments=$(kubectl get deployments -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l)
    echo "📦 Deployment: $deployments 个"
    
    # 模板
    local templates=$(kubectl get clusterworkflowtemplate --no-headers 2>/dev/null | grep -E "(kubectl-cmd|supernode-sandbox)" | wc -l)
    echo "📄 模板: $templates 个"
    
    # 命名空间
    if kubectl get namespace "$NAMESPACE" &> /dev/null; then
        echo "🏠 命名空间: $NAMESPACE (存在)"
    else
        echo "🏠 命名空间: $NAMESPACE (不存在)"
    fi
    
    echo ""
}

# 清理工作流
clean_workflows() {
    log_info "清理工作流..."
    kubectl delete workflows --all -n "$NAMESPACE" --grace-period=0 --force 2>/dev/null || true
    log_success "工作流清理完成"
}

# 清理Pod
clean_pods() {
    log_info "清理Pod..."
    
    # 清理测试相关的Pod
    kubectl delete pods -l app=sandbox-deployment-test -n "$NAMESPACE" --grace-period=0 --force 2>/dev/null || true
    
    # 清理所有Pod（如果上述清理不完整）
    kubectl delete pods --all -n "$NAMESPACE" --grace-period=0 --force 2>/dev/null || true
    
    log_success "Pod清理完成"
}

# 清理Deployment
clean_deployments() {
    log_info "清理Deployment..."
    kubectl delete deployments -l app=sandbox-deployment-test -n "$NAMESPACE" --grace-period=0 --force 2>/dev/null || true
    kubectl delete deployments --all -n "$NAMESPACE" --grace-period=0 --force 2>/dev/null || true
    log_success "Deployment清理完成"
}

# 清理模板
clean_templates() {
    log_info "清理模板..."
    kubectl get clusterworkflowtemplate --no-headers 2>/dev/null | \
        grep -E "(kubectl-cmd|supernode-sandbox-deployment|supernode-rolling-update|sandbox-wechat-notify)" | \
        awk '{print $1}' | \
        xargs -r kubectl delete clusterworkflowtemplate 2>/dev/null || true
    log_success "模板清理完成"
}

# 清理RBAC
clean_rbac() {
    log_info "清理RBAC..."
    kubectl delete clusterrolebinding tke-chaos 2>/dev/null || true
    kubectl delete clusterrole tke-chaos 2>/dev/null || true
    log_success "RBAC清理完成"
}

# 清理命名空间
clean_namespace() {
    log_warning "清理整个命名空间..."
    # 安全检查：确保不删除系统命名空间
    if [[ "$NAMESPACE" =~ ^(default|kube-system|kube-public|kube-node-lease|argo)$ ]]; then
        log_error "拒绝删除系统命名空间: $NAMESPACE"
        return 1
    fi
    kubectl delete namespace "$NAMESPACE" --grace-period=0 --force 2>/dev/null || true
    log_success "命名空间清理完成"
}

# 一键清理
quick_clean() {
    log_info "执行一键清理..."
    clean_workflows
    clean_deployments
    clean_pods
    log_success "一键清理完成"
}

# 完全清理
full_clean() {
    log_warning "执行完全清理..."
    clean_workflows
    clean_deployments
    clean_pods
    clean_templates
    clean_rbac
    clean_namespace
    log_success "完全清理完成"
}

# 显示菜单
show_menu() {
    echo ""
    echo -e "${CYAN}清理选项：${NC}"
    echo "1. 一键清理 (工作流+Deployment+Pod)"
    echo "2. 清理工作流"
    echo "3. 清理Deployment"
    echo "4. 清理Pod"
    echo "5. 清理模板"
    echo "6. 清理RBAC"
    echo "7. 完全清理 (所有资源)"
    echo "0. 退出"
    echo ""
}

# 主函数
main() {
    echo "========================================"
    echo "  TKE Chaos Playbook 清理工具"
    echo "========================================"
    
    check_kubectl
    show_resources
    
    # 如果有参数，直接执行对应操作
    case "${1:-}" in
        "quick"|"1")
            quick_clean
            exit 0
            ;;
        "workflows"|"2")
            clean_workflows
            exit 0
            ;;
        "deployments"|"3")
            clean_deployments
            exit 0
            ;;
        "pods"|"4")
            clean_pods
            exit 0
            ;;
        "templates"|"5")
            clean_templates
            exit 0
            ;;
        "rbac"|"6")
            clean_rbac
            exit 0
            ;;
        "full"|"7")
            read -p "确认完全清理所有资源? (y/N): " -n 1 -r
            echo
            [[ $REPLY =~ ^[Yy]$ ]] && full_clean || log_info "取消操作"
            exit 0
            ;;
        "-h"|"--help"|"help")
            cat << EOF
使用方法: $0 [选项]

选项:
  quick        一键清理工作流、Deployment和Pod
  workflows    只清理工作流
  deployments  只清理Deployment
  pods         只清理Pod
  templates    只清理模板
  rbac         只清理RBAC
  full         完全清理所有资源
  help         显示帮助信息

无参数时进入交互模式
EOF
            exit 0
            ;;
    esac
    
    # 交互模式
    while true; do
        show_menu
        read -p "请选择操作 (0-6): " choice
        
        case $choice in
            1) quick_clean ;;
            2) clean_workflows ;;
            3) clean_deployments ;;
            4) clean_pods ;;
            5) clean_templates ;;
            6) clean_rbac ;;
            7) 
                read -p "确认完全清理所有资源? (y/N): " -n 1 -r
                echo
                [[ $REPLY =~ ^[Yy]$ ]] && full_clean || log_info "取消操作"
                ;;
            0) 
                log_info "退出清理工具"
                exit 0
                ;;
            *) log_error "无效选择" ;;
        esac
        
        echo ""
        read -p "按回车键继续..." -n 1 -r
        echo
    done
}

# 执行主函数
main "$@"