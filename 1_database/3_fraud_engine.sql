CREATE OR REPLACE FUNCTION public.calculate_fraud_score(p_transaction_id integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $$
DECLARE
    v_score INT := 0;
    v_amount NUMERIC(12,2);
    v_account_id INT;
    v_transaction_count INT;
    v_account_age_days INT;
    v_last_transaction_date TIMESTAMP;
    v_days_since_last NUMERIC;
BEGIN
    SELECT amount, account_id, created_at
    INTO v_amount, v_account_id, v_last_transaction_date
    FROM transactions
    WHERE transaction_id = p_transaction_id;
	
	--RULE 1: High Value Transaction
    IF v_amount > 150000 THEN
        v_score := v_score + 30;
    ELSIF v_amount > 100000 THEN
        v_score := v_score + 15;
    END IF;
	
    -- RULE 2: Rapid transactions (3+ in last hour) = +25 points
    SELECT COUNT(*)
    INTO v_transaction_count
    FROM transactions
    WHERE account_id = v_account_id
      AND created_at >= v_last_transaction_date - INTERVAL '1 hour'
      AND created_at < v_last_transaction_date;
    IF v_transaction_count >= 3 THEN
        v_score := v_score + 25;
    ELSIF v_transaction_count = 2 THEN
        v_score := v_score + 10;
    END IF;
    
    -- RULE 3: Dormant account suddenly active = +20 points
    SELECT EXTRACT(DAY FROM v_last_transaction_date - COALESCE(MAX(created_at), v_last_transaction_date))
	INTO v_days_since_last
	FROM transactions
	WHERE account_id = v_account_id
  	AND transaction_id < p_transaction_id;
    IF v_days_since_last > 90 THEN
        v_score := v_score + 20;
    ELSIF v_days_since_last > 60 THEN
        v_score := v_score + 10;
    END IF;
    
    -- RULE 4: New account (<30 days old) with high transaction = +15 points
    SELECT EXTRACT(DAY FROM CURRENT_DATE - created_at)
    INTO v_account_age_days
    FROM accounts
    WHERE account_id = v_account_id;
    IF v_account_age_days < 30 AND v_amount > 100000 THEN
        v_score := v_score + 15;
    END IF;
    
    -- RULE 5: Multiple withdrawals same day = +10 points
    SELECT COUNT(*)
    INTO v_transaction_count
    FROM transactions
    WHERE account_id = v_account_id
      AND type = 'WITHDRAW'
      AND created_at::date = v_last_transaction_date::date;
    
    IF v_transaction_count >= 5 THEN
        v_score := v_score + 10;
    END IF;
    
    RETURN v_score;
END;
$$;

CREATE OR REPLACE FUNCTION public.fraud_check_on_insert()
 RETURNS trigger
 LANGUAGE plpgsql
AS $$
DECLARE
    v_fraud_score INT;
BEGIN
    v_fraud_score := 0;
  
    -- RULE 1: High value transaction
    IF NEW.amount > 150000 THEN
        v_fraud_score := v_fraud_score + 30;
    ELSIF NEW.amount > 100000 THEN
        v_fraud_score := v_fraud_score + 15;
    END IF;
    
    -- RULE 2: Rapid transactions (check account history)
    DECLARE
        v_recent_count INT;
    BEGIN
        SELECT COUNT(*)
        INTO v_recent_count
        FROM transactions
        WHERE account_id = NEW.account_id
          AND created_at >= CURRENT_TIMESTAMP - INTERVAL '1 hour';        
        IF v_recent_count >= 3 THEN
            v_fraud_score := v_fraud_score + 25;
        ELSIF v_recent_count >= 2 THEN
            v_fraud_score := v_fraud_score + 10;
        END IF;
    END;
    
    -- RULE 3: Dormant account check
    DECLARE
        v_last_transaction TIMESTAMP;
        v_days_inactive NUMERIC;
    BEGIN
        SELECT MAX(created_at)
        INTO v_last_transaction
        FROM transactions
        WHERE account_id = NEW.account_id;
        IF v_last_transaction IS NOT NULL THEN
            v_days_inactive := EXTRACT(DAY FROM CURRENT_TIMESTAMP - v_last_transaction);            
            IF v_days_inactive > 90 THEN
                v_fraud_score := v_fraud_score + 20;
            ELSIF v_days_inactive > 60 THEN
                v_fraud_score := v_fraud_score + 10;
            END IF;
        END IF;
    END;
    
    -- RULE 4: New account check
    DECLARE
        v_account_age NUMERIC;
    BEGIN
        SELECT EXTRACT(DAY FROM CURRENT_TIMESTAMP - created_at)
        INTO v_account_age
        FROM accounts
        WHERE account_id = NEW.account_id;        
        IF v_account_age < 30 AND NEW.amount > 100000 THEN
            v_fraud_score := v_fraud_score + 15;
        END IF;
    END;
    
    -- RULE 5: Multiple withdrawals same day
    IF NEW.type = 'WITHDRAW' THEN
        DECLARE
            v_today_withdrawals INT;
        BEGIN
            SELECT COUNT(*)
            INTO v_today_withdrawals
            FROM transactions
            WHERE account_id = NEW.account_id
              AND type = 'WITHDRAW'
              AND created_at::date = CURRENT_DATE;            
            IF v_today_withdrawals >= 5 THEN
                v_fraud_score := v_fraud_score + 10;
            END IF;
        END;
    END IF;
    
    -- Cap at 100
    IF v_fraud_score > 100 THEN
        v_fraud_score := 100;
    END IF;
    
    NEW.fraud_score := v_fraud_score;
    
    -- Flag based on score
    IF v_fraud_score >= 60 THEN
        NEW.fraud_flag := 'HIGH_RISK';
        NEW.fraud_reason := FORMAT('TRIGGER ALERT - Score: %s - Multiple high-risk indicators detected', v_fraud_score);
        NEW.flagged_at := CURRENT_TIMESTAMP;
        RAISE WARNING 'HIGH RISK TRANSACTION DETECTED - Account: %, Amount: %, Score: %',
            NEW.account_id, NEW.amount, v_fraud_score;
        
    ELSIF v_fraud_score >= 40 THEN
        NEW.fraud_flag := 'SUSPICIOUS';
        NEW.fraud_reason := FORMAT('TRIGGER ALERT - Score: %s - Elevated risk detected', v_fraud_score);
        NEW.flagged_at := CURRENT_TIMESTAMP;
        RAISE NOTICE 'Suspicious transaction detected - Account: %, Score: %',
            NEW.account_id, v_fraud_score;
    ELSE
        NEW.fraud_flag := 'NORMAL';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER transaction_fraud_detection 
BEFORE INSERT ON public.transactions 
FOR EACH ROW 
EXECUTE FUNCTION fraud_check_on_insert();
