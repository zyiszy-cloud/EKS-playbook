#!/bin/bash

# TKE Serverless 性能测试执行脚本
# 使用方法: ./run-serverless-tests.sh [test-type]
# test-type: startup | scaling | all

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查kubectl命令
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl 命令未找到，请先安装kubectl"
        exit 1
    fi
}

# 检查集群连接
check_cluster() {
    log_info "检查集群连接..."
    if ! kubectl cluster-info &> /dev/null; then
        log_error "无法连接到Kubernetes集群，请检查kubeconfig配置"
        exit 1
    fi
    log_success "集群连接正常"
}

# 检查前置条件
check_prerequisites() {
    log_info "检查前置条件..."
    
    # 检查命名空间
    if ! kubectl get namespace tke-chaos-test &> /dev/null; then
        log_warning "tke-chaos-test命名空间不存在，正在创建..."
        kubectl create namespace tke-chaos-test
    fi
    
    # 检查ConfigMap
    if ! kubectl get configmap tke-chaos-precheck-resource -n tke-chaos-test &> /dev/null; then
        log_warning "前置检查ConfigMap不存在，正在创建..."
        kubectl create -n tke-chaos-test configmap tke-chaos-precheck-resource --from-literal=empty=""
    fi
    
    # 检查kubeconfig secret
    if ! kubectl get secret dest-cluster-kubeconfig -n tke-chaos-test &> /dev/null; then
        log_error "dest-cluster-kubeconfig secret不存在"
        log_error "请先创建目标集群的kubeconfig secret:"
        log_error "kubectl create -n tke-chaos-test secret generic dest-cluster-kubeconfig --from-file=config=./your-kubeconfig"
        exit 1
    fi
    
    # 检查Argo Workflow
    if ! kubectl get deployment tke-chaos-argo-workflows-workflow-controller -n tke-chaos-test &> /dev/null; then
        log_warning "Argo Workflow未部署，正在部署..."
        kubectl create -f playbook/install-argo.yaml
        log_info "等待Argo Workflow就绪..."
        kubectl wait --for=condition=available deployment/tke-chaos-argo-workflows-workflow-controller -n tke-chaos-test --timeout=300s
    fi
    
    log_success "前置条件检查完成"
}

# 部署模板
deploy_templates() {
    log_info "部署Workflow模板..."
    kubectl apply -f playbook/rbac.yaml
    kubectl apply -f playbook/all-in-one-template.yaml
    log_success "模板部署完成"
}

# 执行Pod启动性能测试
run_startup_test() {
    log_info "开始执行Pod启动性能测试..."
    
    # 清理之前的测试
    kubectl delete workflow serverless-pod-startup-performance -n tke-chaos-test --ignore-not-found=true
    
    # 创建测试
    kubectl create -f playbook/workflow/serverless-pod-startup-performance.yaml
    
    log_info "测试已启动，工作流名称: serverless-pod-startup-performance"
    log_info "您可以通过以下方式监控测试进度:"
    log_info "1. kubectl get workflow -n tke-chaos-test"
    log_info "2. kubectl describe workflow serverless-pod-startup-performance -n tke-chaos-test"
    log_info "3. 访问Argo UI查看详细进度"
    
    # 等待测试完成
    log_info "等待测试完成..."
    kubectl wait --for=condition=Completed workflow/serverless-pod-startup-performance -n tke-chaos-test --timeout=1800s || {
        log_warning "测试可能仍在进行中或遇到问题，请检查工作流状态"
        kubectl get workflow serverless-pod-startup-performance -n tke-chaos-test
        return 1
    }
    
    log_success "Pod启动性能测试完成"
}

# 执行弹性扩缩容性能测试
run_scaling_test() {
    log_info "开始执行弹性扩缩容性能测试..."
    
    # 清理之前的测试
    kubectl delete workflow serverless-scaling-performance -n tke-chaos-test --ignore-not-found=true
    
    # 创建测试
    kubectl create -f playbook/workflow/serverless-scaling-performance.yaml
    
    log_info "测试已启动，工作流名称: serverless-scaling-performance"
    log_info "您可以通过以下方式监控测试进度:"
    log_info "1. kubectl get workflow -n tke-chaos-test"
    log_info "2. kubectl describe workflow serverless-scaling-performance -n tke-chaos-test"
    log_info "3. kubectl get hpa -n tke-serverless-scaling-test -w"
    
    # 等待测试完成
    log_info "等待测试完成..."
    kubectl wait --for=condition=Completed workflow/serverless-scaling-performance -n tke-chaos-test --timeout=2400s || {
        log_warning "测试可能仍在进行中或遇到问题，请检查工作流状态"
        kubectl get workflow serverless-scaling-performance -n tke-chaos-test
        return 1
    }
    
    log_success "弹性扩缩容性能测试完成"
}

# 获取Argo UI访问信息
get_argo_ui_info() {
    log_info "获取Argo UI访问信息..."
    
    # 获取Service信息
    SERVICE_TYPE=$(kubectl get service tke-chaos-argo-workflows-server -n tke-chaos-test -o jsonpath='{.spec.type}')
    
    if [ "$SERVICE_TYPE" = "LoadBalancer" ]; then
        EXTERNAL_IP=$(kubectl get service tke-chaos-argo-workflows-server -n tke-chaos-test -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
        if [ -n "$EXTERNAL_IP" ]; then
            log_info "Argo UI访问地址: http://$EXTERNAL_IP:2746"
        else
            log_warning "LoadBalancer外部IP尚未分配，请稍后检查"
        fi
    else
        log_info "Service类型为 $SERVICE_TYPE，请根据需要配置访问方式"
    fi
    
    # 获取访问token
    log_info "获取Argo UI访问token..."
    TOKEN=$(kubectl exec -n tke-chaos-test deployment/tke-chaos-argo-workflows-server -- argo auth token 2>/dev/null || echo "获取token失败")
    log_info "访问token: $TOKEN"
}

# 显示测试结果
show_results() {
    log_info "测试结果摘要:"
    echo "=================================="
    
    # 显示工作流状态
    kubectl get workflow -n tke-chaos-test -o wide
    
    echo ""
    log_info "详细结果请查看:"
    log_info "1. kubectl describe workflow <workflow-name> -n tke-chaos-test"
    log_info "2. 访问Argo UI查看详细日志和结果"
    log_info "3. 查看测试指南: cat playbook/TKE_SERVERLESS_PERFORMANCE_GUIDE.md"
}

# 清理测试资源
cleanup() {
    log_info "清理测试资源..."
    kubectl delete workflow --all -n tke-chaos-test --ignore-not-found=true
    kubectl delete namespace tke-serverless-perf-test --ignore-not-found=true
    kubectl delete namespace tke-serverless-scaling-test --ignore-not-found=true
    log_success "清理完成"
}

# 显示帮助信息
show_help() {
    echo "TKE Serverless 性能测试脚本"
    echo ""
    echo "使用方法:"
    echo "  $0 [选项] [测试类型]"
    echo ""
    echo "测试类型:"
    echo "  startup   - 执行Pod启动性能测试"
    echo "  scaling   - 执行弹性扩缩容性能测试"
    echo "  all       - 执行所有性能测试"
    echo ""
    echo "选项:"
    echo "  -h, --help     显示帮助信息"
    echo "  -c, --cleanup  清理测试资源"
    echo "  -s, --status   显示测试状态"
    echo "  --ui-info      显示Argo UI访问信息"
    echo ""
    echo "示例:"
    echo "  $0 startup              # 执行Pod启动性能测试"
    echo "  $0 scaling              # 执行弹性扩缩容测试"
    echo "  $0 all                  # 执行所有测试"
    echo "  $0 --cleanup            # 清理测试资源"
    echo "  $0 --status             # 显示测试状态"
}

# 主函数
main() {
    local test_type="$1"
    
    case "$test_type" in
        -h|--help)
            show_help
            exit 0
            ;;
        -c|--cleanup)
            cleanup
            exit 0
            ;;
        -s|--status)
            kubectl get workflow -n tke-chaos-test -o wide
            exit 0
            ;;
        --ui-info)
            get_argo_ui_info
            exit 0
            ;;
        startup)
            check_kubectl
            check_cluster
            check_prerequisites
            deploy_templates
            run_startup_test
            show_results
            ;;
        scaling)
            check_kubectl
            check_cluster
            check_prerequisites
            deploy_templates
            run_scaling_test
            show_results
            ;;
        all)
            check_kubectl
            check_cluster
            check_prerequisites
            deploy_templates
            run_startup_test
            sleep 30  # 等待一段时间再执行下一个测试
            run_scaling_test
            show_results
            ;;
        "")
            log_error "请指定测试类型"
            show_help
            exit 1
            ;;
        *)
            log_error "未知的测试类型: $test_type"
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"