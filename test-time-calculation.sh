#!/bin/bash

echo "🧪 測試時間計算修復..."

# 模擬Pod創建時間
POD_CREATE_TIME="2025-08-04T09:44:05Z"
echo "📅 測試Pod創建時間: $POD_CREATE_TIME"

# 記錄Deployment創建開始時間
DEPLOYMENT_START_TIME=$(date +%s%3N)
echo "🔍 Deployment開始時間戳(ms): $DEPLOYMENT_START_TIME"

# 測試不同的時間解析方法
echo ""
echo "🔧 測試時間解析方法:"

# 方法1: date -d
echo "方法1 - date -d:"
POD_CREATE_TS1=$(date -d "$POD_CREATE_TIME" +%s 2>/dev/null || echo "失敗")
echo "  結果: $POD_CREATE_TS1"

# 方法2: gdate -d
echo "方法2 - gdate -d:"
POD_CREATE_TS2=$(gdate -d "$POD_CREATE_TIME" +%s 2>/dev/null || echo "失敗")
echo "  結果: $POD_CREATE_TS2"

# 方法3: Python解析
echo "方法3 - Python解析:"
POD_CREATE_TS3=$(python3 -c "
import datetime
import sys
try:
    dt = datetime.datetime.fromisoformat('$POD_CREATE_TIME'.replace('Z', '+00:00'))
    print(int(dt.timestamp()))
except:
    print('失敗')
" 2>/dev/null || echo "失敗")
echo "  結果: $POD_CREATE_TS3"

# 選擇最佳結果
POD_CREATE_TS=""
if [ "$POD_CREATE_TS1" != "失敗" ] && [ "$POD_CREATE_TS1" != "0" ]; then
    POD_CREATE_TS="$POD_CREATE_TS1"
    echo "✅ 使用date -d方法"
elif [ "$POD_CREATE_TS2" != "失敗" ] && [ "$POD_CREATE_TS2" != "0" ]; then
    POD_CREATE_TS="$POD_CREATE_TS2"
    echo "✅ 使用gdate -d方法"
elif [ "$POD_CREATE_TS3" != "失敗" ] && [ "$POD_CREATE_TS3" != "0" ]; then
    POD_CREATE_TS="$POD_CREATE_TS3"
    echo "✅ 使用Python解析方法"
else
    POD_CREATE_TS="0"
    echo "❌ 所有方法都失敗"
fi

echo ""
echo "📊 時間計算結果:"
echo "  Pod創建時間戳: $POD_CREATE_TS"
if [ "$POD_CREATE_TS" != "0" ] && [ "$POD_CREATE_TS" != "失敗" ]; then
    echo "  Pod創建時間: $(date -d @$POD_CREATE_TS '+%Y-%m-%d %H:%M:%S')"
    
    # 計算時間差
    DEPLOYMENT_START_TS=$(echo "$DEPLOYMENT_START_TIME" | awk '{printf "%.0f", $1/1000}')
    TIME_DIFF=$((POD_CREATE_TS - DEPLOYMENT_START_TS))
    echo "  Deployment開始時間戳: $DEPLOYMENT_START_TS"
    echo "  時間差: ${TIME_DIFF}秒"
    
    if [ $TIME_DIFF -ge 0 ]; then
        echo "✅ 時間計算正確"
    else
        echo "⚠️  時間差為負數，可能需要調整"
    fi
else
    echo "❌ 無法解析Pod創建時間"
fi

echo ""
echo "✅ 時間計算測試完成！" 