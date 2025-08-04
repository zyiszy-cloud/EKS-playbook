#!/bin/bash

echo "🔍 檢查YAML語法..."

# 檢查supernode-sandbox-deployment-template.yaml
echo "檢查 supernode-sandbox-deployment-template.yaml..."
if grep -q "error converting YAML to JSON" <(kubectl apply --dry-run=client --validate=false -f playbook/template/supernode-sandbox-deployment-template.yaml 2>&1); then
    echo "❌ YAML語法錯誤"
    exit 1
else
    echo "✅ YAML語法正確"
fi

# 檢查sandbox-wechat-notify-template.yaml
echo "檢查 sandbox-wechat-notify-template.yaml..."
if grep -q "error converting YAML to JSON" <(kubectl apply --dry-run=client --validate=false -f playbook/template/sandbox-wechat-notify-template.yaml 2>&1); then
    echo "❌ YAML語法錯誤"
    exit 1
else
    echo "✅ YAML語法正確"
fi

# 檢查wechat.yaml
echo "檢查 wechat.yaml..."
if grep -q "error converting YAML to JSON" <(kubectl apply --dry-run=client --validate=false -f playbook/template/wechat.yaml 2>&1); then
    echo "❌ YAML語法錯誤"
    exit 1
else
    echo "✅ YAML語法正確"
fi

# 檢查kubectl-cmd-template.yaml
echo "檢查 kubectl-cmd-template.yaml..."
if grep -q "error converting YAML to JSON" <(kubectl apply --dry-run=client --validate=false -f playbook/template/kubectl-cmd-template.yaml 2>&1); then
    echo "❌ YAML語法錯誤"
    exit 1
else
    echo "✅ YAML語法正確"
fi

echo ""
echo "�� 所有模板YAML語法檢查完成！" 