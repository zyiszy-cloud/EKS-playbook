# 增强版部署脚本使用指南

## 🚀 新功能概览

增强版 `deploy-all.sh` 脚本现在支持以下高级功能：

1. **智能模板部署** - 自动检测并重新部署模板
2. **工作流选择** - 从多个预设工作流中选择
3. **Pod数量配置** - 灵活配置Pod副本数
4. **强制重新部署** - 强制重新部署所有组件
5. **智能部署模式** - 三种部署模式可选

## 📋 使用方法

### 1. 快速部署模式
```bash
# 使用默认配置快速部署
./scripts/deploy-all.sh -q

# 快速部署并指定Pod数量
./scripts/deploy-all.sh -q -r 3
```

### 2. 智能部署模式（推荐）
```bash
# 启动智能部署向导
./scripts/deploy-all.sh

# 将显示三种模式选择：
# 1. 快速部署 - 使用默认配置
# 2. 自定义部署 - 选择工作流和Pod数量  
# 3. 完全交互 - 详细配置所有参数
```

### 3. 指定工作流部署
```bash
# 使用指定的工作流文件
./scripts/deploy-all.sh --workflow sandbox-reuse-precise-test.yaml

# 使用examples中的工作流
./scripts/deploy-all.sh --workflow basic-deployment-test.yaml -r 2

# 使用完整路径
./scripts/deploy-all.sh --workflow examples/performance-test.yaml
```

### 4. 强制重新部署
```bash
# 强制重新部署所有模板
./scripts/deploy-all.sh --force-redeploy

# 强制重新部署并指定工作流
./scripts/deploy-all.sh --force-redeploy --workflow performance-test.yaml
```

### 5. 仅部署模式
```bash
# 只部署模板，不启动测试
./scripts/deploy-all.sh --skip-test

# 部署后手动选择测试
kubectl apply -f examples/sandbox-reuse-precise-test.yaml
```

## 🎯 工作流选择

脚本现在支持以下预设工作流：

| 工作流文件 | 描述 | 适用场景 |
|-----------|------|----------|
| `supernode-sandbox-deployment-scenario.yaml` | 标准沙箱复用测试 | 常规测试 |
| `basic-deployment-test.yaml` | 基础测试（轻量级） | 快速验证 |
| `performance-test.yaml` | 性能测试（高配置） | 性能分析 |
| `sandbox-reuse-precise-test.yaml` | 精确沙箱复用测试 | 详细分析 |

## 🔧 高级功能

### 智能模板管理
- 自动检测现有模板
- 提示是否重新部署
- 支持强制重新部署模式

### 工作流管理
- 自动清理现有工作流
- 防止工作流冲突
- 支持参数自定义

### 配置灵活性
- 支持命令行参数
- 支持交互式配置
- 支持智能部署向导

## 📊 使用示例

### 示例1：开发测试
```bash
# 开发环境快速测试
./scripts/deploy-all.sh -q --workflow basic-deployment-test.yaml
```

### 示例2：性能评估
```bash
# 性能测试配置
./scripts/deploy-all.sh \
  --workflow performance-test.yaml \
  -r 3 \
  -w "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=YOUR_KEY"
```

### 示例3：生产环境部署
```bash
# 生产环境完整配置
./scripts/deploy-all.sh \
  --force-redeploy \
  --workflow sandbox-reuse-precise-test.yaml \
  -r 5 \
  -c "prod-cluster" \
  --image "nginx:1.25-alpine" \
  --cpu-limit "1000m" \
  --memory-limit "1Gi"
```

### 示例4：交互式配置
```bash
# 完全交互式配置
./scripts/deploy-all.sh --interactive

# 将引导您完成：
# - 集群配置
# - 测试配置  
# - Pod配置
# - 资源配置
# - 企业微信通知配置
```

## 🎨 智能部署模式详解

### 模式1：快速部署
- 使用默认配置
- 自动选择精确测试工作流
- 立即启动测试
- 适合：快速验证功能

### 模式2：自定义部署
- 配置Pod数量
- 选择测试工作流
- 自定义基础参数
- 适合：日常测试使用

### 模式3：完全交互
- 详细配置所有参数
- 企业微信通知配置
- 资源限制配置
- 适合：生产环境部署

## 🔍 故障排查

### 模板部署失败
```bash
# 强制重新部署所有模板
./scripts/deploy-all.sh --force-redeploy --skip-test

# 检查模板状态
kubectl get clusterworkflowtemplate
```

### 工作流启动失败
```bash
# 检查现有工作流
kubectl get workflows -n tke-chaos-test

# 清理现有工作流
./scripts/cleanup.sh quick

# 重新部署
./scripts/deploy-all.sh --workflow sandbox-reuse-precise-test.yaml
```

### 权限问题
```bash
# 重新部署RBAC
kubectl apply -f playbook/rbac.yaml

# 检查服务账户
kubectl get serviceaccount tke-chaos -n tke-chaos-test
```

## 📈 最佳实践

1. **首次使用**：建议使用智能部署模式熟悉功能
2. **开发测试**：使用快速部署模式提高效率
3. **生产部署**：使用完全交互模式确保配置正确
4. **定期维护**：使用强制重新部署模式更新模板
5. **监控测试**：配置企业微信通知及时获得结果

## 🎯 总结

增强版部署脚本提供了：
- ✅ 更智能的部署流程
- ✅ 更灵活的配置选项
- ✅ 更友好的用户体验
- ✅ 更强大的功能支持

现在您可以根据不同场景选择最适合的部署方式，大大提升了使用效率和体验！