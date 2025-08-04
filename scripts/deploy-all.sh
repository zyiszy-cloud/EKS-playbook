#!/bin/bash

# TKE Chaos Playbook 增强版一键部署脚本
# 功能：智能部署超级节点沙箱复用测试环境
# 特性：自动检测并重新部署模板、工作流选择、Pod数量配置等

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 默认配置
NAMESPACE="tke-chaos-test"
DEFAULT_ITERATIONS=1
DEFAULT_REPLICAS=1
DEFAULT_IMAGE="nginx:alpine"
DEFAULT_CPU_REQUEST="100m"
DEFAULT_MEMORY_REQUEST="128Mi"
DEFAULT_CPU_LIMIT="200m"
DEFAULT_MEMORY_LIMIT="256Mi"
DEFAULT_DELAY="20s"

# 默认工作流
DEFAULT_WORKFLOW="sandbox-reuse-precise-test.yaml"

# 全局变量
FORCE_REDEPLOY=false
SELECTED_WORKFLOW=""
AUTO_START_TEST=true

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 显示帮助信息
show_help() {
    cat << EOF
TKE Chaos Playbook 一键部署脚本

使用方法: $0 [选项]

选项:
  -i, --iterations NUM    测试迭代次数 (1-20, 默认: 1)
  -r, --replicas NUM      Deployment副本数 (默认: 1)
  -w, --webhook URL       企业微信webhook地址
  -c, --cluster-id ID     集群ID (默认: tke-cluster)
  -n, --namespace NS      命名空间 (默认: tke-chaos-test)
  --image IMAGE           Pod镜像 (默认: nginx:alpine)
  --cpu-request CPU       CPU请求 (默认: 100m)
  --memory-request MEM    内存请求 (默认: 128Mi)
  --cpu-limit CPU         CPU限制 (默认: 200m)
  --memory-limit MEM      内存限制 (默认: 256Mi)
  --delay TIME            测试间隔 (默认: 20s)
  -q, --quick             快速模式，跳过确认
  --interactive           交互式配置模式
  --force-redeploy        强制重新部署所有模板
  --workflow FILE         指定工作流文件
  --skip-test             只部署组件，不启动测试
  -h, --help              显示帮助信息

示例:
  $0                                    # 智能部署模式选择
  $0 -q                                 # 快速部署（默认配置）
  $0 -r 10 -w "webhook"                # 指定Pod数量和通知
  $0 --interactive                      # 完全交互式配置
  $0 --skip-test                        # 只部署模板不测试

特性: 
  - 自动重新部署模板
  - 简化的配置流程
  - 支持任意Pod数量
EOF
}

# 检查模板是否存在
check_template_exists() {
    local template_name="$1"
    kubectl get clusterworkflowtemplate "$template_name" &> /dev/null
}

# 删除现有模板
delete_existing_template() {
    local template_name="$1"
    if check_template_exists "$template_name"; then
        log_warning "删除现有模板: $template_name"
        if kubectl delete clusterworkflowtemplate "$template_name" --ignore-not-found=true; then
            log_info "模板删除成功: $template_name"
            return 0
        else
            log_error "模板删除失败: $template_name"
            return 1
        fi
    else
        log_info "模板不存在，无需删除: $template_name"
        return 0
    fi
}

# 检查工作流是否存在
check_workflow_exists() {
    local workflow_name="$1"
    kubectl get workflow -n "$NAMESPACE" --no-headers 2>/dev/null | grep -q "^$workflow_name"
}

# 删除现有工作流
delete_existing_workflows() {
    log_info "检查并清理现有工作流..."
    local existing_workflows=$(kubectl get workflows -n "$NAMESPACE" --no-headers 2>/dev/null | awk '{print $1}' || echo "")
    
    if [ -n "$existing_workflows" ]; then
        log_warning "发现现有工作流，正在清理..."
        for workflow in $existing_workflows; do
            log_info "删除工作流: $workflow"
            kubectl delete workflow "$workflow" -n "$NAMESPACE" --grace-period=0 --force 2>/dev/null || true
        done
        
        # 等待工作流完全删除
        local count=0
        while kubectl get workflows -n "$NAMESPACE" --no-headers 2>/dev/null | grep -q .; do
            sleep 1
            count=$((count + 1))
            if [ $count -gt 30 ]; then
                log_warning "工作流删除超时，继续执行"
                break
            fi
        done
        log_success "现有工作流清理完成"
    else
        log_info "未发现现有工作流"
    fi
}

# 简化配置：Pod数量和企业微信通知
simple_config() {
    echo ""
    echo -e "${CYAN}========================================"
    echo "  测试配置"
    echo "========================================${NC}"
    echo ""
    
    # Pod数量配置
    echo -e "${BLUE}1. Pod数量配置${NC}"
    echo "当前配置: $REPLICAS 个Pod副本"
    echo ""
    
    read -p "是否修改Pod数量? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        while true; do
            read -p "请输入Pod副本数: " new_replicas
            if [[ "$new_replicas" =~ ^[1-9][0-9]*$ ]] && [ "$new_replicas" -ge 1 ]; then
                REPLICAS="$new_replicas"
                log_success "Pod副本数设置为: $REPLICAS"
                break
            else
                log_error "请输入大于0的正整数"
            fi
        done
    fi
    
    echo ""
    
    # 企业微信通知配置
    echo -e "${BLUE}2. 企业微信通知配置${NC}"
    read -p "是否配置企业微信通知? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "请输入企业微信群机器人的webhook URL:"
        echo "格式: https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=YOUR_KEY"
        read -p "Webhook URL: " WEBHOOK_URL
        
        if [ -n "$WEBHOOK_URL" ]; then
            log_success "企业微信通知已配置"
        else
            log_warning "未配置企业微信通知"
        fi
    else
        log_info "跳过企业微信通知配置"
    fi
    
    # 使用默认工作流
    SELECTED_WORKFLOW="$DEFAULT_WORKFLOW"
}



# 简化部署模式选择
smart_deployment_mode() {
    echo ""
    echo -e "${CYAN}========================================"
    echo "  部署模式选择"
    echo "========================================${NC}"
    echo ""
    echo "1. 快速部署 - 使用默认配置（1个Pod，无通知）"
    echo "2. 自定义部署 - 配置Pod数量和企业微信通知"
    echo "3. 完全交互 - 详细配置所有参数"
    echo ""
    
    while true; do
        read -p "请选择部署模式 (1-3): " mode_choice
        
        case $mode_choice in
            1)
                log_info "选择快速部署模式"
                SELECTED_WORKFLOW="$DEFAULT_WORKFLOW"
                AUTO_START_TEST=true
                break
                ;;
            2)
                log_info "选择自定义部署模式"
                simple_config
                AUTO_START_TEST=true
                break
                ;;
            3)
                log_info "选择完全交互模式"
                interactive_config
                return 0
                ;;
            *)
                log_error "无效选择，请输入 1-3"
                ;;
        esac
    done
}

# 解析参数
parse_args() {
    ITERATIONS=$DEFAULT_ITERATIONS
    REPLICAS=$DEFAULT_REPLICAS
    WEBHOOK_URL=""
    CLUSTER_ID="tke-cluster"
    POD_IMAGE=$DEFAULT_IMAGE
    CPU_REQUEST=$DEFAULT_CPU_REQUEST
    MEMORY_REQUEST=$DEFAULT_MEMORY_REQUEST
    CPU_LIMIT=$DEFAULT_CPU_LIMIT
    MEMORY_LIMIT=$DEFAULT_MEMORY_LIMIT
    DELAY=$DEFAULT_DELAY
    QUICK_MODE=false
    INTERACTIVE_MODE=false
    SKIP_TEST=false
    FORCE_REDEPLOY=false
    SELECTED_WORKFLOW=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -i|--iterations)
                ITERATIONS="$2"
                shift 2
                ;;
            -r|--replicas)
                REPLICAS="$2"
                shift 2
                ;;
            -w|--webhook)
                WEBHOOK_URL="$2"
                shift 2
                ;;
            -c|--cluster-id)
                CLUSTER_ID="$2"
                shift 2
                ;;
            -n|--namespace)
                NAMESPACE="$2"
                shift 2
                ;;
            --image)
                POD_IMAGE="$2"
                shift 2
                ;;
            --cpu-request)
                CPU_REQUEST="$2"
                shift 2
                ;;
            --memory-request)
                MEMORY_REQUEST="$2"
                shift 2
                ;;
            --cpu-limit)
                CPU_LIMIT="$2"
                shift 2
                ;;
            --memory-limit)
                MEMORY_LIMIT="$2"
                shift 2
                ;;
            --delay)
                DELAY="$2"
                shift 2
                ;;
            -q|--quick)
                QUICK_MODE=true
                shift
                ;;
            --interactive)
                INTERACTIVE_MODE=true
                shift
                ;;
            --force-redeploy)
                FORCE_REDEPLOY=true
                shift
                ;;
            --workflow)
                SELECTED_WORKFLOW="$2"
                shift 2
                ;;
            --skip-test)
                SKIP_TEST=true
                AUTO_START_TEST=false
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
    
    # 验证参数
    validate_parameters
}

# 验证参数
validate_parameters() {
    # 验证迭代次数
    if [[ ! "$ITERATIONS" =~ ^[1-9][0-9]?$ ]] || [ "$ITERATIONS" -gt 20 ]; then
        log_error "迭代次数必须在1-20之间"
        exit 1
    fi
    
    # 验证副本数
    if [[ ! "$REPLICAS" =~ ^[1-9][0-9]*$ ]] || [ "$REPLICAS" -lt 1 ]; then
        log_error "副本数必须大于0"
        exit 1
    fi
    
    # 验证资源格式
    if ! [[ "$CPU_REQUEST" =~ ^[0-9]+m?$ ]] && ! [[ "$CPU_REQUEST" =~ ^[0-9]*\.?[0-9]+$ ]]; then
        log_error "CPU请求格式错误，例如: 100m, 0.1, 1"
        exit 1
    fi
    
    if ! [[ "$MEMORY_REQUEST" =~ ^[0-9]+[KMG]i?$ ]]; then
        log_error "内存请求格式错误，例如: 128Mi, 1Gi"
        exit 1
    fi
}

# 交互式配置
interactive_config() {
    echo ""
    echo -e "${CYAN}========================================"
    echo "  交互式配置向导"
    echo "========================================${NC}"
    echo ""
    
    # 集群ID配置
    echo -e "${BLUE}1. 集群配置${NC}"
    read -p "集群ID (默认: $CLUSTER_ID): " input
    [ -n "$input" ] && CLUSTER_ID="$input"
    
    read -p "命名空间 (默认: $NAMESPACE): " input
    [ -n "$input" ] && NAMESPACE="$input"
    
    echo ""
    
    # 测试配置
    echo -e "${BLUE}2. 测试配置${NC}"
    while true; do
        read -p "测试迭代次数 (1-20, 默认: $ITERATIONS, 推荐1次): " input
        if [ -z "$input" ]; then
            break
        elif [[ "$input" =~ ^[1-9][0-9]?$ ]] && [ "$input" -le 20 ]; then
            ITERATIONS="$input"
            break
        else
            echo -e "${RED}请输入1-20之间的数字${NC}"
        fi
    done
    
    while true; do
        read -p "Deployment副本数 (默认: $REPLICAS): " input
        if [ -z "$input" ]; then
            break
        elif [[ "$input" =~ ^[1-9][0-9]*$ ]] && [ "$input" -ge 1 ]; then
            REPLICAS="$input"
            break
        else
            echo -e "${RED}请输入大于0的正整数${NC}"
        fi
    done
    
    read -p "测试间隔时间 (默认: $DELAY): " input
    [ -n "$input" ] && DELAY="$input"
    
    echo ""
    
    # Pod配置
    echo -e "${BLUE}3. Pod配置${NC}"
    read -p "Pod镜像 (默认: $POD_IMAGE): " input
    [ -n "$input" ] && POD_IMAGE="$input"
    
    echo ""
    echo -e "${BLUE}4. 资源配置${NC}"
    echo "当前配置: CPU请求=$CPU_REQUEST, 内存请求=$MEMORY_REQUEST"
    echo "          CPU限制=$CPU_LIMIT, 内存限制=$MEMORY_LIMIT"
    echo ""
    
    read -p "是否修改资源配置? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "CPU请求 (默认: $CPU_REQUEST): " input
        [ -n "$input" ] && CPU_REQUEST="$input"
        
        read -p "内存请求 (默认: $MEMORY_REQUEST): " input
        [ -n "$input" ] && MEMORY_REQUEST="$input"
        
        read -p "CPU限制 (默认: $CPU_LIMIT): " input
        [ -n "$input" ] && CPU_LIMIT="$input"
        
        read -p "内存限制 (默认: $MEMORY_LIMIT): " input
        [ -n "$input" ] && MEMORY_LIMIT="$input"
    fi
    
    echo ""
    
    # 企业微信通知配置
    echo -e "${BLUE}5. 企业微信通知配置${NC}"
    read -p "是否配置企业微信通知? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "请输入企业微信群机器人的webhook URL:"
        echo "格式: https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=YOUR_KEY"
        read -p "Webhook URL: " WEBHOOK_URL
        
        if [ -n "$WEBHOOK_URL" ]; then
            echo -e "${GREEN}✅ 企业微信通知已配置${NC}"
        else
            echo -e "${YELLOW}⚠️ 未配置企业微信通知${NC}"
        fi
    else
        echo -e "${YELLOW}📝 跳过企业微信通知配置${NC}"
    fi
    
    echo ""
    
    # 显示最终配置
    echo -e "${CYAN}========================================"
    echo "  配置确认"
    echo "========================================${NC}"
    echo "集群ID: $CLUSTER_ID"
    echo "命名空间: $NAMESPACE"
    echo "测试迭代: $ITERATIONS 次"
    echo "副本数: $REPLICAS 个"
    echo "Pod镜像: $POD_IMAGE"
    echo "资源配置: CPU=$CPU_REQUEST/$CPU_LIMIT, 内存=$MEMORY_REQUEST/$MEMORY_LIMIT"
    echo "测试间隔: $DELAY"
    [ -n "$WEBHOOK_URL" ] && echo "企业微信通知: 已配置" || echo "企业微信通知: 未配置"
    echo ""
    
    read -p "确认以上配置并开始部署? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "取消部署"
        exit 0
    fi
}

# 检查环境
check_environment() {
    log_info "检查环境..."
    
    # 检查kubectl
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl未安装，请先安装kubectl"
        exit 1
    fi
    
    # 检查集群连接
    if ! kubectl cluster-info &> /dev/null; then
        log_error "无法连接到Kubernetes集群"
        exit 1
    fi
    
    log_success "环境检查通过"
}

# 创建命名空间
create_namespace() {
    log_info "创建命名空间: $NAMESPACE"
    
    if kubectl get namespace "$NAMESPACE" &> /dev/null; then
        log_warning "命名空间已存在"
    else
        kubectl create namespace "$NAMESPACE"
        log_success "命名空间创建成功"
    fi
}

# 部署RBAC
deploy_rbac() {
    log_info "部署RBAC权限..."
    kubectl apply -f playbook/rbac.yaml
    log_success "RBAC部署完成"
}

# 检查并安装Argo Workflows
install_argo() {
    log_info "检查Argo Workflows..."
    
    if kubectl get deployment tke-chaos-argo-workflows-workflow-controller -n "$NAMESPACE" &> /dev/null; then
        log_success "Argo Workflows已安装"
    else
        log_info "安装Argo Workflows..."
        kubectl apply -f playbook/install-argo.yaml
        log_success "Argo Workflows安装完成"
    fi
}

# 智能部署模板
deploy_templates() {
    log_info "智能部署工作流模板..."
    
    local templates=(
        "kubectl-cmd:playbook/template/kubectl-cmd-template.yaml"
        "supernode-sandbox-deployment-template:playbook/template/supernode-sandbox-deployment-template.yaml"
        "sandbox-wechat-notify-template:playbook/template/sandbox-wechat-notify-template.yaml"
    )
    
    for template_info in "${templates[@]}"; do
        local template_name=$(echo "$template_info" | cut -d: -f1)
        local template_file=$(echo "$template_info" | cut -d: -f2)
        
        if [ ! -f "$template_file" ]; then
            log_error "模板文件不存在: $template_file"
            exit 1
        fi
        
        # 自动重新部署模板
        if check_template_exists "$template_name"; then
            log_info "检测到现有模板 $template_name，自动重新部署"
            delete_existing_template "$template_name"
            
            # 等待删除完成
            local wait_count=0
            while check_template_exists "$template_name" && [ $wait_count -lt 30 ]; do
                sleep 1
                wait_count=$((wait_count + 1))
            done
            
            if check_template_exists "$template_name"; then
                log_warning "模板删除超时，但继续部署"
            fi
        fi
        
        # 部署新模板
        log_info "部署模板: $(basename "$template_file")"
        if kubectl apply -f "$template_file"; then
            # 验证模板是否成功创建
            local verify_count=0
            while ! check_template_exists "$template_name" && [ $verify_count -lt 10 ]; do
                sleep 1
                verify_count=$((verify_count + 1))
            done
            
            if check_template_exists "$template_name"; then
                log_success "模板部署成功: $template_name"
            else
                log_error "模板部署验证失败: $template_name"
                return 1
            fi
        else
            log_error "模板部署失败: $template_name"
            return 1
        fi
    done
}

# 创建前置资源
create_precheck_resources() {
    log_info "创建前置检查资源..."
    
    if kubectl get configmap tke-chaos-precheck-resource -n "$NAMESPACE" &> /dev/null; then
        log_warning "前置资源已存在"
    else
        kubectl create -n "$NAMESPACE" configmap tke-chaos-precheck-resource --from-literal=empty=""
        log_success "前置资源创建完成"
    fi
}

# 启动测试
start_test() {
    if [ "$AUTO_START_TEST" = false ] || [ "$SKIP_TEST" = true ]; then
        log_info "跳过测试启动"
        return
    fi
    
    # 清理现有工作流
    delete_existing_workflows
    
    log_info "启动沙箱复用测试..."
    
    # 确定要使用的工作流文件
    local workflow_source=""
    if [ -n "$SELECTED_WORKFLOW" ]; then
        # 检查是否是examples中的文件
        if [ -f "examples/$SELECTED_WORKFLOW" ]; then
            workflow_source="examples/$SELECTED_WORKFLOW"
        elif [ -f "playbook/workflow/$SELECTED_WORKFLOW" ]; then
            workflow_source="playbook/workflow/$SELECTED_WORKFLOW"
        elif [ -f "$SELECTED_WORKFLOW" ]; then
            workflow_source="$SELECTED_WORKFLOW"
        else
            log_error "找不到工作流文件: $SELECTED_WORKFLOW"
            exit 1
        fi
        
        log_info "使用工作流文件: $workflow_source"
        
        # 如果需要自定义参数，创建临时工作流文件
        if [ "$REPLICAS" != "1" ] || [ -n "$WEBHOOK_URL" ] || [ "$CLUSTER_ID" != "tke-cluster" ]; then
            log_info "应用自定义配置..."
            local temp_workflow="/tmp/custom-workflow-$$.yaml"
            
            # 复制原始工作流并修改参数
            cp "$workflow_source" "$temp_workflow"
            
            # 使用更精确的sed替换参数值
            echo "[DEBUG] 开始参数替换..."
            echo "[DEBUG] REPLICAS=$REPLICAS, WEBHOOK_URL=$WEBHOOK_URL, CLUSTER_ID=$CLUSTER_ID"
            
            # 替换副本数 - 更精确的匹配
            sed -i.bak "/- name: replicas/,/value:/ s/value: \"[0-9]*\"/value: \"$REPLICAS\"/" "$temp_workflow" 2>/dev/null || true
            
            # 替换webhook URL
            if [ -n "$WEBHOOK_URL" ]; then
                sed -i.bak "/- name: webhook-url/,/value:/ s|value: \".*\"|value: \"$WEBHOOK_URL\"|" "$temp_workflow" 2>/dev/null || true
            fi
            
            # 替换集群ID
            if [ "$CLUSTER_ID" != "tke-cluster" ]; then
                sed -i.bak "/- name: cluster-id/,/value:/ s/value: \".*\"/value: \"$CLUSTER_ID\"/" "$temp_workflow" 2>/dev/null || true
            fi
            
            # 验证替换结果
            echo "[DEBUG] 参数替换后的关键配置:"
            grep -A1 "name: replicas" "$temp_workflow" || echo "未找到replicas配置"
            grep -A1 "name: webhook-url" "$temp_workflow" || echo "未找到webhook-url配置"
            
            kubectl create -f "$temp_workflow"
            rm -f "$temp_workflow" "$temp_workflow.bak" 2>/dev/null || true
        else
            kubectl create -f "$workflow_source"
        fi
        
        log_success "测试工作流已启动"
        return
    fi
    
    # 如果没有选择工作流，创建默认工作流
    log_info "创建默认测试工作流..."
    
    # 创建Deployment测试工作流
    local workflow_file="/tmp/sandbox-deployment-test-$$.yaml"
    cat > "$workflow_file" << EOF
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: sandbox-deployment-test-
  namespace: $NAMESPACE
spec:
  serviceAccountName: tke-chaos
  entrypoint: deployment-sandbox-test
  arguments:
    parameters:
    - name: cluster-id
      value: "$CLUSTER_ID"
    - name: webhook-url
      value: "$WEBHOOK_URL"
    - name: kubeconfig-secret-name
      value: ""
    - name: namespace
      value: "$NAMESPACE"
    - name: deployment-name-prefix
      value: "sandbox-deployment-test"
    - name: replicas
      value: "$REPLICAS"
    - name: pod-image
      value: "$POD_IMAGE"
    - name: cpu-request
      value: "$CPU_REQUEST"
    - name: memory-request
      value: "$MEMORY_REQUEST"
    - name: cpu-limit
      value: "$CPU_LIMIT"
    - name: memory-limit
      value: "$MEMORY_LIMIT"
    - name: test-iterations
      value: "$ITERATIONS"
    - name: delay-between-tests
      value: "$DELAY"
  workflowTemplateRef:
    name: supernode-sandbox-deployment-template
    clusterScope: true
EOF
    
    kubectl create -f "$workflow_file"
    rm -f "$workflow_file"
    
    log_success "默认测试工作流已启动"
}

# 显示部署结果
show_result() {
    echo ""
    echo -e "${GREEN}========================================"
    echo "🎉 部署完成！"
    echo "========================================${NC}"
    echo "📋 部署摘要:"
    echo "  命名空间: $NAMESPACE"
    echo "  集群ID: $CLUSTER_ID"
    echo "  Pod副本数: $REPLICAS 个"
    echo "  Pod镜像: $POD_IMAGE"
    echo "  资源配置: CPU=$CPU_REQUEST/$CPU_LIMIT, 内存=$MEMORY_REQUEST/$MEMORY_LIMIT"
    echo "  测试间隔: $DELAY"
    [ -n "$WEBHOOK_URL" ] && echo "  企业微信通知: ✅ 已配置" || echo "  企业微信通知: ❌ 未配置"
    [ -n "$SELECTED_WORKFLOW" ] && echo "  使用工作流: $SELECTED_WORKFLOW" || echo "  使用工作流: 默认工作流"
    echo ""
    
    echo "🚀 手动启动测试:"
    echo "  精确沙箱复用测试: kubectl apply -f examples/sandbox-reuse-precise-test.yaml"
    echo ""
    
    echo "📊 监控命令:"
    echo "  查看工作流: kubectl get workflows -n $NAMESPACE"
    echo "  实时监控: kubectl get workflows -n $NAMESPACE -w"
    echo "  查看Pod: kubectl get pods -n $NAMESPACE"
    echo "  查看日志: kubectl logs -l workflows.argoproj.io/workflow -n $NAMESPACE -f"
    echo ""
    
    echo "🧹 清理命令:"
    echo "  快速清理: ./scripts/cleanup.sh quick"
    echo "  完全清理: ./scripts/cleanup.sh full"
    echo ""
    
    if [ "$AUTO_START_TEST" = true ] && [ "$SKIP_TEST" = false ]; then
        echo -e "${YELLOW}⚡ 测试已自动启动！${NC}"
        echo "监控测试进度:"
        echo "  kubectl get workflows -n $NAMESPACE -w"
        echo ""
        echo "查看实时日志:"
        echo "  kubectl logs -l workflows.argoproj.io/workflow -n $NAMESPACE -f"
    elif [ "$SKIP_TEST" = true ]; then
        echo -e "${BLUE}📦 仅部署模式完成${NC}"
        echo "手动启动测试请选择上述测试选项之一"
    fi
}

# 主函数
main() {
    echo "========================================"
    echo "  TKE Chaos Playbook 增强版部署工具"
    echo "  (智能沙箱复用测试平台)"
    echo "========================================"
    
    parse_args "$@"
    check_environment
    
    # 根据模式选择配置方式
    if [ "$INTERACTIVE_MODE" = true ]; then
        interactive_config
    elif [ "$QUICK_MODE" = true ]; then
        log_info "快速部署模式"
        SELECTED_WORKFLOW="$DEFAULT_WORKFLOW"
        AUTO_START_TEST=true
    elif [ -z "$SELECTED_WORKFLOW" ] && [ "$SKIP_TEST" = false ]; then
        # 如果没有指定工作流且不跳过测试，进入智能部署模式
        smart_deployment_mode
    fi
    
    # 显示配置摘要（除非是快速模式）
    if [ "$QUICK_MODE" = false ]; then
        echo ""
        echo -e "${CYAN}========================================"
        echo "  部署配置摘要"
        echo "========================================${NC}"
        echo "  命名空间: $NAMESPACE"
        echo "  集群ID: $CLUSTER_ID"
        echo "  Pod副本数: $REPLICAS 个"
        echo "  Pod镜像: $POD_IMAGE"
        echo "  资源配置: CPU=$CPU_REQUEST/$CPU_LIMIT, 内存=$MEMORY_REQUEST/$MEMORY_LIMIT"
        echo "  测试间隔: $DELAY"
        [ -n "$WEBHOOK_URL" ] && echo "  企业微信通知: 已配置" || echo "  企业微信通知: 未配置"
        [ -n "$SELECTED_WORKFLOW" ] && echo "  选择工作流: $SELECTED_WORKFLOW" || echo "  工作流: 默认工作流"
        [ "$FORCE_REDEPLOY" = true ] && echo "  部署模式: 强制重新部署" || echo "  部署模式: 智能部署"
        echo ""
        
        if [ "$INTERACTIVE_MODE" = false ]; then
            read -p "确认以上配置并开始部署? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_info "取消部署"
                exit 0
            fi
        fi
    fi
    
    create_namespace
    deploy_rbac
    install_argo
    
    # 部署模板（关键步骤，添加错误处理）
    if ! deploy_templates; then
        log_error "模板部署失败，请检查错误信息"
        exit 1
    fi
    
    create_precheck_resources
    start_test
    
    show_result
}

# 执行主函数
main "$@"