# 简化版部署脚本使用指南

## 🎯 简化改进

根据用户反馈，脚本已简化为：

1. **✅ 移除Pod数量限制** - 现在支持任意数量的Pod副本
2. **✅ 自动重新部署模板** - 无需手动确认，自动检测并重新部署
3. **✅ 简化工作流选择** - 只使用一个优化的工作流
4. **✅ 核心配置选项** - 只保留Pod数量和企业微信通知配置

## 🚀 使用方法

### 1. 智能部署模式（推荐）
```bash
./scripts/deploy-all.sh
```

将显示三种选择：
- **快速部署** - 使用默认配置（1个Pod，无通知）
- **自定义部署** - 配置Pod数量和企业微信通知
- **完全交互** - 详细配置所有参数

### 2. 快速部署
```bash
# 使用默认配置快速部署
./scripts/deploy-all.sh -q

# 指定Pod数量快速部署
./scripts/deploy-all.sh -q -r 20
```

### 3. 命令行配置
```bash
# 指定Pod数量和企业微信通知
./scripts/deploy-all.sh -r 50 -w "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=YOUR_KEY"

# 大规模测试
./scripts/deploy-all.sh -r 100 -w "YOUR_WEBHOOK"
```

### 4. 仅部署模板
```bash
# 只部署模板，不启动测试
./scripts/deploy-all.sh --skip-test
```

## 📋 核心特性

### ✅ 无Pod数量限制
- 支持任意数量的Pod副本
- 适合大规模性能测试
- 自动验证输入有效性

### ✅ 自动模板管理
- 自动检测现有模板
- 自动重新部署更新
- 无需手动确认

### ✅ 简化配置流程
- 只保留核心配置选项
- Pod数量配置
- 企业微信通知配置

### ✅ 统一工作流
- 使用优化的精确沙箱复用测试工作流
- 支持任意Pod数量
- 自动参数配置

## 🎨 使用示例

### 示例1：小规模测试
```bash
# 5个Pod的测试
./scripts/deploy-all.sh -r 5
```

### 示例2：中等规模测试
```bash
# 20个Pod + 企业微信通知
./scripts/deploy-all.sh -r 20 -w "YOUR_WEBHOOK_URL"
```

### 示例3：大规模性能测试
```bash
# 100个Pod的大规模测试
./scripts/deploy-all.sh -r 100 -w "YOUR_WEBHOOK_URL"
```

### 示例4：交互式配置
```bash
# 启动交互式配置
./scripts/deploy-all.sh

# 选择模式2：自定义部署
# 配置Pod数量：50
# 配置企业微信通知：是
```

## 📊 配置流程

### 自定义部署模式流程：
```
1. 启动脚本
   ↓
2. 选择"自定义部署"
   ↓
3. 配置Pod数量（支持任意数量）
   ↓
4. 配置企业微信通知（可选）
   ↓
5. 自动部署模板
   ↓
6. 启动测试
```

## 🎯 测试输出示例

```bash
========================================
  TKE Chaos Playbook 增强版部署工具
  (智能沙箱复用测试平台)
========================================

======================================== 
  部署模式选择
========================================
1. 快速部署 - 使用默认配置（1个Pod，无通知）
2. 自定义部署 - 配置Pod数量和企业微信通知
3. 完全交互 - 详细配置所有参数

请选择部署模式 (1-3): 2

======================================== 
  测试配置
========================================

1. Pod数量配置
当前配置: 1 个Pod副本

是否修改Pod数量? (y/N): y
请输入Pod副本数: 50
✅ Pod副本数设置为: 50

2. 企业微信通知配置
是否配置企业微信通知? (y/N): y
请输入企业微信群机器人的webhook URL:
格式: https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=YOUR_KEY
Webhook URL: https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=abc123
✅ 企业微信通知已配置

========================================
  部署配置摘要
========================================
  命名空间: tke-chaos-test
  集群ID: tke-cluster
  Pod副本数: 50 个
  Pod镜像: nginx:alpine
  资源配置: CPU=100m/200m, 内存=128Mi/256Mi
  测试间隔: 20s
  企业微信通知: ✅ 已配置
  选择工作流: sandbox-reuse-precise-test.yaml
  部署模式: 智能部署

确认以上配置并开始部署? (y/N): y
```

## 🔧 技术改进

### 1. Pod数量验证
```bash
# 新的验证逻辑
if [[ "$new_replicas" =~ ^[1-9][0-9]*$ ]] && [ "$new_replicas" -ge 1 ]; then
    REPLICAS="$new_replicas"
    log_success "Pod副本数设置为: $REPLICAS"
    break
else
    log_error "请输入大于0的正整数"
fi
```

### 2. 自动模板部署
```bash
# 自动重新部署逻辑
if check_template_exists "$template_name"; then
    log_info "检测到现有模板 $template_name，自动重新部署"
    delete_existing_template "$template_name"
fi
```

### 3. 简化配置函数
```bash
# 只保留核心配置
simple_config() {
    # Pod数量配置
    # 企业微信通知配置
    # 使用默认工作流
}
```

## 📈 优势总结

1. **✅ 更灵活** - 支持任意Pod数量，适合各种规模测试
2. **✅ 更简单** - 自动化模板管理，减少用户操作
3. **✅ 更专注** - 只保留核心配置，避免选择困难
4. **✅ 更高效** - 统一工作流，优化测试流程

现在脚本更加简洁高效，完全满足您的需求！