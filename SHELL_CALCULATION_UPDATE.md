# Shell内置计算和企业微信通知优化

## 🎯 修改目标

根据用户要求：
1. **移除bc依赖** - 使用内置shell计算
2. **改为秒级精度** - 无需毫秒级精度
3. **完善企业微信通知** - 检查并优化通知功能

## ✅ 主要修改内容

### 1. 移除bc依赖

#### 修改前
```bash
# 安装bc用于浮点数计算
if ! command -v bc &> /dev/null; then
  echo "📦 安装bc计算工具..."
  apt-get update -qq && apt-get install -y bc -qq >/dev/null 2>&1
fi

# 使用bc进行浮点数计算
pod_creation_time=$(echo "$POD_CREATION_END_TIME - $DEPLOYMENT_START_TIME" | bc -l)
pod_creation_time_ms=$(echo "$pod_creation_time * 1000" | bc -l | cut -d. -f1)
```

#### 修改后
```bash
# 使用内置shell计算，无需外部依赖
echo "📊 使用内置shell计算，秒级精度"

# 使用shell内置算术运算
pod_creation_time_sec=$((POD_CREATION_END_TIME - DEPLOYMENT_START_TIME))
```

### 2. 改为秒级精度

#### 时间记录修改
```bash
# 修改前：毫秒精度
DEPLOYMENT_START_TIME=$(date +%s.%3N)
POD_CREATION_END_TIME=$(date +%s.%3N)

# 修改后：秒级精度
DEPLOYMENT_START_TIME=$(date +%s)
POD_CREATION_END_TIME=$(date +%s)
```

#### 显示格式修改
```bash
# 修改前
echo "创建耗时: ${pod_creation_time_ms}ms"
echo "平均Pod创建时间: ${AVG_TIME}ms (不含启动时间)"

# 修改后
echo "创建耗时: ${pod_creation_time_sec}秒"
echo "平均Pod创建时间: ${AVG_TIME}秒 (不含启动时间)"
```

#### 性能分析阈值调整
```bash
# 修改前：毫秒级阈值
if [ $IMPROVEMENT -ge 1000 ]; then  # 1秒以上
  echo "沙箱复用效果显著"
elif [ $IMPROVEMENT -ge 500 ]; then  # 500ms以上
  echo "沙箱复用效果明显"

# 修改后：秒级阈值
if [ $IMPROVEMENT -ge 3 ]; then
  echo "沙箱复用效果显著 (提升超过3秒)"
elif [ $IMPROVEMENT -ge 1 ]; then
  echo "沙箱复用效果明显 (提升超过1秒)"
```

### 3. 完善企业微信通知功能

#### 新增完整的通知逻辑
```bash
# 发送企业微信通知
if [ -n "$WEBHOOK_URL" ] && [ "$WEBHOOK_URL" != "" ]; then
  echo "📨 发送企业微信通知..."
  
  # 构建通知内容
  if [ $FAILED_TESTS -eq 0 ]; then
    STATUS_EMOJI="✅"
    STATUS_TEXT="全部成功"
  else
    STATUS_EMOJI="⚠️"
    STATUS_TEXT="部分失败"
  fi
  
  # 计算性能提升信息
  PERF_INFO=""
  if [ -n "$STARTUP_TIMES" ] && [ $COUNT -eq 2 ]; then
    FIRST_TIME=$(echo $STARTUP_TIMES | awk '{print $1}')
    SECOND_TIME=$(echo $STARTUP_TIMES | awk '{print $2}')
    if [ $FIRST_TIME -gt $SECOND_TIME ]; then
      IMPROVEMENT=$((FIRST_TIME - SECOND_TIME))
      IMPROVEMENT_PERCENT=$(( IMPROVEMENT * 100 / FIRST_TIME ))
      PERF_INFO="性能提升: ${IMPROVEMENT}秒 (${IMPROVEMENT_PERCENT}%)"
    fi
  fi
  
  # 发送Markdown格式通知
  NOTIFICATION_CONTENT="{
    \"msgtype\": \"markdown\",
    \"markdown\": {
      \"content\": \"### ${STATUS_EMOJI} 超级节点沙箱复用测试完成\\n\\n**📋 基础信息**\\n- 集群ID: $CLUSTER_ID\\n- 完成时间: $(date '+%Y-%m-%d %H:%M:%S')\\n- 测试节点: $node_name\\n- Pod副本数: **$REPLICAS个**\\n\\n**📊 测试结果**\\n- 状态: **$STATUS_TEXT**\\n- 总测试: **$TOTAL_TESTS次**\\n- 成功: **$SUCCESSFUL_TESTS次**\\n- 失败: **$FAILED_TESTS次**\\n- 平均创建时间: ${AVG_TIME}秒$PERF_INFO\"
    }
  }"
  
  # 发送通知并检查结果
  if curl -s -X POST "$WEBHOOK_URL" \
    -H "Content-Type: application/json" \
    -d "$NOTIFICATION_CONTENT" > /tmp/webhook_response 2>&1; then
    
    if grep -q '"errcode":0' /tmp/webhook_response 2>/dev/null; then
      echo "✅ 企业微信通知发送成功"
    else
      echo "⚠️ 企业微信通知发送失败"
    fi
  else
    echo "❌ 企业微信通知发送失败，请检查网络连接和webhook地址"
  fi
fi
```

## 🎨 新增功能

### 1. 企业微信通知测试示例
创建了 `examples/test-wechat-notification.yaml` 文件，用于测试企业微信通知功能：

```yaml
- name: webhook-url
  value: "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=YOUR_WEBHOOK_KEY"
- name: replicas
  value: "1"  # 单个Pod快速测试
- name: test-iterations
  value: "1"  # 单次测试
```

### 2. 通知内容优化
- **Markdown格式**：使用企业微信支持的Markdown格式
- **详细信息**：包含集群ID、测试节点、Pod数量等
- **性能分析**：自动计算并显示性能提升情况
- **状态标识**：使用emoji和颜色区分成功/失败状态

### 3. 错误处理增强
- **网络错误处理**：检查curl命令执行结果
- **响应验证**：验证企业微信API响应状态
- **友好提示**：提供清晰的错误信息和建议

## 📊 性能优化效果

### 1. 资源使用优化
- **移除外部依赖**：不再需要安装bc包
- **减少镜像大小**：避免额外的软件包安装
- **提升启动速度**：减少初始化时间

### 2. 计算精度调整
- **秒级精度**：满足实际需求，避免过度精确
- **整数运算**：使用shell内置算术，性能更好
- **简化逻辑**：减少复杂的浮点数处理

### 3. 通知功能完善
- **实时通知**：测试完成后立即发送通知
- **详细报告**：包含完整的测试结果和性能分析
- **错误处理**：优雅处理网络错误和API异常

## 🧪 测试验证

### 1. 基础功能测试
```bash
# 测试基础沙箱复用功能
./scripts/deploy-all.sh -q -r 2

# 测试企业微信通知
kubectl apply -f examples/test-wechat-notification.yaml
```

### 2. 性能测试
```bash
# 大规模Pod测试
./scripts/deploy-all.sh -r 10 -w "YOUR_WEBHOOK_URL"

# 验证计算精度
kubectl logs -l workflows.argoproj.io/workflow -n tke-chaos-test | grep "创建耗时"
```

### 3. 通知测试
```bash
# 修改webhook地址
sed -i 's/YOUR_WEBHOOK_KEY/ACTUAL_KEY/' examples/test-wechat-notification.yaml

# 运行通知测试
kubectl apply -f examples/test-wechat-notification.yaml

# 检查通知发送结果
kubectl logs -l workflows.argoproj.io/workflow -n tke-chaos-test | grep "企业微信"
```

## 🎯 使用建议

### 1. 企业微信配置
```bash
# 获取webhook地址
# 1. 在企业微信群中添加机器人
# 2. 复制webhook地址
# 3. 在部署时配置：
./scripts/deploy-all.sh -w "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=YOUR_KEY"
```

### 2. 性能监控
- 关注秒级的性能提升数据
- 重点分析3秒以上的显著提升
- 监控平均创建时间的变化趋势

### 3. 故障排查
- 检查webhook地址格式是否正确
- 验证网络连接是否正常
- 查看企业微信群是否收到通知

## 📈 总结

通过这次优化：

1. **✅ 简化依赖**：移除bc依赖，使用shell内置计算
2. **✅ 精度适中**：改为秒级精度，满足实际需求
3. **✅ 通知完善**：实现完整的企业微信通知功能
4. **✅ 用户友好**：提供测试示例和详细文档
5. **✅ 错误处理**：增强错误处理和用户提示

现在系统更加轻量、高效，同时提供了完整的通知功能！