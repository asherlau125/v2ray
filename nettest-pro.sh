#!/bin/bash
# VPS 网络测试脚本 - 带线路识别
# 作者：ChatGPT

echo "===== VPS 网络测试开始 ====="
echo "时间: $(date)"
IP=$(curl -s ifconfig.me)
echo "公网IP: $IP"
echo "ASN 信息:"
whois $IP | egrep "origin|OrgName|descr" | head -n 5
echo "--------------------------------"

# 1. Speedtest 测速
echo "[1] Speedtest 测速"
if ! command -v speedtest >/dev/null 2>&1; then
    apt-get update -y >/dev/null 2>&1
    apt-get install -y speedtest-cli >/dev/null 2>&1
fi
speedtest --simple
echo "--------------------------------"

# 2. Ping 中国常用 DNS
echo "[2] Ping 测试"
for iptest in 223.5.5.5 180.76.76.76 114.114.114.114; do
    echo "Ping $iptest:"
    ping -c 4 $iptest | tail -n 2
    echo ""
done
echo "--------------------------------"

# 3. Traceroute 路由追踪
echo "[3] Traceroute to China DNS"
if ! command -v traceroute >/dev/null 2>&1; then
    apt-get install -y traceroute >/dev/null 2>&1
fi
for iptest in 223.5.5.5 180.76.76.76; do
    echo "Traceroute $iptest:"
    traceroute -m 20 $iptest | head -n 15
    echo ""
done
echo "--------------------------------"

# 4. MTR 测试
echo "[4] MTR 测试"
if ! command -v mtr >/dev/null 2>&1; then
    apt-get install -y mtr-tiny >/dev/null 2>&1
fi
mtr -rwc 10 223.5.5.5
echo "--------------------------------"

# 5. 自动识别线路类型
echo "[5] 自动识别线路类型"
trace_output=$(traceroute -m 20 223.5.5.5)

if echo "$trace_output" | grep -q "59.43"; then
    if echo "$trace_output" | grep -q "AS4809"; then
        echo "✅ 检测到 CN2 GIA 线路（电信高端优化）"
    else
        echo "✅ 检测到 CN2 线路（电信优化）"
    fi
elif echo "$trace_output" | grep -q "AS4134"; then
    echo "⚠️ 普通 163 骨干网（电信普通线路）"
elif echo "$trace_output" | grep -q "AS4837"; then
    echo "⚠️ 联通 4837 普通线路"
elif echo "$trace_output" | grep -qi "CMI\|AS58453"; then
    echo "✅ 检测到 CMI（移动国际优化线路）"
else
    echo "❓ 未识别到常见回国优化线路，可能是普通国际线路"
fi

echo "===== 测试结束 ====="
