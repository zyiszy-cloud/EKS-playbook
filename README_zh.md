# TKE Chaos Playbook

基于Argo Workflows的腾讯云TKE集群混沌工程演练平台，专注于超级节点Pod沙箱复用功能测试。

## 项目简介

TKE Chaos Playbook是腾讯云TKE团队设计的混沌工程平台，用于在Kubernetes集群中进行各种故障注入和性能测试。本项目专门针对超级节点的Pod沙箱复用功能进行测试，验证Pod重建时沙箱复用的效果和性能提升。

## 核心功能

- **超级节点沙箱复用测试**: 测试超级节点上Pod重建时沙箱复用功能的效果
- **批量Pod创建测试**: 同时创建多个Pod，分析沙箱复用率和创建性能
- **企业微信通知**: 支持测试结果通过企业微信群进行通知
- **性能分析**: 自动分析Pod创建时间（沙箱初始化）和端到端时间，包含P50/P95/P99统计
- **沙箱复用率统计**: 分析不同超级节点上的Pod分布和沙箱复用效果
- **自动化测试**: 支持多批次、多Pod的自动化测试流程

## 快速开始

### 1. 一键部署

```bash
# 克隆项目
git clone <repository-url>
cd tke-chaos-playbook

# 交互式部署（推荐）
./scripts/deploy-all.sh

# 快速部署（使用默认配置）
./scripts/deploy-all.sh -q

# 自定义测试迭代次数
./scripts/deploy-all.sh -i 5

# 完整自定义配置
./scripts/deploy-all.sh -i 10 -c 'my-cluster' -w 'https://webhook-url'
```

#### 支持的命令行参数：
- `-i, --iterations NUM`: 设置测试迭代次数 (1-20, 默认: 1)
- `-w, --webhook URL`: 设置企业微信webhook地址
- `-c, --cluster-id ID`: 设置集群ID (默认: tke-cluster)
- `-q, --quick`: 快速模式，使用默认配置并立即启动测试
- `--skip-test`: 只部署组件，不启动测试
- `-h, --help`: 显示帮助信息

脚本会自动完成以下操作：
- 检查kubectl和集群连接
- 创建必要的命名空间
- 部署RBAC权限配置
- 安装Argo Workflows（如果未安装）
- 部署所有工作流模板
- 创建前置检查资源
- 验证部署状态
- 可选择立即启动测试工作流

### 2. 手动部署

```bash
# 1. 创建命名空间
kubectl create namespace tke-chaos-test

# 2. 部署RBAC权限
kubectl apply -f playbook/rbac.yaml

# 3. 安装Argo Workflows (如果未安装)
kubectl apply -f playbook/install-argo.yaml

# 4. 部署模板
kubectl apply -f playbook/template/kubectl-cmd-template.yaml
kubectl apply -f playbook/template/supernode-sandbox-deployment-template.yaml

# 5. 创建前置检查资源
kubectl create -n tke-chaos-test configmap tke-chaos-precheck-resource --from-literal=empty=""
```

### 3. 运行测试

```bash
# 运行超级节点沙箱复用测试（Deployment模式）
kubectl apply -f playbook/workflow/supernode-sandbox-deployment-scenario.yaml

# 查看工作流状态
kubectl get workflow -n tke-chaos-test

# 查看工作流日志
kubectl logs -l workflows.argoproj.io/workflow -n tke-chaos-test -f
```

## 配置说明

### 企业微信通知配置

如需启用企业微信通知，请在工作流文件中配置webhook地址：

```yaml
- name: webhook-url
  value: "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=YOUR_KEY"
```

### 测试参数配置

可以在工作流文件中调整以下测试参数：

- `test-iterations`: 测试迭代次数 (默认: 1)
- `pod-image`: 测试Pod使用的镜像 (默认: nginx:alpine)
- `pod-cpu-request/limit`: Pod CPU资源配置
- `pod-memory-request/limit`: Pod内存资源配置
- `wait-pod-ready-timeout`: 等待Pod就绪超时时间 (默认: 300s)
- `pod-recreation-delay`: Pod重建间隔时间 (默认: 30s)

## 项目结构

```
tke-chaos-playbook/
├── scripts/                                # 脚本工具目录
│   ├── deploy-all.sh                       # 一键部署脚本
│   ├── cleanup.sh                          # 清理脚本
│   ├── test-local-env.sh                   # 环境检查脚本
│   └── test-curl-image.sh                  # 镜像测试脚本
├── README.md                               # 项目说明文档
├── README_zh.md                            # 中文说明文档
├── USAGE.md                                # 使用指南
├── USAGE_SIMPLE.md                         # 简化使用指南
└── playbook/
    ├── rbac.yaml                           # RBAC权限配置
    ├── install-argo.yaml                   # Argo Workflows安装配置
    ├── template/                           # 工作流模板目录
    │   ├── kubectl-cmd-template.yaml       # kubectl命令执行模板
    │   └── supernode-sandbox-deployment-template.yaml  # Deployment测试模板
    └── workflow/                           # 工作流场景目录
        └── supernode-sandbox-deployment-scenario.yaml  # Deployment测试场景
```

## 测试原理

### 沙箱复用机制

超级节点的沙箱复用功能通过以下机制提升Pod启动性能：

1. **沙箱保留**: Pod删除后，沙箱环境可能被保留一段时间
2. **资源匹配**: 新Pod如果资源规格匹配，可以复用已有沙箱
3. **启动加速**: 复用沙箱可以跳过部分初始化步骤，加快启动速度

### 测试方法

1. **基准测试**: 首次创建Pod，记录启动时间作为基准
2. **复用测试**: 删除Pod后立即重建，测试沙箱复用效果
3. **性能对比**: 对比首次启动和后续启动的时间差异
4. **统计分析**: 计算平均启动时间和性能提升百分比

## 监控和调试

### 查看工作流状态

```bash
# 查看所有工作流
kubectl get workflows -n tke-chaos-test

# 查看特定工作流详情
kubectl describe workflow <workflow-name> -n tke-chaos-test

# 实时监控工作流状态
kubectl get workflow <workflow-name> -n tke-chaos-test -w
```

### 查看日志

```bash
# 查看工作流日志
kubectl logs -l workflows.argoproj.io/workflow=<workflow-name> -n tke-chaos-test -f

# 查看特定步骤日志
kubectl logs <pod-name> -n tke-chaos-test
```

### 访问Argo UI

```bash
# 端口转发
kubectl port-forward svc/tke-chaos-argo-workflows-server -n tke-chaos-test 2746:2746

# 访问UI
open https://localhost:2746
```

## 故障排除

### 常见问题

1. **Pod启动失败**
   - 检查超级节点是否可用：`kubectl get nodes -l "node.kubernetes.io/instance-type=eklet"`
   - 验证镜像是否可以拉取
   - 检查资源配额是否充足

2. **工作流执行失败**
   - 检查RBAC权限配置：`kubectl get serviceaccount tke-chaos -n tke-chaos-test`
   - 验证模板是否正确部署：`kubectl get clusterworkflowtemplate`
   - 查看工作流日志获取详细错误信息

3. **企业微信通知失败**
   - 验证webhook地址是否正确
   - 检查网络连接是否正常
   - 确认消息格式是否符合要求

4. **LoadBalancer readiness gate问题**
   - 项目已自动添加腾讯云相关注解禁用LoadBalancer功能
   - 如仍有问题，检查Pod的annotations配置

### 清理资源

使用交互式清理脚本（推荐）：
```bash
./scripts/cleanup.sh
```

或手动清理：
```bash
# 删除工作流
kubectl delete workflow <workflow-name> -n tke-chaos-test

# 删除所有测试资源
kubectl delete namespace tke-chaos-test

# 卸载Argo Workflows (可选)
kubectl delete -f playbook/install-argo.yaml
```

## 贡献指南

欢迎提交Issue和Pull Request来改进项目。

## 许可证

本项目采用MIT许可证，详见LICENSE文件。