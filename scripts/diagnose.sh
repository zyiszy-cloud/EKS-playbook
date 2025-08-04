#!/bin/bash

# TKE Chaos Playbook 诊断脚本
# 用于排查部署问题

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

echo "========================================"
echo "  TKE Chaos Playbook 诊断工具"
echo "========================================"

# 1. 检查kubectl连接
log_info "检查kubectl连接..."
if kubectl cluster-info &> /dev/null; then
    log_success "kubectl连接正常"
    kubectl cluster-info | head -2
else
    log_error "kubectl连接失败"
    exit 1
fi

echo ""

# 2. 检查命名空间
log_info "检查命名空间..."
NAMESPACE="tke-chaos-test"
if kubectl get namespace "$NAMESPACE" &> /dev/null; then
    log_success "命名空间存在: $NAMESPACE"
else
    log_warning "命名空间不存在: $NAMESPACE"
fi

echo ""

# 3. 检查RBAC权限
log_info "检查RBAC权限..."
if kubectl get serviceaccount tke-chaos -n "$NAMESPACE" &> /dev/null; then
    log_success "服务账户存在: tke-chaos"
else
    log_warning "服务账户不存在: tke-chaos"
fi

if kubectl get clusterrole tke-chaos &> /dev/null; then
    log_success "集群角色存在: tke-chaos"
else
    log_warning "集群角色不存在: tke-chaos"
fi

if kubectl get clusterrolebinding tke-chaos &> /dev/null; then
    log_success "集群角色绑定存在: tke-chaos"
else
    log_warning "集群角色绑定不存在: tke-chaos"
fi

echo ""

# 4. 检查Argo Workflows
log_info "检查Argo Workflows..."
if kubectl get deployment tke-chaos-argo-workflows-workflow-controller -n "$NAMESPACE" &> /dev/null; then
    log_success "Argo Workflows控制器已安装"
    CONTROLLER_STATUS=$(kubectl get deployment tke-chaos-argo-workflows-workflow-controller -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}')
    if [ "$CONTROLLER_STATUS" = "1" ]; then
        log_success "Argo Workflows控制器运行正常"
    else
        log_warning "Argo Workflows控制器状态异常"
    fi
else
    log_warning "Argo Workflows控制器未安装"
fi

echo ""

# 5. 检查工作流模板
log_info "检查工作流模板..."
TEMPLATES=("kubectl-cmd" "supernode-sandbox-deployment-template")

for template in "${TEMPLATES[@]}"; do
    if kubectl get clusterworkflowtemplate "$template" &> /dev/null; then
        log_success "模板存在: $template"
    else
        log_warning "模板不存在: $template"
    fi
done

echo ""

# 6. 检查模板文件
log_info "检查模板文件..."
TEMPLATE_FILES=(
    "playbook/template/kubectl-cmd-template.yaml"
    "playbook/template/supernode-sandbox-deployment-template.yaml"
)

for file in "${TEMPLATE_FILES[@]}"; do
    if [ -f "$file" ]; then
        log_success "模板文件存在: $file"
    else
        log_error "模板文件不存在: $file"
    fi
done

echo ""

# 7. 检查工作流文件
log_info "检查工作流文件..."
WORKFLOW_FILES=(
    "examples/sandbox-reuse-precise-test.yaml"
    "playbook/workflow/supernode-sandbox-deployment-scenario.yaml"
)

for file in "${WORKFLOW_FILES[@]}"; do
    if [ -f "$file" ]; then
        log_success "工作流文件存在: $file"
    else
        log_error "工作流文件不存在: $file"
    fi
done

echo ""

# 8. 检查超级节点
log_info "检查超级节点..."
SUPERNODES=$(kubectl get nodes --selector=node.kubernetes.io/instance-type=eklet -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")

if [ -n "$SUPERNODES" ]; then
    SUPERNODE_COUNT=$(echo $SUPERNODES | wc -w)
    log_success "发现 $SUPERNODE_COUNT 个超级节点:"
    for node in $SUPERNODES; do
        echo "  - $node"
    done
else
    log_warning "未发现超级节点"
    echo "  请检查集群是否配置了超级节点"
fi

echo ""

# 9. 检查现有工作流
log_info "检查现有工作流..."
EXISTING_WORKFLOWS=$(kubectl get workflows -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l)
if [ "$EXISTING_WORKFLOWS" -gt 0 ]; then
    log_info "发现 $EXISTING_WORKFLOWS 个现有工作流:"
    kubectl get workflows -n "$NAMESPACE" --no-headers | awk '{print "  - " $1 " (" $2 ")"}'
else
    log_info "未发现现有工作流"
fi

echo ""

# 10. 系统资源检查
log_info "检查系统资源..."
echo "节点资源使用情况:"
kubectl top nodes 2>/dev/null || log_warning "无法获取节点资源使用情况（需要metrics-server）"

echo ""
echo "========================================"
echo "  诊断完成"
echo "========================================"

# 给出建议
echo ""
log_info "建议操作:"
echo "1. 如果模板不存在，运行: ./scripts/deploy-all.sh --skip-test"
echo "2. 如果权限有问题，运行: kubectl apply -f playbook/rbac.yaml"
echo "3. 如果Argo未安装，运行: kubectl apply -f playbook/install-argo.yaml"
echo "4. 清理所有资源，运行: ./scripts/cleanup.sh full"
echo "5. 查看详细日志，运行: kubectl logs -n $NAMESPACE -l app=workflow-controller"