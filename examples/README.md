# 示例文件说明

本目录包含了TKE超级节点沙箱复用测试的各种使用示例。

## 📋 重要说明

- **这些是示例文件**：用于展示如何手动配置和启动测试
- **部署脚本不使用这些文件**：`./scripts/deploy-all.sh` 会动态生成工作流配置
- **手动使用**：您可以直接使用这些文件进行测试：`kubectl create -f examples/xxx.yaml`

## 📁 文件列表

### basic-deployment-test.yaml
**基础测试示例**
- 使用轻量级资源配置
- 单次对比测试（基准 vs 沙箱复用）
- 1个Pod副本
- 适合快速验证功能

**使用方法**:
```bash
kubectl apply -f examples/basic-deployment-test.yaml
```

### performance-test.yaml
**性能测试示例**
- 使用高性能资源配置
- 单次对比测试（基准 vs 沙箱复用）
- 3个Pod副本
- 适合性能分析

**使用方法**:
```bash
kubectl apply -f examples/performance-test.yaml
```

### sandbox-reuse-precise-test.yaml
**精确沙箱复用测试示例**
- 精确测量Pod创建时间（不含启动时间）
- 20秒后销毁Pod（严格按需求）
- 单次对比测试（基准测试 vs 沙箱复用测试）
- 支持任意Pod数量配置
- 详细的沙箱复用效果分析

**使用方法**:
```bash
kubectl apply -f examples/sandbox-reuse-precise-test.yaml
```

### rolling-update-test.yaml
**Pod滚动更新沙箱复用测试示例**
- 测试滚动更新过程中的沙箱复用效果
- 多次滚动更新（镜像版本来回切换）
- 5个Pod副本，4次更新迭代
- 分析滚动更新性能和沙箱复用率
- 支持企业微信通知

**使用方法**:
```bash
kubectl apply -f examples/rolling-update-test.yaml
```

### test-wechat-notification.yaml
**企业微信通知测试示例**
- 测试企业微信通知功能
- 轻量级配置，快速验证
- 单个Pod，单次测试
- 验证webhook配置是否正确

**使用方法**:
```bash
# 修改webhook地址后运行
kubectl apply -f examples/test-wechat-notification.yaml
```

## 🚀 快速开始

1. **确保环境已部署**:
   ```bash
   ./scripts/deploy-all.sh --skip-test
   ```

2. **选择合适的示例**:
   - 首次使用：选择 `basic-deployment-test.yaml`
   - 性能分析：选择 `performance-test.yaml`
   - 滚动更新测试：选择 `rolling-update-test.yaml`

3. **运行测试**:
   ```bash
   kubectl apply -f examples/basic-deployment-test.yaml
   ```

4. **监控结果**:
   ```bash
   kubectl get workflows -n tke-chaos-test -w
   ```

## 📊 自定义配置

您可以基于这些示例创建自己的测试配置：

1. **复制示例文件**
2. **修改参数值**（如迭代次数、资源配置等）
3. **应用自定义配置**

## 🔗 相关文档

- [项目README](../README.md)
- [使用指南](../docs/USAGE.md)
- [沙箱复用测试指南](../docs/SANDBOX_REUSE_TEST_GUIDE.md)
- [滚动更新测试指南](../docs/ROLLING_UPDATE_TEST_GUIDE.md)
- [企业微信通知设置](../docs/WECHAT_NOTIFICATION_SETUP.md)