# TKE Chaos Playbook

腾讯云容器服务（TKE）超级节点沙箱复用性能测试工具。

## 🎯 项目概述

专门用于测试和验证腾讯云TKE超级节点的沙箱复用机制性能，通过自动化测试流程准确测量Pod启动时间，分析沙箱复用对性能的影响。

## ✨ 核心功能

- **🚀 沙箱复用测试**: 自动化测试沙箱复用机制的性能表现
- **⏱️ 精确时间测量**: 毫秒级精度的Pod创建和沙箱初始化时间测量
- **📊 性能对比分析**: 基准测试与沙箱复用测试的详细对比
- **🔄 滚动更新测试**: 测试Pod滚动更新过程中的沙箱复用效果
- **💬 企业微信通知**: 测试结果自动推送到企业微信群

## 🚀 快速开始

### 前置条件

- Kubernetes集群（推荐TKE）在集群中创建tke-chaos-test/tke-chaos-precheck-resource ConfigMap，该资源用于标识集群可执行演练测试
- kubectl create ns tke-chaos-test && kubectl create -n tke-chaos-test configmap tke-chaos-precheck-resource --from-literal=empty=""
- Argo Workflows已安装
- 
- kubectl命令行工具
- 超级节点已配置

### 30秒快速部署

```bash
# 1. 克隆项目
git clone git@github.com:wi1123/EKS-playbook.git
cd tke-chaos-playbook
# 部署Argo Workflow
kubectl create -f playbook/install-argo.yaml
# 验证Argo Workflow Pod正常运行
kubectl get po -n tke-chaos-test
#腾讯云TKE控制台开启tke-chaos-test/tke-chaos-argo-workflows-server Service公网访问，浏览器访问LoadBalancer IP:2746
# 获取Argo Server UI接入凭证
kubectl exec -it -n tke-chaos-test deployment/tke-chaos-argo-workflows-server -- argo auth token

# 2. 一键部署
./scripts/deploy-all.sh 

# 3. 启动测试
kubectl apply -f examples/basic-deployment-test.yaml

# 4. 查看结果
kubectl get workflows -n tke-chaos-test -w
```

### 核心指标
- **沙箱初始化时间**: 从Pod创建到容器启动的时间（核心指标）
- **沙箱复用率**: 复用沙箱的Pod占比
- **性能提升**: 沙箱复用相对于基准测试的性能提升百分比

### 典型测试结果
```
📊 沙箱复用效果分析:
- 基准测试（首次创建）: 14.000秒
- 沙箱复用测试: 13.400秒
- 沙箱复用覆盖率: 60% (6/10个Pod)
- 性能提升: 4.3%
```

## 🛠️ 配置选项

### 部署参数
```bash
./scripts/deploy-all.sh [选项]
  -n, --namespace NS      指定命名空间 (默认: tke-chaos-test)
  -c, --cluster-id ID     指定集群ID (默认: tke-cluster)
  -r, --replicas NUM      Pod副本数 (默认: 3)
  -i, --image IMG         指定Pod镜像 (默认: nginx:alpine)
  -cpu, --cpu REQ/LIMIT   指定CPU资源 (请求/限制，默认: 100m/200m)
  -mem, --memory REQ/LIMIT 指定内存资源 (请求/限制，默认: 128Mi/256Mi)
  -d, --delay DELAY       指定测试间隔 (默认: 30s)
  -it, --iterations NUM   指定测试迭代次数 (默认: 2)
  -w, --webhook URL       企业微信Webhook URL
  -f, --force             强制重新部署
  -s, --skip-test         跳过测试
  -i, --interactive       交互式配置模式
  -wf, --workflow NAME    指定工作流模板 (可选: supernode-sandbox-deployment-template, supernode-rolling-update-template)
  -l, --log-level LEVEL   设置日志级别 (debug, info, warn, error, 默认: info)
  -h, --help              显示帮助信息
```

### 企业微信通知
配置企业微信webhook URL以接收测试结果通知：

```bash
# 交互式配置（包含微信通知）
./scripts/deploy-all.sh -i

# 或直接指定webhook
./scripts/deploy-all.sh -w "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=YOUR_KEY"

# 指定工作流模板并配置webhook
./scripts/deploy-all.sh -wf supernode-rolling-update-template -w "YOUR_WEBHOOK_URL"
```

详细配置指南请参考 [企业微信通知设置](WECHAT_NOTIFICATION_SETUP.md)

## 🔧 测试场景详解

### 沙箱复用原理
- **沙箱保留**: Pod删除后，底层沙箱环境可能被保留一段时间
- **资源匹配**: 新Pod如果资源规格匹配，可以复用已有沙箱
- **启动加速**: 复用沙箱可以跳过部分初始化步骤，显著减少启动时间

### 滚动更新测试
测试采用两阶段对比方式：
1. **标准滚动更新（基准测试）**: 执行标准Kubernetes滚动更新
2. **沙箱复用测试**: 滚动更新完成后，创建临时Pod测试沙箱复用效果

### 复用判断标准
- **复用成功**: 沙箱初始化时间 < 20.0秒
- **复用效果显著**: 复用率 > 50%
- **复用效果一般**: 复用率 20%-50%

## 🛠️ 故障排除

### 常见问题
1. **Pod创建超时**: 检查超级节点状态和镜像拉取
2. **沙箱复用率为0%**: 检查Pod规格一致性和测试间隔时间
3. **时间测量异常**: 验证kubectl权限和时区设置

### 工具命令
```bash
# 诊断系统问题
./scripts/diagnose.sh

# 清理测试资源
./scripts/cleanup.sh quick

# 查看测试日志
kubectl logs -l workflows.argoproj.io/workflow -n tke-chaos-test
```

## 📚 文档

- [企业微信通知设置](docs/WECHAT_NOTIFICATION_SETUP.md) - 微信通知配置指南

## 🤝 贡献指南

欢迎提交Issue和Pull Request来改进项目。

## 📄 许可证

本项目采用MIT许可证，详见LICENSE文件。
