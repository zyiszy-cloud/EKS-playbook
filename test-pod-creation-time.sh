#!/bin/bash

# 测试Pod创建时间计算修复效果的脚本

echo "========================================"
echo "  测试Pod创建时间计算修复"
echo "========================================"

# 1. 清理现有资源
echo "1. 清理现有资源..."
./scripts/cleanup.sh quick

# 2. 重新部署模板
echo "2. 重新部署模板..."
./scripts/deploy-all.sh --skip-test

# 3. 运行一个小规模测试（3个Pod）
echo "3. 运行测试（3个Pod）验证时间计算..."
./scripts/deploy-all.sh -r 3 -w "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=ddd60f9a-3044-498d-b44e-9f9e77ad834c"

echo "4. 等待测试完成..."
sleep 15

echo "5. 查看最新的工作流日志..."
kubectl logs -l workflows.argoproj.io/workflow -n tke-chaos-test --tail=200

echo ""
echo "========================================"
echo "  检查要点："
echo "  1. 是否显示Pod创建耗时（沙箱初始化）统计"
echo "  2. 是否显示端到端耗时统计"
echo "  3. 是否显示调度等待耗时统计"
echo "  4. 企业微信通知是否发送成功"
echo "  5. 数值比较是否正常（无unary operator错误）"
echo "========================================"

echo ""
echo "如需查看完整日志，请运行："
echo "kubectl logs -l workflows.argoproj.io/workflow -n tke-chaos-test -f"