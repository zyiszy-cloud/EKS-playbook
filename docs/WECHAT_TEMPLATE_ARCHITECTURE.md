# 企业微信通知模板架构设计

## 🎯 设计目标

基于现有的 `wechat.yaml` 模板设计模式，创建专门用于沙箱复用测试的企业微信通知模板，实现：
1. **模块化设计** - 分离消息生成和发送逻辑
2. **可复用性** - 支持不同测试场景的通知
3. **标准化** - 统一的消息格式和发送方式
4. **错误处理** - 完善的重试机制和错误处理

## 📋 架构分析

### 原始wechat.yaml模板优势
```yaml
# 1. 模块化设计
- generate-message: 生成消息内容
- notify: 发送消息到企微群
- combined-template: 组合生成和发送

# 2. 参数化配置
- 支持多种测试场景参数
- 灵活的消息内容定制

# 3. 错误处理
- HTTP模板with重试策略
- 状态码验证
- 响应内容检查
```

## 🏗️ 新架构设计

### 1. 模板层次结构

```
sandbox-wechat-notify-template.yaml
├── generate-sandbox-test-message-then-notify (组合模板)
│   ├── generate-sandbox-test-notify-message (消息生成)
│   └── notify (消息发送)
├── notify (通用发送模板)
└── simple-notify (简化通知模板)
```

### 2. 核心模板功能

#### A. 消息生成模板 (`generate-sandbox-test-notify-message`)
```yaml
功能: 根据测试阶段和结果生成Markdown格式消息
参数:
  - stage: 测试阶段 (开始/完成/失败)
  - cluster-id: 集群ID
  - test-node: 测试节点
  - pod-replicas: Pod副本数
  - test-status: 测试状态
  - performance-data: 性能分析数据
输出: Markdown格式的通知内容
```

#### B. 通用发送模板 (`notify`)
```yaml
功能: 发送消息到企业微信群
特性:
  - 3次重试机制
  - 指数退避策略
  - HTTP状态码验证
  - 企业微信API响应验证
参数:
  - message: JSON格式消息
  - webhook-url: 企业微信webhook地址
```

#### C. 组合模板 (`generate-sandbox-test-message-then-notify`)
```yaml
功能: 生成消息并发送的完整流程
流程:
  1. 调用消息生成模板
  2. 将生成的消息传递给发送模板
  3. 返回发送结果
```

### 3. 集成方式

#### 主模板集成
```yaml
# 在supernode-sandbox-deployment-template.yaml中
steps:
- - name: send-start-notification
    template: send-wechat-notification
    arguments:
      parameters:
      - name: stage
        value: "开始"
      - name: webhook-url
        value: "{{inputs.parameters.webhook-url}}"
    when: "{{inputs.parameters.webhook-url}} != ''"

- - name: run-deployment-test
    template: run-deployment-test
    # ... 测试逻辑

- - name: send-completion-notification
    template: send-wechat-notification
    arguments:
      parameters:
      - name: stage
        value: "完成"
      - name: test-status
        value: "{{steps.run-deployment-test.outputs.result}}"
      - name: webhook-url
        value: "{{inputs.parameters.webhook-url}}"
    when: "{{inputs.parameters.webhook-url}} != ''"
```

## 📊 消息格式设计

### 1. 测试开始通知
```markdown
### 🚀 超级节点沙箱复用测试开始

**📋 基础信息**
- 集群ID: `cluster-name`
- 测试节点: `node-1`
- Pod副本数: **5个**
- 开始时间: `2025-08-04 10:30:00`

**🚀 测试配置**
- 测试类型: 沙箱复用性能测试
- 测试策略: 基准测试 vs 沙箱复用测试
- 预计耗时: 约2-5分钟

> 📊 测试进行中，请稍候...
```

### 2. 测试完成通知
```markdown
### ✅ 超级节点沙箱复用测试完成

**📋 基础信息**
- 集群ID: `cluster-name`
- 完成时间: `2025-08-04 10:35:00`
- 测试节点: `node-1`
- Pod副本数: **5个**

**📊 测试结果**
- 状态: **全部成功**
- 总测试: **2次**
- 成功: **2次**
- 失败: **0次**
- 平均创建时间: `8秒`

**⚡ 性能分析**
- 首次创建: 12秒
- 沙箱复用: 4秒
- 性能提升: **8秒** (67%)
- 复用效果: 显著

> 📈 详细分析数据请查看工作流日志
```

## 🔧 技术特性

### 1. 错误处理机制
```yaml
retryStrategy:
  limit: "3"                    # 最多重试3次
  retryPolicy: "Always"         # 总是重试
  backoff:
    duration: "5s"              # 初始等待5秒
    factor: 2                   # 指数退避因子
    maxDuration: "1m"           # 最大等待1分钟
```

### 2. 响应验证
```bash
# HTTP状态码检查
if [ "$HTTP_CODE" = "200" ]; then
  # 企业微信API响应检查
  if echo "$RESPONSE_BODY" | grep -q '"errcode":0'; then
    echo "✅ 企业微信通知发送成功"
  else
    echo "⚠️ 企业微信API返回错误"
  fi
fi
```

### 3. 条件执行
```yaml
# 只在配置了webhook时发送通知
when: "{{inputs.parameters.webhook-url}} != ''"
```

## 🚀 使用方法

### 1. 部署模板
```bash
# 部署所有模板（包括新的通知模板）
./scripts/deploy-all.sh --skip-test

# 验证模板部署
kubectl get clusterworkflowtemplate | grep sandbox-wechat-notify-template
```

### 2. 配置webhook
```bash
# 使用企业微信通知
./scripts/deploy-all.sh -r 5 -w "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=YOUR_KEY"
```

### 3. 测试通知功能
```bash
# 使用专门的通知测试示例
kubectl apply -f examples/test-wechat-notification.yaml
```

### 4. 独立使用通知模板
```yaml
# 直接调用通知模板
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: test-notification-
spec:
  entrypoint: send-notification
  templates:
  - name: send-notification
    steps:
    - - name: notify
        templateRef:
          name: sandbox-wechat-notify-template
          template: simple-notify
          clusterScope: true
        arguments:
          parameters:
          - name: title
            value: "测试通知"
          - name: content
            value: "这是一个测试通知消息"
          - name: webhook-url
            value: "YOUR_WEBHOOK_URL"
```

## 📈 优势总结

### 1. 架构优势
- **模块化**: 消息生成和发送分离，便于维护
- **可复用**: 支持多种测试场景和消息类型
- **标准化**: 统一的消息格式和发送机制
- **扩展性**: 易于添加新的消息类型和发送方式

### 2. 功能优势
- **智能消息**: 根据测试阶段和结果自动生成合适的消息
- **性能分析**: 自动计算和展示沙箱复用性能提升
- **错误处理**: 完善的重试机制和错误提示
- **条件执行**: 只在需要时发送通知，避免无效调用

### 3. 运维优势
- **易于调试**: 清晰的日志输出和错误信息
- **灵活配置**: 支持多种参数组合和使用场景
- **监控友好**: 提供详细的执行状态和结果反馈
- **文档完善**: 详细的使用说明和示例

## 🎯 最佳实践

1. **webhook配置**: 确保企业微信webhook地址正确且有效
2. **消息内容**: 根据实际需求调整消息模板内容
3. **错误处理**: 监控通知发送状态，及时处理失败情况
4. **性能优化**: 合理设置重试策略，避免过度重试
5. **安全考虑**: 保护webhook地址，避免泄露到日志中

通过这种模板化的设计，企业微信通知功能变得更加模块化、可维护和可扩展！