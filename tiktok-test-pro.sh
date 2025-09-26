
#!/bin/bash
# TikTok 节点可用性自动测试脚本

echo "===== TikTok 节点可用性测试 ====="
echo "时间: $(date)"

IP=$(curl -s ifconfig.me)
echo "VPS 公网 IP: $IP"

echo "检测 ASN 信息..."
if ! command -v whois >/dev/null 2>&1; then
    apt-get update -y >/dev/null 2>&1
    apt-get install -y whois >/dev/null 2>&1
fi
whois $IP | egrep "origin|OrgName|descr" | head -n 5

echo "--------------------------------"

echo "[1] Speedtest 测试"
if ! command -v speedtest >/dev/null 2>&1; then
    apt-get install -y speedtest-cli >/dev/null 2>&1
fi
speedtest --simple

echo "--------------------------------"

echo "[2] Ping 国内关键节点"
PING_SUM=0
PING_COUNT=0
for iptest in 223.5.5.5 180.76.76.76 114.114.114.114; do
    echo "Ping $iptest:"
    ping_result=$(ping -c 4 $iptest | tail -n 2)
    echo "$ping_result"
    avg_ping=$(echo "$ping_result" | awk -F '/' '{print $5}')
    if [[ $avg_ping ]]; then
        PING_SUM=$(echo "$PING_SUM + $avg_ping" | bc)
        PING_COUNT=$((PING_COUNT+1))
    fi
    echo ""
done

AVG_PING=$(echo "scale=2; $PING_SUM / $PING_COUNT" | bc)
echo "平均延迟: $AVG_PING ms"
echo "--------------------------------"

echo "[3] 路由追踪（Traceroute）"
if ! command -v traceroute >/dev/null 2>&1; then
    apt-get install -y traceroute >/dev/null 2>&1
fi
for iptest in 223.5.5.5 180.76.76.76; do
    echo "Traceroute $iptest:"
    traceroute -m 20 $iptest | head -n 15
    echo ""
done

echo "--------------------------------"

echo "[4] TikTok API 延迟模拟"
echo "测试 TikTok API 连接延迟..."
curl -o /dev/null -s -w "延迟: %{time_total} 秒\n" "https://api16-normal-useast5.us.tiktokv.com/passport/login/"

echo "--------------------------------"

echo "[5] 自动结论"
if (( $(echo "$AVG_PING < 50" | bc -l) )); then
    echo "✅ 延迟低，适合做 TikTok 节点"
elif (( $(echo "$AVG_PING < 150" | bc -l) )); then
    echo "⚠️ 延迟中等，可用但可能有卡顿"
else
    echo "❌ 延迟高，不建议做 TikTok 节点"
fi

echo "建议：如果要长期稳定做 TikTok 节点，建议选择 CN2 GIA / CMI / 9929 等优化线路"
echo "===== 测试结束 ====="
