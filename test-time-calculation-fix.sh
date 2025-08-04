#!/bin/bash

echo "🧪 測試修復後的時間計算邏輯..."

# 模擬Deployment開始時間獲取
echo "📅 模擬Deployment開始時間獲取:"
DEPLOYMENT_CREATE_TIMESTAMP=$(date -Iseconds)
DEPLOYMENT_START_SEC=$(date +%s)

echo "  創建時間戳: $DEPLOYMENT_CREATE_TIMESTAMP"
echo "  秒級時間戳: $DEPLOYMENT_START_SEC"

# 獲取毫秒級時間戳（使用多種方法）
DEPLOYMENT_START_TIME=""

# 方法1: 嘗試使用date +%s%3N
if command -v date >/dev/null 2>&1; then
  TEMP_TIME=$(date +%s%3N 2>/dev/null)
  if [[ "$TEMP_TIME" =~ ^[0-9]+$ ]] && [ ${#TEMP_TIME} -gt 10 ]; then
    DEPLOYMENT_START_TIME="$TEMP_TIME"
    echo "  方法1成功: $DEPLOYMENT_START_TIME"
  else
    echo "  方法1失敗: $TEMP_TIME"
  fi
fi

# 方法2: 如果方法1失敗，使用Python獲取毫秒級時間戳
if [ -z "$DEPLOYMENT_START_TIME" ]; then
  DEPLOYMENT_START_TIME=$(python3 -c "import time; print(int(time.time() * 1000))" 2>/dev/null || echo "")
  if [ -n "$DEPLOYMENT_START_TIME" ]; then
    echo "  方法2成功: $DEPLOYMENT_START_TIME"
  else
    echo "  方法2失敗"
  fi
fi

# 方法3: 如果Python也失敗，使用秒級時間戳*1000
if [ -z "$DEPLOYMENT_START_TIME" ]; then
  DEPLOYMENT_START_TIME=$((DEPLOYMENT_START_SEC * 1000))
  echo "  方法3使用: $DEPLOYMENT_START_TIME"
fi

echo ""
echo "📊 時間戳獲取結果:"
echo "  秒級時間戳: $DEPLOYMENT_START_SEC"
echo "  毫秒級時間戳: $DEPLOYMENT_START_TIME"

# 模擬Pod創建時間
echo ""
echo "📅 模擬Pod創建時間解析:"
POD_CREATE_TIME="2025-08-04T10:14:43Z"
echo "  Pod創建時間: $POD_CREATE_TIME"

# 使用Python解析Pod創建時間
POD_CREATE_TS=$(python3 -c "import datetime; import sys; dt = datetime.datetime.fromisoformat('$POD_CREATE_TIME'.replace('Z', '+00:00')); print(int(dt.timestamp()))" 2>/dev/null || echo "0")
echo "  Pod創建時間戳: $POD_CREATE_TS"

# 計算時間差
echo ""
echo "⏱️  時間差計算:"
DEPLOYMENT_START_TS=$DEPLOYMENT_START_SEC
TIME_DIFF=$((POD_CREATE_TS - DEPLOYMENT_START_TS))

echo "  Deployment開始時間戳: $DEPLOYMENT_START_TS"
echo "  Pod創建時間戳: $POD_CREATE_TS"
echo "  時間差: ${TIME_DIFF}秒"

if [ $TIME_DIFF -ge 0 ] && [ $TIME_DIFF -lt 100 ]; then
  echo "✅ 時間計算正確！"
else
  echo "❌ 時間計算異常！"
fi

echo ""
echo "🎯 預期結果:"
echo "  時間差應該在0-10秒之間"
echo "  不應該出現1752548181秒這樣的異常值" 