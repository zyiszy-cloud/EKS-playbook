#!/bin/bash
set -euo pipefail

# =========================================================
# TKE Chaos Playbook 增强版部署工具
# 智能沙箱复用测试平台一键部署脚本
# =========================================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # 无颜色

# 默认配置
NAMESPACE="tke-chaos-test"
CLUSTER_ID="tke-cluster"
REPLICAS=3
POD_IMAGE="nginx:alpine"
CPU_REQUEST="100m"
CPU_LIMIT="200m"
MEMORY_REQUEST="128Mi"
MEMORY_LIMIT="256Mi"
DELAY="30s"
ITERATIONS=2
WEBHOOK_URL=""
FORCE_REDEPLOY=false
SKIP_TEST=false
AUTO_START_TEST=true
INTERACTIVE_MODE=false
QUICK_MODE=false
SELECTED_WORKFLOW=""
LOG_LEVEL="info" # debug, info, warn, error
CONFIG_FILE="./.tke-chaos-config"
DEFAULT_WORKFLOW="supernode-sandbox-deployment-template"
SUPPORTED_WORKFLOWS=("supernode-sandbox-deployment-template" "supernode-rolling-update-template")

# 日志函数
log_debug() {
    if [[ "$LOG_LEVEL" == "debug" ]]; then
        echo -e "${BLUE}[DEBUG] $1${NC}"
    fi
}

log_info() {
    if [[ "$LOG_LEVEL" == "debug" || "$LOG_LEVEL" == "info" ]]; then
        echo -e "${BLUE}[INFO] $1${NC}"
    fi
}

log_success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

log_warn() {
    if [[ "$LOG_LEVEL" == "debug" || "$LOG_LEVEL" == "info" || "$LOG_LEVEL" == "warn" ]]; then
        echo -e "${YELLOW}[WARN] $1${NC}"
    fi
}

log_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

# 显示帮助信息
show_help() {
    echo ""
    echo "TKE Chaos Playbook 部署工具"
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "选项:"
    echo "  -n, --namespace     指定命名空间 (默认: $NAMESPACE)"
    echo "  -c, --cluster-id    指定集群ID (默认: $CLUSTER_ID)"
    echo "  -r, --replicas      指定Pod副本数 (默认: $REPLICAS)"
    echo "  -i, --image         指定Pod镜像 (默认: $POD_IMAGE)"
    echo "  -cpu, --cpu         指定CPU资源 (请求/限制，默认: $CPU_REQUEST/$CPU_LIMIT)"
    echo "  -mem, --memory      指定内存资源 (请求/限制，默认: $MEMORY_REQUEST/$MEMORY_LIMIT)"
    echo "  -d, --delay         指定测试间隔 (默认: $DELAY)"
    echo "  -it, --iterations   指定测试迭代次数 (默认: $ITERATIONS)"
    echo "  -w, --webhook       指定企业微信Webhook URL"
    echo "  -f, --force         强制重新部署"
    echo "  -s, --skip-test     跳过测试"
    echo "  -i, --interactive   交互式配置模式"
    echo "  -wf, --workflow     指定工作流模板 (可选: ${SUPPORTED_WORKFLOWS[*]})"
    echo "  -l, --log-level     设置日志级别 (debug, info, warn, error, 默认: $LOG_LEVEL)"
    echo "  -cf, --config-file  指定配置文件路径 (默认: $CONFIG_FILE)"
    echo "  -h, --help          显示帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 --quick"
    echo "  $0 --interactive"
    echo "  $0 --namespace my-test --replicas 5 --cpu 200m/500m"
    echo ""
}

# 检查模板是否存在
check_template_exists() {
    local template_name=$1
    log_info "检查模板 $template_name 是否存在"
    if kubectl get clusterworkflowtemplate $template_name >/dev/null 2>&1; then
        log_success "模板 $template_name 已存在"
        return 0
    else
        log_warn "模板 $template_name 不存在"
        return 1
    fi
}

# 删除已存在的工作流
delete_existing_workflows() {
    log_info "清理命名空间 $NAMESPACE 中的现有工作流"
    workflows=$(kubectl get workflows -n $NAMESPACE --no-headers -o custom-columns=NAME:.metadata.name 2>/dev/null || true)
    if [ -n "$workflows" ]; then
        for workflow in $workflows; do
            log_info "删除工作流: $workflow"
            kubectl delete workflow $workflow -n $NAMESPACE --ignore-not-found=true
        done
        log_success "工作流清理完成"
    else
        log_info "未发现需要清理的工作流"
    fi
}

# 简化配置
simple_config() {
    log_info "使用简化配置"
    # 设置副本数
    read -p "请输入Pod副本数 (默认: $REPLICAS): " input_replicas
    if [ -n "$input_replicas" ]; then
        if [[ $input_replicas =~ ^[0-9]+$ ]] && [ $input_replicas -gt 0 ]; then
            REPLICAS=$input_replicas
        else
            log_error "无效的副本数，使用默认值 $REPLICAS"
        fi
    fi

    # 设置企业微信通知
    read -p "是否配置企业微信通知? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "请输入企业微信Webhook URL: " input_webhook
        if [ -n "$input_webhook" ]; then
            WEBHOOK_URL=$input_webhook
            log_success "企业微信通知已配置"
        else
            log_warn "未输入Webhook URL，跳过配置"
        fi
    fi
}

# 智能部署模式
smart_deployment_mode() {
    log_info "进入智能部署模式"

    # 检查可用的工作流模板
    echo -e "${CYAN}可用的工作流模板:${NC}"
    echo "1. supernode-sandbox-deployment-template (默认) - 沙箱部署测试"
    echo "2. supernode-rolling-update-template - 滚动更新测试"

    read -p "请选择工作流模板 (1-2，默认: 1): " -n 1 -r
    echo
    case $REPLY in
        2)
            SELECTED_WORKFLOW="supernode-rolling-update-template"
            ;;
        *)
            SELECTED_WORKFLOW="supernode-sandbox-deployment-template"
            ;;
    esac

    log_info "已选择工作流模板: $SELECTED_WORKFLOW"

    # 根据选择的工作流设置相应参数
    if [ "$SELECTED_WORKFLOW" = "supernode-rolling-update-template" ]; then
        # 滚动更新测试默认1次迭代
        ROLLING_UPDATE_ITERATIONS=1
        log_info "滚动更新测试需要额外参数"
        read -p "请输入更新迭代次数 (默认: $ROLLING_UPDATE_ITERATIONS): " input_iterations
        if [ -n "$input_iterations" ]; then
            if [[ $input_iterations =~ ^[0-9]+$ ]] && [ $input_iterations -gt 0 ]; then
                ITERATIONS=$input_iterations
            else
                log_error "无效的迭代次数，使用默认值 $ROLLING_UPDATE_ITERATIONS"
                ITERATIONS=$ROLLING_UPDATE_ITERATIONS
            fi
        else
            ITERATIONS=$ROLLING_UPDATE_ITERATIONS
        fi
    fi

    simple_config
}

# 参数解析
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -n|--namespace)
                NAMESPACE="$2"
                shift 2
                ;;
            -c|--cluster-id)
                CLUSTER_ID="$2"
                shift 2
                ;;
            -r|--replicas)
                REPLICAS="$2"
                shift 2
                ;;
            -i|--image)
                POD_IMAGE="$2"
                shift 2
                ;;
            -cpu|--cpu)
                CPU_SPEC="$2"
                # 分割CPU请求和限制
                CPU_REQUEST=$(echo $CPU_SPEC | cut -d'/' -f1)
                CPU_LIMIT=$(echo $CPU_SPEC | cut -d'/' -f2)
                shift 2
                ;;
            -mem|--memory)
                MEM_SPEC="$2"
                # 分割内存请求和限制
                MEMORY_REQUEST=$(echo $MEM_SPEC | cut -d'/' -f1)
                MEMORY_LIMIT=$(echo $MEM_SPEC | cut -d'/' -f2)
                shift 2
                ;;
            -d|--delay)
                DELAY="$2"
                shift 2
                ;;
            -it|--iterations)
                ITERATIONS="$2"
                shift 2
                ;;
            -w|--webhook)
                WEBHOOK_URL="$2"
                shift 2
                ;;
            -f|--force)
                FORCE_REDEPLOY=true
                shift
                ;;
            -s|--skip-test)
                SKIP_TEST=true
                AUTO_START_TEST=false
                shift
                ;;
            -q|--quick)
                QUICK_MODE=true
                INTERACTIVE_MODE=false
                shift
                ;;
            -i|--interactive)
                INTERACTIVE_MODE=true
                QUICK_MODE=false
                shift
                ;;
            -wf|--workflow)
                SELECTED_WORKFLOW="$2"
                # 验证工作流是否受支持
                if [[ ! "${SUPPORTED_WORKFLOWS[@]}" =~ "$SELECTED_WORKFLOW" ]]; then
                    log_error "不支持的工作流模板: $SELECTED_WORKFLOW"
                    log_error "支持的模板: ${SUPPORTED_WORKFLOWS[*]}"
                    exit 1
                fi
                shift 2
                ;;
            -l|--log-level)
                LOG_LEVEL="$2"
                # 验证日志级别
                if [[ ! "debug info warn error" =~ "$LOG_LEVEL" ]]; then
                    log_error "无效的日志级别: $LOG_LEVEL"
                    log_error "支持的级别: debug, info, warn, error"
                    exit 1
                fi
                shift 2
                ;;
            -cf|--config-file)
                CONFIG_FILE="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # 从配置文件加载配置（如果存在）
    if [ -f "$CONFIG_FILE" ]; then
        log_info "从配置文件 $CONFIG_FILE 加载配置"
        source "$CONFIG_FILE"
    fi
}

# 参数验证
validate_parameters() {
    log_info "验证参数"

    # 验证副本数
    if ! [[ $REPLICAS =~ ^[0-9]+$ ]] || [ $REPLICAS -eq 0 ]; then
        log_error "无效的副本数: $REPLICAS，必须是正整数"
        exit 1
    fi

    # 验证迭代次数
    if ! [[ $ITERATIONS =~ ^[0-9]+$ ]] || [ $ITERATIONS -eq 0 ]; then
        log_error "无效的迭代次数: $ITERATIONS，必须是正整数"
        exit 1
    fi

    # 验证CPU格式
    if ! [[ $CPU_REQUEST =~ ^[0-9]+[m]?$ ]] || ! [[ $CPU_LIMIT =~ ^[0-9]+[m]?$ ]]; then
        log_error "无效的CPU格式: $CPU_REQUEST/$CPU_LIMIT，应为数字加可选的'm'"
        exit 1
    fi

    # 验证内存格式
    if ! [[ $MEMORY_REQUEST =~ ^[0-9]+[EPTGMK]i?$ ]] || ! [[ $MEMORY_LIMIT =~ ^[0-9]+[EPTGMK]i?$ ]]; then
        log_error "无效的内存格式: $MEMORY_REQUEST/$MEMORY_LIMIT，应为数字加单位(E,P,T,G,M,K)加可选的'i'"
        exit 1
    fi

    # 验证延迟格式
    if ! [[ $DELAY =~ ^[0-9]+[smhd]?$ ]]; then
        log_error "无效的延迟格式: $DELAY，应为数字加可选的单位(s,m,h,d)"
        exit 1
    fi

    log_success "参数验证通过"
}

# 交互式配置
interactive_config() {
    log_info "进入交互式配置模式"

    echo -e "${CYAN}========================================"
    echo "        交互式配置"
    echo "========================================${NC}"

    # 集群ID
    read -p "请输入集群ID (默认: $CLUSTER_ID): " input_cluster
    if [ -n "$input_cluster" ]; then
        CLUSTER_ID=$input_cluster
    fi

    # 命名空间
    read -p "请输入命名空间 (默认: $NAMESPACE): " input_namespace
    if [ -n "$input_namespace" ]; then
        NAMESPACE=$input_namespace
    fi

    # Pod副本数
    read -p "请输入Pod副本数 (默认: $REPLICAS): " input_replicas
    if [ -n "$input_replicas" ]; then
        if [[ $input_replicas =~ ^[0-9]+$ ]] && [ $input_replicas -gt 0 ]; then
            REPLICAS=$input_replicas
        else
            log_error "无效的副本数，使用默认值 $REPLICAS"
        fi
    fi

    # Pod镜像
    read -p "请输入Pod镜像 (默认: $POD_IMAGE): " input_image
    if [ -n "$input_image" ]; then
        POD_IMAGE=$input_image
    fi

    # CPU资源
    read -p "请输入CPU资源 (请求/限制，默认: $CPU_REQUEST/$CPU_LIMIT): " input_cpu
    if [ -n "$input_cpu" ]; then
        CPU_REQUEST=$(echo $input_cpu | cut -d'/' -f1)
        CPU_LIMIT=$(echo $input_cpu | cut -d'/' -f2)
        if ! [[ $CPU_REQUEST =~ ^[0-9]+[m]?$ ]] || ! [[ $CPU_LIMIT =~ ^[0-9]+[m]?$ ]]; then
            log_error "无效的CPU格式，使用默认值 $CPU_REQUEST/$CPU_LIMIT"
            CPU_REQUEST="100m"
            CPU_LIMIT="200m"
        fi
    fi

    # 内存资源
    read -p "请输入内存资源 (请求/限制，默认: $MEMORY_REQUEST/$MEMORY_LIMIT): " input_memory
    if [ -n "$input_memory" ]; then
        MEMORY_REQUEST=$(echo $input_memory | cut -d'/' -f1)
        MEMORY_LIMIT=$(echo $input_memory | cut -d'/' -f2)
        if ! [[ $MEMORY_REQUEST =~ ^[0-9]+[EPTGMK]i?$ ]] || ! [[ $MEMORY_LIMIT =~ ^[0-9]+[EPTGMK]i?$ ]]; then
            log_error "无效的内存格式，使用默认值 $MEMORY_REQUEST/$MEMORY_LIMIT"
            MEMORY_REQUEST="128Mi"
            MEMORY_LIMIT="256Mi"
        fi
    fi

    # 测试间隔
    read -p "请输入测试间隔 (默认: $DELAY): " input_delay
    if [ -n "$input_delay" ]; then
        if [[ $input_delay =~ ^[0-9]+[smhd]?$ ]]; then
            DELAY=$input_delay
        else
            log_error "无效的延迟格式，使用默认值 $DELAY"
        fi
    fi

    # 测试迭代次数
    read -p "请输入测试迭代次数 (默认: $ITERATIONS): " input_iterations
    if [ -n "$input_iterations" ]; then
        if [[ $input_iterations =~ ^[0-9]+$ ]] && [ $input_iterations -gt 0 ]; then
            ITERATIONS=$input_iterations
        else
            log_error "无效的迭代次数，使用默认值 $ITERATIONS"
        fi
    fi

    # 企业微信通知
    read -p "是否配置企业微信通知? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "请输入企业微信Webhook URL: " input_webhook
        if [ -n "$input_webhook" ]; then
            # 验证URL格式
            if [[ "$input_webhook" =~ ^https://qyapi\.weixin\.qq\.com/cgi-bin/webhook/send\?key=[a-zA-Z0-9_-]+$ ]]; then
                WEBHOOK_URL="$input_webhook"
                log_success "企业微信通知已配置"
            else
                log_warn "无效的企业微信Webhook URL格式，跳过配置"
                log_info "正确格式: https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=YOUR_KEY"
            fi
        else
            log_warn "未输入Webhook URL，跳过配置"
        fi
    fi

    # 工作流选择
    echo -e "${CYAN}可用的工作流模板:${NC}"
    echo "1. supernode-sandbox-deployment-template (默认) - 沙箱部署测试"
    echo "2. supernode-rolling-update-template - 滚动更新测试"
    read -p "请选择工作流模板 (1-2，默认: 1): " -n 1 -r
    echo
    case $REPLY in
        2)
            SELECTED_WORKFLOW="supernode-rolling-update-template"
            ;;
        *)
            SELECTED_WORKFLOW="supernode-sandbox-deployment-template"
            ;;
    esac

    # 自动启动测试
    read -p "是否自动启动测试? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        AUTO_START_TEST=false
    else
        AUTO_START_TEST=true
    fi

    # 保存配置
    read -p "是否保存配置以便下次使用? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        save_config
    fi
}

# 保存配置
save_config() {
    log_info "保存配置到 $CONFIG_FILE"
    cat > "$CONFIG_FILE" <<EOL
# TKE Chaos Playbook 配置文件
# 生成时间: $(date '+%Y-%m-%d %H:%M:%S')

NAMESPACE="$NAMESPACE"
CLUSTER_ID="$CLUSTER_ID"
REPLICAS=$REPLICAS
POD_IMAGE="$POD_IMAGE"
CPU_REQUEST="$CPU_REQUEST"
CPU_LIMIT="$CPU_LIMIT"
MEMORY_REQUEST="$MEMORY_REQUEST"
MEMORY_LIMIT="$MEMORY_LIMIT"
DELAY="$DELAY"
ITERATIONS=$ITERATIONS
WEBHOOK_URL="$WEBHOOK_URL"
SELECTED_WORKFLOW="$SELECTED_WORKFLOW"
AUTO_START_TEST=$AUTO_START_TEST
LOG_LEVEL="$LOG_LEVEL"
EOL

    if [ $? -eq 0 ]; then
        log_success "配置已保存到 $CONFIG_FILE"
    else
        log_error "保存配置失败"
    fi
}

# 环境检查
check_environment() {
    log_info "检查环境"

    # 检查kubectl是否安装
    if ! command -v kubectl >/dev/null 2>&1; then
        log_error "未找到kubectl，请先安装kubectl"
        exit 1
    fi

    # 检查kubectl版本
    KUBECTL_VERSION=$(kubectl version --client=true -o json 2>/dev/null | grep -o '"gitVersion":"[^"]*"' | cut -d'"' -f4 || echo "unknown")
    log_info "kubectl版本: $KUBECTL_VERSION"
    #检查集群连接
    if ! kubectl cluster-info >/dev/null 2>&1; then
        log_error "无法连接到Kubernetes集群"
        log_error "请检查kubeconfig配置"
        exit 1
    fi

    log_success "环境检查通过"
}

# 主函数
main() {
    echo "========================================"
    echo "  TKE Chaos Playbook 部署工具"
    echo "========================================"
    
    # 解析参数
    parse_args "$@"
    
    # 验证参数
    validate_parameters
    
    # 检查环境
    check_environment
    
    # 根据模式执行相应操作
    if [ "$INTERACTIVE_MODE" = true ]; then
        interactive_config
    elif [ "$QUICK_MODE" = false ]; then
        smart_deployment_mode
    fi
    
    # 显示最终配置
    echo ""
    echo "========================================"
    echo "  最终配置"
    echo "========================================"
    echo "命名空间: $NAMESPACE"
    echo "集群ID: $CLUSTER_ID"
    echo "Pod副本数: $REPLICAS"
    echo "Pod镜像: $POD_IMAGE"
    echo "CPU资源: $CPU_REQUEST/$CPU_LIMIT"
    echo "内存资源: $MEMORY_REQUEST/$MEMORY_LIMIT"
    echo "测试间隔: $DELAY"
    echo "测试迭代: $ITERATIONS"
    echo "选择的工作流: $SELECTED_WORKFLOW"
    echo "企业微信通知: $([ -n "$WEBHOOK_URL" ] && echo "已配置" || echo "未配置")"
    echo "========================================"
    
    # 确认部署
    if [ "$QUICK_MODE" = false ]; then
        read -p "确认开始部署? (Y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            log_info "取消部署"
            exit 0
        fi
    fi
    
    # 开始部署
    log_info "开始部署TKE Chaos Playbook..."
    
    # 创建命名空间
    log_info "创建命名空间: $NAMESPACE"
    kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
    
    # 检查并部署Argo Workflows
    log_info "检查Argo Workflows..."
    if ! kubectl get deployment tke-chaos-argo-workflows-workflow-controller -n "$NAMESPACE" >/dev/null 2>&1; then
        log_info "部署Argo Workflows..."
        kubectl apply -f playbook/install-argo.yaml || {
            log_error "Argo Workflows部署失败"
            exit 1
        }
        
        # 等待Argo Workflows就绪
        log_info "等待Argo Workflows就绪..."
        kubectl wait --for=condition=available --timeout=300s deployment/tke-chaos-argo-workflows-workflow-controller -n "$NAMESPACE" || {
            log_warn "Argo Workflows可能需要更多时间启动"
        }
    else
        log_success "Argo Workflows已存在"
    fi
    
    # 部署RBAC权限
    log_info "部署RBAC权限..."
    kubectl apply -f playbook/rbac.yaml || {
        log_error "RBAC部署失败"
        exit 1
    }
    
    # 部署工作流模板
    log_info "部署工作流模板..."
    kubectl apply -f playbook/template/ || {
        log_error "模板部署失败"
        exit 1
    }
    
    # 等待模板就绪
    log_info "等待模板就绪..."
    sleep 5
    
    # 检查模板状态
    for template in "${SUPPORTED_WORKFLOWS[@]}"; do
        if check_template_exists "$template"; then
            log_success "模板 $template 部署成功"
        else
            log_error "模板 $template 部署失败"
            exit 1
        fi
    done
    
    log_success "所有模板部署完成"
    
    # 如果不跳过测试，启动测试
    if [ "$SKIP_TEST" = false ] && [ "$AUTO_START_TEST" = true ]; then
        log_info "启动测试工作流..."
        
        # 确保命名空间存在
        kubectl get namespace "$NAMESPACE" >/dev/null 2>&1 || {
            log_warn "命名空间 $NAMESPACE 不存在，正在创建..."
            kubectl create namespace "$NAMESPACE"
        }
        
        # 根据选择的工作流启动相应测试
        case "$SELECTED_WORKFLOW" in
            "supernode-sandbox-deployment-template")
                log_info "启动沙箱部署测试..."
                
                # 动态生成工作流配置
                cat > /tmp/sandbox-deployment-workflow.yaml <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: sandbox-deployment-test-
  namespace: $NAMESPACE
  labels:
    test-type: "deployment-sandbox-reuse"
spec:
  serviceAccountName: tke-chaos
  entrypoint: deployment-sandbox-test
  arguments:
    parameters:
    # 基础配置
    - name: cluster-id
      value: "$CLUSTER_ID"
    - name: webhook-url
      value: "$WEBHOOK_URL"
    
    # 测试配置
    - name: kubeconfig-secret-name
      value: ""
    - name: deployment-name-prefix
      value: "sandbox-deployment-test"
    - name: replicas
      value: "$REPLICAS"
    - name: pod-image
      value: "$POD_IMAGE"
    - name: namespace
      value: "$NAMESPACE"
    - name: test-iterations
      value: "$ITERATIONS"
    - name: delay-between-tests
      value: "$DELAY"
    
    # 资源配置
    - name: cpu-request
      value: "$CPU_REQUEST"
    - name: memory-request
      value: "$MEMORY_REQUEST"
    - name: cpu-limit
      value: "$CPU_LIMIT"
    - name: memory-limit
      value: "$MEMORY_LIMIT"

  workflowTemplateRef:
    name: supernode-sandbox-deployment-template
    clusterScope: true
EOF
                
                if kubectl create -f /tmp/sandbox-deployment-workflow.yaml; then
                    log_success "沙箱部署测试已启动"
                    # 获取工作流名称
                    sleep 2
                    WORKFLOW_NAME=$(kubectl get workflows -n "$NAMESPACE" --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1].metadata.name}' 2>/dev/null || echo "unknown")
                    log_info "工作流名称: $WORKFLOW_NAME"
                    # 清理临时文件
                    rm -f /tmp/sandbox-deployment-workflow.yaml
                else
                    log_error "启动沙箱部署测试失败"
                    log_info "调试信息："
                    kubectl get clusterworkflowtemplate supernode-sandbox-deployment-template >/dev/null 2>&1 && log_info "✅ 模板存在" || log_error "❌ 模板不存在"
                    rm -f /tmp/sandbox-deployment-workflow.yaml
                    exit 1
                fi
                ;;
            "supernode-rolling-update-template")
                log_info "启动滚动更新测试..."
                
                # 动态生成工作流配置
                cat > /tmp/rolling-update-workflow.yaml <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: rolling-update-test-
  namespace: $NAMESPACE
  labels:
    test-type: "rolling-update"
spec:
  serviceAccountName: tke-chaos
  entrypoint: rolling-update-sandbox-test
  arguments:
    parameters:
    # 基础配置
    - name: cluster-id
      value: "$CLUSTER_ID"
    - name: webhook-url
      value: "$WEBHOOK_URL"
    - name: kubeconfig-secret-name
      value: ""
    - name: namespace
      value: "$NAMESPACE"
    
    # 滚动更新配置
    - name: deployment-name
      value: "rolling-update-test"
    - name: replicas
      value: "$REPLICAS"
    - name: initial-image
      value: "nginx:1.20-alpine"
    - name: updated-image
      value: "nginx:1.21-alpine"
    - name: update-iterations
      value: "$ITERATIONS"
    - name: delay-between-updates
      value: "$DELAY"
    
    # 资源配置
    - name: cpu-request
      value: "$CPU_REQUEST"
    - name: memory-request
      value: "$MEMORY_REQUEST"
    - name: cpu-limit
      value: "$CPU_LIMIT"
    - name: memory-limit
      value: "$MEMORY_LIMIT"

  workflowTemplateRef:
    name: supernode-rolling-update-template
    clusterScope: true
EOF
                
                if kubectl create -f /tmp/rolling-update-workflow.yaml; then
                    log_success "滚动更新测试已启动"
                    # 获取工作流名称
                    sleep 2
                    WORKFLOW_NAME=$(kubectl get workflows -n "$NAMESPACE" --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1].metadata.name}' 2>/dev/null || echo "unknown")
                    log_info "工作流名称: $WORKFLOW_NAME"
                    # 清理临时文件
                    rm -f /tmp/rolling-update-workflow.yaml
                else
                    log_error "启动滚动更新测试失败"
                    log_info "调试信息："
                    kubectl get clusterworkflowtemplate supernode-rolling-update-template >/dev/null 2>&1 && log_info "✅ 模板存在" || log_error "❌ 模板不存在"
                    rm -f /tmp/rolling-update-workflow.yaml
                    exit 1
                fi
                ;;
            *)
                log_warn "未知的工作流模板: $SELECTED_WORKFLOW"
                ;;
        esac
        
        # 显示监控命令
        echo ""
        echo "========================================"
        echo "  监控命令"
        echo "========================================"
        echo "查看工作流状态:"
        echo "  kubectl get workflows -n $NAMESPACE -w"
        echo ""
        echo "查看详细日志:"
        echo "  kubectl logs -n $NAMESPACE -l workflows.argoproj.io/workflow"
        echo ""
        echo "查看Pod状态:"
        echo "  kubectl get pods -n $NAMESPACE"
        echo "========================================"
    fi
    
    log_success "部署完成！"
}

# 执行主函数
main "$@"