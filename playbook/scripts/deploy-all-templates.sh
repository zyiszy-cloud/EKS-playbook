#!/bin/bash

# TKE SuperNode 所有测试模板部署脚本

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
echo "  TKE SuperNode 所有测试模板部署工具"
echo "========================================================"
echo -e "${NC}"

# 检查kubectl连接
log_info "检查kubectl连接..."
if ! kubectl cluster-info &> /dev/null; then
    log_error "无法连接到Kubernetes集群"
    exit 1
fi
log_success "kubectl连接正常"

# 确保命名空间存在
log_info "确保测试命名空间存在..."
kubectl create namespace tke-chaos-test --dry-run=client -o yaml | kubectl apply -f -

# 定义所有模板文件
TEMPLATES=(
    "playbook/template/kubectl-cmd-template.yaml:kubectl-cmd"
    "playbook/template/precheck-template.yaml:precheck-template"
    "playbook/template/supernode-template.yaml:supernode-template"
    "playbook/template/supernode-pod-benchmark-template.yaml:supernode-pod-benchmark-template"
    "playbook/template/network-performance-template.yaml:network-performance-template"
    ""
    "playbook/template/image-pull-template.yaml:image-pull-template"
    "playbook/template/resource-elasticity-template.yaml:resource-elasticity-template"
)

# 部署所有模板
log_info "部署所有测试模板..."
DEPLOYED_COUNT=0
FAILED_COUNT=0

for template_info in "${TEMPLATES[@]}"; do
    IFS=':' read -r template_file template_name <<< "$template_info"
    
    log_info "处理模板: $template_name"
    
    # 检查文件是否存在
    if [ ! -f "$template_file" ]; then
        log_warning "模板文件不存在: $template_file"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        continue
    fi
    
    # 检查模板是否已存在
    if kubectl get clusterworkflowtemplate "$template_name" &>/dev/null; then
        log_info "模板 $template_name 已存在，正在更新..."
        if kubectl apply -f "$template_file"; then
            log_success "✓ 模板 $template_name 更新成功"
            DEPLOYED_COUNT=$((DEPLOYED_COUNT + 1))
        else
            log_error "✗ 模板 $template_name 更新失败"
            FAILED_COUNT=$((FAILED_COUNT + 1))
        fi
    else
        log_info "部署新模板: $template_name"
        if kubectl apply -f "$template_file"; then
            log_success "✓ 模板 $template_name 部署成功"
            DEPLOYED_COUNT=$((DEPLOYED_COUNT + 1))
        else
            log_error "✗ 模板 $template_name 部署失败"
            FAILED_COUNT=$((FAILED_COUNT + 1))
        fi
    fi
done

echo ""
log_info "部署统计:"
echo "  成功: $DEPLOYED_COUNT"
echo "  失败: $FAILED_COUNT"
echo "  总计: ${#TEMPLATES[@]}"

# 验证所有模板
log_info "验证所有模板..."
echo ""
echo "已部署的ClusterWorkflowTemplate:"
kubectl get clusterworkflowtemplate 2>/dev/null || log_warning "无法获取ClusterWorkflowTemplate列表"

# 检查关键模板
CRITICAL_TEMPLATES=("kubectl-cmd" "supernode-pod-benchmark-template" "network-performance-template")
MISSING_CRITICAL=0

echo ""
log_info "检查关键模板:"
for template in "${CRITICAL_TEMPLATES[@]}"; do
    if kubectl get clusterworkflowtemplate "$template" &>/dev/null; then
        log_success "✓ 关键模板 $template 可用"
    else
        log_error "✗ 关键模板 $template 缺失"
        MISSING_CRITICAL=$((MISSING_CRITICAL + 1))
    fi
done

echo ""
if [ $MISSING_CRITICAL -eq 0 ]; then
    log_success "🎉 所有关键模板部署成功！"
    
    echo ""
    log_info "🚀 现在可以运行以下测试:"
    echo "  Pod创建基准测试:"
    echo "    kubectl apply -f playbook/workflow/supernode-pod-benchmark.yaml"
    echo ""
    echo "  网络性能测试:"
    echo "    kubectl apply -f playbook/workflow/network-performance-test.yaml"
    echo ""

    echo "  镜像拉取测试:"
    echo "    kubectl apply -f playbook/workflow/image-pull-test.yaml"
    echo ""
    echo "  资源弹性测试:"
    echo "    kubectl apply -f playbook/workflow/resource-elasticity-test.yaml"
    echo ""
    
    log_info "📊 查看测试进度:"
    echo "  kubectl get workflows -n tke-chaos-test"
    echo ""
    
    log_info "📋 查看测试日志:"
    echo "  kubectl logs -n tke-chaos-test -l workflows.argoproj.io/workflow=<workflow-name> -f"
    echo ""
    
else
    log_error "❌ 有 $MISSING_CRITICAL 个关键模板缺失，请检查部署问题"
    exit 1
fi

log_success "模板部署脚本执行完成！"