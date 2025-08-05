#!/bin/bash

# 完整修复验证脚本

echo "========================================"
echo "  完整修复验证测试"
echo "========================================"

echo "🔧 本次修复内容："
echo "1. 修复模板中ITERATIONS变量的双引号问题"
echo "2. 修复一键部署脚本中缺少test-iterations参数替换"
echo "3. 确保所有层级的配置都是2次迭代"
echo ""

# 1. 强制清理所有资源
echo "1. 强制清理所有资源..."
./scripts/cleanup.sh full
kubectl delete clusterworkflowtemplate --all --ignore-not-found=true

# 等待清理完成
sleep 5

# 2. 重新部署模板
echo "2. 重新部署模板..."
./scripts/deploy-all.sh --force-redeploy --skip-test

# 3. 验证模板配置
echo "3. 验证模板配置..."
echo "检查模板中的test-iterations默认值："
kubectl get clusterworkflowtemplate supernode-sandbox-deployment-template -o yaml | grep -A2 -B2 "test-iterations" | head -10

# 4. 测试一键部署脚本的参数替换
echo "4. 测试一键部署脚本的参数替换..."
echo "创建临时测试工作流验证参数替换..."

# 创建临时测试文件
cp examples/sandbox-reuse-precise-test.yaml /tmp/test-param-replacement.yaml

# 模拟脚本的参数替换逻辑
REPLICAS=5
WEBHOOK_URL="https://test-webhook-url"
CLUSTER_ID="test-cluster"
ITERATIONS=2

echo "应用参数替换..."
sed -i.bak "/- name: replicas/,/value:/ s/value: \"[0-9]*\"/value: \"$REPLICAS\"/" /tmp/test-param-replacement.yaml
sed -i.bak "/- name: webhook-url/,/value:/ s|value: \".*\"|value: \"$WEBHOOK_URL\"|" /tmp/test-param-replacement.yaml
sed -i.bak "/- name: cluster-id/,/value:/ s/value: \".*\"/value: \"$CLUSTER_ID\"/" /tmp/test-param-replacement.yaml
sed -i.bak "/- name: test-iterations/,/value:/ s/value: \"[0-9]*\"/value: \"$ITERATIONS\"/" /tmp/test-param-replacement.yaml

echo "验证参数替换结果："
echo "  replicas: $(grep -A1 "name: replicas" /tmp/test-param-replacement.yaml | grep value || echo "未找到")"
echo "  webhook-url: $(grep -A1 "name: webhook-url" /tmp/test-param-replacement.yaml | grep value || echo "未找到")"
echo "  cluster-id: $(grep -A1 "name: cluster-id" /tmp/test-param-replacement.yaml | grep value || echo "未找到")"
echo "  test-iterations: $(grep -A1 "name: test-iterations" /tmp/test-param-replacement.yaml | grep value || echo "未找到")"

# 5. 启动实际测试
echo "5. 启动实际测试..."
kubectl apply -f /tmp/test-param-replacement.yaml

echo "6. 等待测试启动..."
sleep 10

echo "7. 显示工作流状态..."
kubectl get workflows -n tke-chaos-test

echo ""
echo "8. 监控测试进度（重点关注迭代次数）..."
echo "   🔍 关键检查点："
echo "   - 应该显示：测试迭代: 2"
echo "   - 应该显示：第1次测试：基准测试"
echo "   - 应该显示：第2次测试：沙箱复用测试"
echo "   - 企业微信通知应该显示：总测试: 2次"
echo ""

# 监控日志
kubectl logs -l workflows.argoproj.io/workflow -n tke-chaos-test --tail=200 -f &
LOG_PID=$!

echo "9. 等待150秒后停止日志监控..."
sleep 150
kill $LOG_PID 2>/dev/null

echo ""
echo "========================================"
echo "  修复验证结果："
echo "========================================"
echo "如果看到以下内容，说明修复成功："
echo "✅ 测试迭代: 2"
echo "✅ 第1次测试：基准测试（首次创建沙箱）"
echo "✅ 第2次测试：沙箱复用测试"
echo "✅ 企业微信通知显示：总测试: 2次"
echo "✅ 沙箱复用效果分析有实际数据对比"
echo ""
echo "如果仍然显示1次测试，请检查："
echo "1. 模板是否正确重新部署"
echo "2. 参数替换是否生效"
echo "3. 是否有其他缓存问题"
echo ""
echo "查看完整日志："
echo "kubectl logs -l workflows.argoproj.io/workflow -n tke-chaos-test -f"

# 清理测试文件
rm -f /tmp/test-param-replacement.yaml /tmp/test-param-replacement.yaml.bak