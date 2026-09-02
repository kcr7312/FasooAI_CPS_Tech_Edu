USE Maintenance;

-- 점검 데이터 Insert
INSERT INTO server_health_check 
(server_name, server_ip, check_time, cpu_usage, memory_usage, disk_usage, status, note) 
VALUES 
('nwserver', '192.168.102.7', '2026-09-01 10:17:47', 2.20, 87.73, 8.00, 'Normal', '메모리 사용률은 JVM 사전 할당으로 인한 정상 수치'),
('esaPrimary', '192.168.102.8', '2026-09-01 10:17:56', 0.60, 10.91, 5.00, 'Normal', '특이사항 없음'),
('hybrid', '192.168.102.9', '2026-09-01 10:18:05', 4.60, 17.06, 5.00, 'Normal', '특이사항 없음');

-- 증적용 조회 쿼리 실행
SELECT * FROM server_health_check ORDER BY check_time DESC;