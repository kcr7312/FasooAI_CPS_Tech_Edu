# Week 04 - NetWitness 운영 점검 자동화와 점검 이력 관리

## 1. 과제 개요

본 실습은 NetWitness 서버의 기본 운영 점검을 직접 수행하고, 반복 점검 항목을 스크립트로 자동화한 뒤 MySQL에 점검 이력을 저장하는 것을 목적으로 합니다.

단순히 결과물을 생성하는 것이 아니라 각 점검 항목의 의미, 확인 방법, 자동화 로직, 오류 대응 과정을 스스로 설명할 수 있을 정도로 숙지해야 합니다.

### 대상 서버

| Role | IP |
|---|---|
| HEAD | 192.168.102.7 |
| ESA | 192.168.102.8 |
| Hybrid | 192.168.102.9 |

---

## 2. I. NetWitness 점검 실습

### 2.1 기본 점검 항목

- hostname / IP
- OS / uptime
- CPU 사용률
- Memory 사용률
- Disk 사용률
- 주요 서비스 동작 상태
- 네트워크 상태
- 로그 및 이상 징후

### 2.2 서버별 점검 결과

#### HEAD

| 항목 | 결과 | 확인 명령/방법 | 판단 |
|---|---|---|---|
| Hostname / IP | nwserver / 192.168.102.7 | hostname, ip a | 양호 |
| OS / Uptime | AlmaLinux 8.10 / up 3days, 20:54 | hostnamectl, uptime | 양호 |
| CPU | 4% | GUI (Admin > Health & Wellness > Monitoring) | 양호 |
| Memory | 89% | GUI (Admin > Health & Wellness > Monitoring) | 주의(메모리 사용률 높음) |
| Disk | 8% | df -h(/var/netwitness 부분) | 양호 |
| Service | 12.5.2.0 버전 & 서비스 정상 | GUI (Admin > Hosts, Services) | 양호 |
| Network | 정상 통신 확인 | ping, 웹 접속 상태 확인 | 양호 |
| Log / 이상 징후 | 폐쇄망 통신 타임아웃 | grep -iE "error|warning|critical|fail" /var/log/messages | tail -n 20 | 양호 |

#### ESA

| 항목 | 결과 | 확인 명령/방법 | 판단 |
|---|---|---|---|
| Hostname / IP | esaPrimary / 192.168.102.8 | hostname, ip a | 양호 |
| OS / Uptime | AlmaLinux 8.10 / up 3days, 20:54 | hostnamectl, uptime | 양호 |
| CPU | 2.1% | GUI (Admin > Health & Wellness > Monitoring) | 양호 |
| Memory | 10.6% | GUI (Admin > Health & Wellness > Monitoring) | 양호 |
| Disk | 5% | df -h(/var/netwitness 부분) | 양호 |
| Service | 12.5.2.0 버전 & Incidents / Alerts 서비스 정상 | GUI (Respond > Incidents, Alerts) | 양호 |
| Network | 정상 통신 확인 | GUI 호스트 연결 상태 확인 | 양호 |
| Log / 이상 징후 | 로컬 수집 데몬 타임아웃 | grep -iE "error|warning|critical|fail" /var/log/messages | tail -n 20 | 양호 |

#### Hybrid

| 항목 | 결과 | 확인 명령/방법 | 판단 |
|---|---|---|---|
| Hostname / IP | hybrid / 192.168.102.9 | hostname, ip a | 양호 |
| OS / Uptime | AlmaLinux 8.10 / up 3days, 20:54 | hostnamectl, uptime | 양호 |
| CPU | Concentrator: 5%, Decoder: 4% | GUI (Admin > Services > status) | 양호 |
| Memory | Concentrator: 1%, Decoder: 4% | GUI (Admin > Services > status) | 양호 |
| Disk | 5% | df -h(/var/netwitness 부분) | 양호 |
| Service | 12.5.2.0 버전 & 데이터/패킷 저장 기간 15 Days, 유입량 0.0 Gbps | GUI (Explorer > Database > stats > ~.oldest.file.time 확인) | 양호 |
| Network | 정상 통신 확인 | GUI (Admin > Hosts) | 양호 |
| Log / 이상 징후 | 계정 쿼리 타임아웃 & collectd 통신 에러 | grep -iE "error|warning|critical|fail" /var/log/messages | tail -n 20 | 양호 |

### 2.3 수동 점검 시 사용한 명령어

```bash
# 실제 사용한 명령어를 기록
hostname
hostnamectl
ip a
uptime
free -m
df -h
grep -iE "error|warning|critical|fail" /var/log/messages | tail -n 20
```

### 2.4 점검 결과 종합 판단

- 정상/이상 여부: 정상으로 판단
- 판단 근거: CLI/GUI 모두 정상 작동 & 장비들의 리소스 사용량 양호
- 추가 확인이 필요했던 항목: HEAD의 MEM 사용률(89%) / 하기의 추가 확인을 통해 정상 확인
						1. free -m 결과: available 3111 MB & Swap total 4095 MB 중 used 1263 MB, free 2832 MB
						2. top 결과: CPU id 95.9%, Load Average 0.25
						3. dmesg -T | grep -i "out of memory" 결과: 이력 없음
						4. Java 기반 특성으로 가상 메모리 "예약"이 대부분 차지

---

## 3. II. 점검 자동화

### 3.1 구현 목적

다수 서버의 CPU, Memory, Disk 상태를 동일한 방식으로 수집하여 반복 점검의 효율성과 일관성을 높입니다.

### 3.2 구현 파일

- `scripts/health_check.sh`

### 3.3 실행 결과

```text
[초기 스크립트]
Server: nwserver
Time: 2026-08-31 10:17:13
CPU: 9.50%
MEM: 88.66%
HDD: 29%

Server: esaPrimary
Time: 2026-08-31 10:21:15
CPU: 4.80%
MEM: 10.86%
HDD: 20%

Server: hybrid
Time: 2026-08-31 10:21:19
CPU: 6.40%
MEM: 16.88%
HDD: 19%

ㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡ
[일부 수치 불일치 해결 후]
Server: nwserver
Time: 2026-09-01 10:17:47
CPU: 2.20%
MEM: 87.73% (OS Total)
HDD: 8% (/var/netwitness)

Server: esaPrimary
Time: 2026-09-01 10:17:56
CPU: 0.60%
MEM: 10.91% (OS Total)
HDD: 5% (/var/netwitness)

Server: hybrid
Time: 2026-09-01 10:18:05
CPU: 4.60%
MEM: 17.06% (OS Total)
HDD: 5% (/var/netwitness)
```

실제 실행 결과 또는 캡처 자료는 `evidence/automation/`에 저장합니다.

### 3.4 수동 점검과 자동화 결과 비교

| 항목 | 수동 점검 | 자동 점검 | 일치 여부 | 차이 발생 원인 |
|---|---:|---:|---|---|
| CPU | 4% | 9.5% | 불일치 | GUI에서는 일정 주기의 평균 값 / 자동 점검은 top명령어 사용(실행 순간 결과값)으로 인한 차이 |
| Memory | 89% | 88.66% | 일치 | - |
| Disk | 8% | 29% | 불일치 | df -h를 통해 확인하는 것은 같으나 수동 점검에선 데이터 파티션(/var/netwitness)를 기준 자동 점검에선 OS 구동영역인 루트(/) 파티션 기준으로 파싱했기에 차이 발생 |

### 3.5 구현 중 발생한 오류 및 해결 과정

| 구분 | 내용 |
|---|---|
| 발생 오류 | 타임스탬프 오류 & 수치 불일치 오류 |
| 원인 분석 | OS 타임존이 UTC로 설정되어 있어, KST와 9시간 차이 발생 / 수동 점검에선 데이터 파티션(/var/netwitness)를 기준 자동 점검에선 OS 구동영역인 루트(/) 파티션 기준으로 파싱했기에 차이 발생 |
| 해결 방법 | timedatectl set-timezone Asia/Seoul 명령어 통해 타임존 변경 / 디스크 조회 로직에 조건문을 추가하여, /var/netwitness 마운트 경로가 존재할 경우 해당 파티션의 사용률을 우선적으로 추출 |
| 검증 방법 | 수동 점검 결과와 비교하여 일치 혹은 근사값임을 확인 |

---

## 4. III. 점검 데이터 DB 관리

### 4.1 DB 구성

- Database: `Maintenance`
- Table: `server_health_check`

SQL 파일은 `sql/schema.sql`에 작성합니다.

### 4.2 데이터 저장 결과

```sql
SELECT *
FROM Maintenance.server_health_check
ORDER BY check_time DESC;
```

실행 결과 또는 캡처 자료는 `evidence/db/`에 저장합니다.

### 4.3 점검 이력 활용

- 서버별 자원 사용률 변화:
	> HEAD 서버: 2.2%(CPU), 8%(DISK)로 안정적 다만, 87%(MEM)으로 3대의 서버 중 가장 높음
	> ESA 서버: 0.6%(CPU), 5%(DISK), 11%(MEM)으로 안정적
	> Hybrid 서버: 4.6%(CPU), 5%(DISK), 17%(MEM)으로 안정적
- 특이 Trend: HEAD 서버의 메모리 사용률이 높지만, 이는 Netwitness 엔진 및 Java 기반 메모리 예약에 기인한 Trend로 판단됨
- 추가 점검 필요 항목: 현 상태에서 추가로 데이터 수집에 따른 실질적인 수치변화를 추적 관찰하여 리소스 관리 필요

---

## 5. AI 활용 및 검증

AI 사용 자체는 제한하지 않습니다. 단, AI 출력은 정답으로 간주하지 않으며 실제 시스템 상태와 명령 결과를 기준으로 검증해야 합니다.

| 항목 | 내용 |
|---|---|
| AI를 사용한 목적 | 1. health_check.sh 자원 사용률 추출 시 발생하는 공백 및 파싱 오류 해결 / 2. schema.sql 실행 시 발생하는 경로&명령어 오류 해결 |
| AI가 제안한 내용 | 1. top, df 출력값에서 awk와 정규식을 활용해 순수 수치만 추출 제안 / 2. 환경변수 등록 또는 절대 경로 파일 실행 제안 |
| 실제 검증 방법 | 1. CLI에서 스크립트를 적용한 후, 실제 OS의 리소스 모니터링 값과 비교 / 2. 절대 경로로 schema.sql & insert.sql 순차 실행 |
| 검증 결과 | 1. 숫자형 데이터만 추출되었고, 실제 값과 동일 / 2. 문제 없이 쿼리 실행 & 별도의 경고 or 에러 결과 없음 |
| 최종 판단 | AI가 제안한 방법이 문제 없다는 것을 확인 아울러, 시스템에 별도의 영향을 끼치지 않으므로 적절했다고 판단 |

### AI 사용 시 원칙

1. 생성된 명령어 또는 코드를 실행하기 전에 의미를 이해합니다.
2. AI가 제시한 원인과 실제 시스템 증거를 구분합니다.
3. 잘못된 제안이 있었다면 수정 과정도 기록합니다.
4. 동일한 환경에서 AI 없이도 기본 점검 절차를 수행할 수 있어야 합니다.

---

## 6. Training Test 준비

본 교육 이후 다양한 장애 시나리오를 기반으로 추가 점검 테스트를 진행합니다.

- 예정일: 2026-08-31 14:00
- AI 활용 가능
- 단순 임계치 확인이 아닌 이상 징후 탐지 및 원인 추론 평가
- 여러 점검 결과와 시스템 상태를 종합적으로 연결하여 판단해야 함

본 실습은 과제를 빠르게 완성하는 데 목적이 있지 않습니다. 이후 장애 대응에 활용할 수 있도록 제품의 동작 구조와 각 점검 항목의 의미 및 확인 절차를 충분히 내재화해야 합니다.

---

## 7. 실습 결과 정리

### 이번 실습을 통해 이해한 내용

1. 데이터 축적의 중요성
	> 수동 점검시 별도의 기록이 없다면, 단발적인 데이터 해석만 할 수 있을것으로 생각됩니다. 하지만 점검 결과를 DB에 저장한다면 각 수치들의 추세 그리고 그것에서 부터 드러나는 징후들 또한 점검 지표로 활용할 수 있어 점검의 폭이 더 넓어질 수 있다고 생각됩니다.
2. 환경에 맞춘 DB 구축
	> 점검 결과를 적재할 DB의 위치(NetWitness 내부, 로컬 PC, 별도의 점검용 서버 등)를 선정하는 과정에서, 인프라 구성에 따라 데이터 수집부터 저장까지의 파이프라인이 달라진다는 점을 확인했습니다.
	질의응답을 통해 실무에서는 각 시스템의 보안 정책과 환경적 제약에 맞춰 최적의 파이프라인을 유연하게 설계해야 함을 이해했습니다. 이에 본 실습에서는 환경의 특성과 효율성을 종합적으로 고려하여 로컬 PC에 DB를 구축하였고,
	결과적으로 불필요한 복잡도를 줄여 파이프라인을 완성할 수 있었습니다.

### 기존 점검 방식에서 놓칠 수 있다고 판단한 항목

1. 장기적인 이상 징후
	> 수동 점검은 해당 시점의 상태를 기준으로 판단하기때문에 긴시간에 걸쳐 진행되는 메모리 누수 or 디스크 포화 등은 제때 식별하기 어렵다고 생각됩니다.
2. 휴먼 에러
	> 아무래도 사람이 점검을 진행하기에 사람에 따라서 점검 결과에 주관적인 판단이 과하게 적용될 우려가 있다고 생각됩니다. 이외 사람이라면 할 수 있는 실수들(오기입, 누락 등)이 있을 수 있다고 생각합니다.

### 추가적으로 자동화하고 싶은 항목

1. GUI에서 확인하고 있는 수치 통합 수집
2. OS 리소스 수치와 서비스에서 제공하는 수치 교차 검증

---

## 8. Repository 구조

```text
week03-netwitness-maintenance/
├── README.md
├── scripts/
│   └── health_check.sh
├── sql/
│   └── schema.sql
├── evidence/
│   ├── manual/
│   ├── automation/
│   └── db/
├── notes/
│   └── troubleshooting.md
└── .gitignore
```

## 9. 제출 기준

다음 항목이 저장소에 포함되어야 제출 완료로 인정합니다.

- [ ] HEAD / ESA / Hybrid 수동 점검 결과
- [ ] CPU / Memory / HDD 자동 점검 스크립트
- [ ] 자동화 실행 결과
- [ ] `Maintenance` DB 및 `server_health_check` 테이블 생성 SQL
- [ ] 점검 데이터 입력 및 조회 결과
- [ ] 오류 발생 및 해결 과정
- [ ] AI 활용 및 실제 검증 과정
- [ ] 실습을 통해 이해한 내용 정리

단순히 파일 존재 여부만 확인하지 않습니다. 작성한 코드, SQL, 명령어 및 판단 근거를 본인이 설명할 수 있어야 합니다.
