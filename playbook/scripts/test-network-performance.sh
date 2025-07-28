#!/bin/bash

# TKE SuperNode 网络性能测试验证脚本

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

# 显示帮助信息
show_help() {
    echo ""
    echo -e "${BLUE}TKE SuperNode 网络性能测试验证工具${NC}"
    echo ""
    echo -e "${YELLOW}用法:${NC}"
    echo "  $0 [选项]"
    echo ""
    echo -e "${YELLOW}选项:${NC}"
    echo "  -t, --test-type <type>    测试类型: latency/bandwidth/all (默认: latency)"
    echo "  -c, --client-pods <num>   客户端Pod数量 (默认: 2)"
    echo "  -s, --server-pods <num>   服务端Pod数量 (默认: 1)"
    echo "  -d, --duration <time>     测试持续时间 (默认: 60s)"
    echo "  -w, --wait                等待测试完成"
    echo "  -h, --help                显示帮助信息"
    echo ""
    echo -e "${YELLOW}示例:${NC}"
    echo "  $0                        # 运行默认延迟测试"
    echo "  $0 -t all -c 3 -s 2       # 运行全部测试，3个客户端，2个服务端"
    echo "  $0 -t bandwidth -w        # 运行带宽测试并等待完成"
    echo ""
}

# 默认参数
TEST_TYPE="latency"
CLIENT_PODS="2"
SERVER_PODS="1"
DURATION="60s"
WAIT_FOR_COMPLETION=false

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--test-type)
            TEST_TYPE="$2"
            shift 2
            ;;
        -c|--client-pods)
            CLIENT_PODS="$2"
            shift 2
            ;;
        -s|--server-pods)
            SERVER_PODS="$2"
            shift 2
            ;;
        -d|--duration)
            DURATION="$2"
            shift 2
            ;;
        -w|--wait)
            WAIT_FOR_COMPLETION=true
            shift
            ;;
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

echo -e "${BLUE}"
echo "========================================================"
echo "  TKE SuperNode 网络性能测试验证工具"
echo "========================================================"
echo -e "${NC}"

# 检查kubectl连接
log_info "检查kubectl连接..."
if ! kubectl cluster-info &> /dev/null; then
    log_error "无法连接到Kubernetes集群"
    exit 1
fi
log_success "kubectl连接正常"

# 检查必要的模板
log_info "检查必要的模板..."
REQUIRED_TEMPLATES=("kubectl-cmd" "network-performance-template")
MISSING_TEMPLATES=()

for template in "${REQUIRED_TEMPLATES[@]}"; do
    if kubectl get clusterworkflowtemplate "$template" &>/dev/null; then
        log_success "✓ 模板 $template 存在"
    else
        log_error "✗ 模板 $template 不存在"
        MISSING_TEMPLATES+=("$template")
    fi
done

if [ ${#MISSING_TEMPLATES[@]} -gt 0 ]; then
    log_error "缺少必要的模板，请先运行:"
    echo "  ./playbook/scripts/deploy-all-templates.sh"
    echo "或者:"
    exit 1
fi

# 清理旧的测试资源
log_info "清理旧的测试资源..."
kubectl delete namespace tke-network-test --ignore-not-found=true
kubectl delete workflows -n tke-chaos-test -l network-performance-test=true --ignore-not-found=true

# 等待资源清理完成
sleep 5

# 创建网络性能测试工作流
log_info "创建网络性能测试工作流..."
cat > /tmp/network-performance-test.yaml << EOF
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: network-performance-test-
  namespace: tke-chaos-test
  labels:
    network-performance-test: "true"
    test-type: "$TEST_TYPE"
spec:
  entrypoint: main
  serviceAccountName: tke-chaos
  arguments:
    parameters:
    - name: test-type
      value: "$TEST_TYPE"
    - name: client-pods
      value: "$CLIENT_PODS"
    - name: server-pods
      value: "$SERVER_PODS"
    - name: test-duration
      value: "$DURATION"
    - name: supernode-selector
      value: "node.kubernetes.io/instance-type=eklet"
    - name: kubeconfig-secret-name
      value: ""
  templates:
  - name: main
    steps:
    - - name: network-performance-test
        arguments:
          parameters:
          - name: test-type
            value: "{{workflow.parameters.test-type}}"
          - name: client-pods
            value: "{{workflow.parameters.client-pods}}"
          - name: server-pods
            value: "{{workflow.parameters.server-pods}}"
          - name: test-duration
            value: "{{workflow.parameters.test-duration}}"
          - name: supernode-selector
            value: "{{workflow.parameters.supernode-selector}}"
          - name: kubeconfig-secret-name
            value: "{{workflow.parameters.kubeconfig-secret-name}}"
        templateRef:
          name: network-performance-template
          template: main
          clusterScope: true
EOF

# 提交工作流
WORKFLOW_NAME=$(kubectl apply -f /tmp/network-performance-test.yaml -o jsonpath='{.metadata.name}')
if [ -n "$WORKFLOW_NAME" ]; then
    log_success "网络性能测试工作流已提交: $WORKFLOW_NAME"
    
    echo ""
    log_info "测试配置:"
    echo "  测试类型: $TEST_TYPE"
    echo "  客户端Pod数: $CLIENT_PODS"
    echo "  服务端Pod数: $SERVER_PODS"
    echo "  测试持续时间: $DURATION"
    echo ""
    
    log_info "📊 查看测试进度:"
    echo "  kubectl get workflow $WORKFLOW_NAME -n tke-chaos-test"
    echo ""
    
    log_info "📋 查看测试日志:"
    echo "  kubectl logs -n tke-chaos-test -l workflows.argoproj.io/workflow=$WORKFLOW_NAME -f"
    echo ""
    
    if [ "$WAIT_FOR_COMPLETION" = true ]; then
        log_info "等待测试完成..."
        
        # 等待工作流完成
        kubectl wait --for=condition=Completed workflow/$WORKFLOW_NAME -n tke-chaos-test --timeout=1800s || {
            log_warning "测试超时或失败"
            kubectl get workflow/$WORKFLOW_NAME -n tke-chaos-test -o yaml
        }
        
        # 显示最终状态
        FINAL_STATUS=$(kubectl get workflow "$WORKFLOW_NAME" -n tke-chaos-test -o jsonpath='{.status.phase}' 2>/dev/null || echo "Unknown")
        if [ "$FINAL_STATUS" = "Succeeded" ]; then
            log_success "网络性能测试完成！"
            
            # 显示测试结果
            log_info "测试结果:"
            kubectl logs -n tke-chaos-test -l workflows.argoproj.io/workflow=$WORKFLOW_NAME | tail -50
        else
            log_error "测试失败，状态: $FINAL_STATUS"
        fi
    fi
    
    log_info "🧹 清理测试资源:"
    echo "  kubectl delete workflow $WORKFLOW_NAME -n tke-chaos-test"
    echo "  kubectl delete namespace tke-network-test"
    echo ""
    
else
    log_error "工作流提交失败"
    exit 1
fi

# 清理临时文件
rm -f /tmp/network-performance-test.yaml

log_success "网络性能测试验证完成！"