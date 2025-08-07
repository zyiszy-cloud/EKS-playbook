# 企业微信通知配置指南

## 🎯 配置目标

为TKE超级节点沙箱复用测试配置企业微信通知，确保测试结果能够及时发送到指定的微信群。

## � 配置置步骤

### 1. 创建企业微信群机器人

1. 在企业微信群中，点击右上角的"..."
2. 选择"群机器人"
3. 点击"添加机器人"
4. 设置机器人名称（如：TKE测试通知）
5. 复制生成的Webhook URL

**Webhook URL格式**:
```
https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=YOUR_KEY_HERE
```

### 2. 部署时配置通知

#### 方法1: 交互式配置
```bash
# 运行部署脚本
./scripts/deploy-all.sh --interactive

# 在交互过程中输入webhook URL
```

#### 方法2: 命令行参数配置
```bash
# 直接通过参数配置
./scripts/deploy-all.sh -w "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=YOUR_KEY"
```

#### 方法3: 快速部署配置
```bash
# 快速模式配置 (非交互式)
./scripts/deploy-all.sh -wf supernode-sandbox-deployment-template -w "YOUR_WEBHOOK_URL"
```

### 3. 脚本参数说明

部署脚本支持以下与通知相关的参数：
- `-w, --webhook`: 指定企业微信Webhook URL
- `-i, --interactive`: 进入交互式配置模式
- `-wf, --workflow`: 指定工作流模板 (可选: supernode-sandbox-deployment-template, supernode-rolling-update-template)

### 4. 手动配置工作流

如果需要手动配置工作流文件：

```yaml
# 编辑 playbook/workflow/supernode-sandbox-deployment-scenario.yaml
arguments:
  parameters:
  - name: webhook-url
    value: "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=YOUR_KEY"
```

## 📨 通知内容

### 1. 测试开始通知
```json
{
  "msgtype": "text",
  "text": {
    "content": "🚀 超级节点Deployment沙箱复用测试开始\n集群: tke-cluster\n测试次数: 3\n副本数: 1\n开始时间: 2025-08-01 16:00:00"
  }
}
```

### 2. 测试完成通知
```json
{
  "msgtype": "markdown",
  "markdown": {
    "content": "### ✅ 超级节点Deployment沙箱复用测试完成\n\n**📋 基础信息**\n- 集群ID: `tke-cluster`\n- 完成时间: `2025-08-01 16:05:30`\n- 测试迭代: **3次**\n- 副本数: **1个**\n\n**📊 测试结果**\n- 状态: **全部成功**\n- 总测试: **3次**\n- 成功: **3次**\n- 失败: **0次**\n- 平均启动: `12s`\n\n**⚡ 性能分析**\n- 首次启动: `18s`\n- 平均启动: `12s`\n- 性能提升: `6s`\n\n> 📈 详细分析数据请查看工作流日志"
  }
}
```

## 🔍 故障排查

### 1. 通知未发送

**检查webhook URL**:
```bash
# 测试webhook URL是否有效
curl -X POST "YOUR_WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{"msgtype":"text","text":{"content":"测试消息"}}'
```

**预期响应**:
```json
{"errcode":0,"errmsg":"ok"}
```

### 2. 查看通知发送日志

```bash
# 查看工作流日志中的通知部分
kubectl logs -l workflows.argoproj.io/workflow -n tke-chaos-test | grep -A 5 -B 5 "企业微信"
```

**成功日志示例**:
```
📨 发送企业微信通知...
✅ 企业微信通知发送成功
```

**失败日志示例**:
```
📨 发送企业微信通知...
⚠️ 企业微信通知发送失败，状态码: 400
```

### 3. 常见问题

#### 问题1: webhook URL为空
**现象**: 日志显示"📝 未配置企业微信webhook，跳过通知"
**解决**: 确保正确配置了webhook URL

#### 问题2: 网络连接失败
**现象**: 状态码为000或连接超时
**解决**: 检查集群网络连接和防火墙设置

#### 问题3: 消息格式错误
**现象**: 状态码为400
**解决**: 检查JSON格式是否正确

## 🧪 测试验证

### 1. 简单测试
```bash
# 使用curl直接测试
curl -X POST "YOUR_WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{"msgtype":"text","text":{"content":"TKE测试通知配置成功！"}}'
```

### 2. 完整测试
```bash
# 运行完整的测试流程
./scripts/deploy-all.sh -q -w "YOUR_WEBHOOK_URL"

# 监控通知发送
kubectl logs -l workflows.argoproj.io/workflow -n tke-chaos-test -f | grep "企业微信"
```

## 📱 通知效果

### 测试开始通知
![测试开始](https://via.placeholder.com/400x100/4CAF50/FFFFFF?text=🚀+测试开始通知)

### 测试完成通知
![测试完成](https://via.placeholder.com/400x200/2196F3/FFFFFF?text=📊+详细结果报告)

## 🔒 安全建议

1. **webhook URL保护**: 不要在公开代码中暴露webhook URL
2. **访问控制**: 限制机器人的权限范围
3. **消息频率**: 避免过于频繁的通知发送
4. **内容过滤**: 确保通知内容不包含敏感信息

## 📚 相关文档

- [企业微信群机器人开发文档](https://developer.work.weixin.qq.com/document/path/91770)
- [项目使用指南](USAGE.md)
- [故障排查指南](USAGE_SIMPLE.md)

配置完成后，您将能够实时接收到TKE超级节点沙箱复用测试的详细结果通知！