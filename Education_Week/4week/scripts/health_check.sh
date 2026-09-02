#!/bin/bash
# scripts/health_check.sh

# 1. 서버 기본 정보 수집
SERVER_NAME=$(hostname)
CURRENT_TIME=$(date "+%Y-%m-%d %H:%M:%S")

# 2. CPU 사용률 계산
CPU_IDLE=$(top -bn2 -d 1 | grep -i "^%cpu" | tail -n 1 | awk -F, '{print $4}' | awk '{print $1}')
if [ -n "$CPU_IDLE" ]; then
    CPU_USAGE=$(awk "BEGIN {printf \"%.2f\", 100 - $CPU_IDLE}")
else
    CPU_USAGE="0.00"
fi

# 3. Memory 사용률 (OS 전체 가용량 기준)
MEM_USAGE=$(free -m | awk 'NR==2{printf "%.2f", $3*100/$2}')

# 4. Disk 사용률 수집 (NetWitness 데이터 파티션)
if df -h | grep -q "/var/netwitness"; then
    HDD_USAGE=$(df -h /var/netwitness | awk 'NR==2{print $5}' | sed 's/%//')
else
    HDD_USAGE=$(df -h / | awk 'NR==2{print $5}' | sed 's/%//')
fi

# 5. 출력
echo "Server: ${SERVER_NAME}"
echo "Time: ${CURRENT_TIME}"
echo "CPU: ${CPU_USAGE}%"
echo "MEM: ${MEM_USAGE}% (OS Total)"
echo "HDD: ${HDD_USAGE}% (/var/netwitness)"