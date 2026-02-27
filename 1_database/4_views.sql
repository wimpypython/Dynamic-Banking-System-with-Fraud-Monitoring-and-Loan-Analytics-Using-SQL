CREATE OR REPLACE VIEW customer_summary AS
SELECT
    c.customer_id,
    c.full_name,
    c.city,
    a.account_id,
    a.account_type,
    a.status AS account_status,
    a.balance AS current_balance,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, c.date_of_birth)) AS customer_age_years,
    COUNT(t.transaction_id) AS total_transactions,
    COUNT(CASE WHEN t.fraud_flag = 'HIGH_RISK' THEN 1 END) AS high_risk_count,
    COUNT(CASE WHEN t.fraud_flag = 'SUSPICIOUS' THEN 1 END) AS suspicious_count
FROM customers c
JOIN accounts a ON c.customer_id = a.customer_id
LEFT JOIN transactions t ON a.account_id = t.account_id
GROUP BY 
    c.customer_id,
    c.full_name,
    c.city,
    a.account_id,
    a.account_type,
    a.status,
    a.balance,
    c.date_of_birth;

