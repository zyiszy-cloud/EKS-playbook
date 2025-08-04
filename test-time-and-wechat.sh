#!/bin/bash

# 测试时间计算和企业微信通知的脚本

echo "========================================"
echo "  测试时间计算和企业微信通知修复"
echo "========================================"

# 1. 清理现有资源
echo "1. 清理现有资源..."
./scripts/cleanup.sh quick

# 2. 重新部署模板
echo "2. 重新部署模板..."
./scripts/deploy-all.sh --skip-test

# 3. 运行一个简单的测试
echo "3. 运行测试（3个Pod）..."
./scripts/deploy-all.sh -r 3 -w "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=ddd60f9a-3044-498d-b44e-9f9e77ad834c"

echo "4. 等待测试完成..."
sleep 10

echo "5. 查看最新的工作流日志..."
kubectl logs -l workflows.argoproj.io/workflow -n tke-chaos-test --tail=100

echo ""
echo "========================================"
echo "  检查要点："
echo "  1. Pod创建时间是否显示真实的毫秒/秒数"
echo "  2. 企业微信通知是否发送成功"
echo "  3. 平均时间计算是否正确"
echo "========================================"