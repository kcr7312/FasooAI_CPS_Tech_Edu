#!/usr/bin/env bash

# Week 03 - NetWitness health check
# TODO: 교육생이 직접 구현할 것.
# 최소 출력 항목:
# - server name
# - check time
# - CPU usage
# - Memory usage
# - Disk usage

#ㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡ

# 1. 서버 기본 정보 수집
SERVER_NAME=$(hostname)
CURRENT_TIME=$(date "+%Y-%m-%d %H:%M:%S")

# 2. CPU 사용률 계산 (%)
CPU_IDLE=$(top -bn1 | grep -i "cpu" | awk '{print $8}' | cut -d'%' -f1 | head -n 1)
if [ -n "$CPU_IDLE" ]; then
    CPU_USAGE=$(awk "BEGIN {printf \"%.2f\", 100 - $CPU_IDLE}")
else
    CPU_USAGE="0.00"
fi

# 3. Memory 사용률 계산 (%)
MEM_USAGE=$(free -m | awk 'NR==2{printf "%.2f", $3*100/$2}')

# 4. Disk 사용률 수집 (루트 파티션 기준 %)
HDD_USAGE=$(df -h / | awk 'NR==2{print $5}' | sed 's/%//')

# 5. README 3.3 요구사항 규격 출력
echo "Server: ${SERVER_NAME}"
echo "Time: ${CURRENT_TIME}"
echo "CPU: ${CPU_USAGE}%"
echo "MEM: ${MEM_USAGE}%"
echo "HDD: ${HDD_USAGE}%"
