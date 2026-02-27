CREATE OR REPLACE PROCEDURE deposit_money(
    p_account_id INT,
    p_amount NUMERIC(12,2)
)
LANGUAGE plpgsql
AS $$
BEGIN
    
    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'Deposit amount must be positive';
    END IF;

    
    UPDATE accounts
    SET balance = balance + p_amount
    WHERE account_id = p_account_id;

    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Account does not exist';
    END IF;

    
    INSERT INTO transactions(account_id, type, amount)
    VALUES (p_account_id, 'DEPOSIT', p_amount);
	RAISE NOTICE 'SUCCESS!';

END;
$$;

CREATE OR REPLACE PROCEDURE withdraw_money(
    p_account_id INT,
    p_amount NUMERIC(12,2)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_balance NUMERIC(12,2);
    v_status VARCHAR(20);
    v_daily_total NUMERIC(12,2);
    v_daily_limit NUMERIC(12,2);
BEGIN
   
    IF p_amount IS NULL OR p_amount <= 0 THEN
        RAISE EXCEPTION 'Withdrawal amount must be positive';
    END IF;

    
    SELECT balance, status, daily_limit
    INTO v_balance, v_status, v_daily_limit
    FROM accounts
    WHERE account_id = p_account_id
    FOR UPDATE;

    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Account does not exist';
    END IF;

   
    IF v_status <> 'ACTIVE' THEN
        RAISE EXCEPTION 'Account is not active';
    END IF;

    
    IF v_balance < p_amount THEN
        RAISE EXCEPTION 'Insufficient balance';
    END IF;

    
    SELECT COALESCE(SUM(amount),0)
    INTO v_daily_total
    FROM transactions
    WHERE account_id = p_account_id
      AND type = 'WITHDRAW'
      AND created_at::date = CURRENT_DATE;

    
    IF v_daily_total + p_amount > v_daily_limit THEN
        RAISE EXCEPTION 'Daily withdrawal limit exceeded';
    END IF;

    
    UPDATE accounts
    SET balance = balance - p_amount
    WHERE account_id = p_account_id;

    
    INSERT INTO transactions(account_id, type, amount)
    VALUES (p_account_id, 'WITHDRAW', p_amount);

END;
$$;

CREATE OR REPLACE PROCEDURE transfer_money(
    p_from_account INT,
    p_to_account INT,
    p_amount NUMERIC(12,2)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_balance NUMERIC(12,2);
BEGIN
    IF p_amount IS NULL OR p_amount <= 0 THEN
        RAISE EXCEPTION 'Transfer amount must be positive';
    END IF;

    IF p_from_account = p_to_account THEN
        RAISE EXCEPTION 'Cannot transfer to same account';
    END IF;

    SELECT balance INTO v_balance
    FROM accounts
    WHERE account_id = p_from_account
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Sender account does not exist';
    END IF;

    IF (SELECT status FROM accounts WHERE account_id = p_from_account) <> 'ACTIVE' THEN
        RAISE EXCEPTION 'Sender account not active';
    END IF;

    IF v_balance < p_amount THEN
        RAISE EXCEPTION 'Insufficient balance';
    END IF;

    PERFORM 1
    FROM accounts
    WHERE account_id = p_to_account
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Receiver account does not exist';
    END IF;

    UPDATE accounts
    SET balance = balance - p_amount
    WHERE account_id = p_from_account;

    UPDATE accounts
    SET balance = balance + p_amount
    WHERE account_id = p_to_account;

    INSERT INTO transactions(account_id, type, amount)
    VALUES (p_from_account, 'TRANSFER_OUT', p_amount);

    INSERT INTO transactions(account_id, type, amount)
    VALUES (p_to_account, 'TRANSFER_IN', p_amount);
END;
$$;

CREATE OR REPLACE FUNCTION apply_interest(
    p_account_id INT,
    p_rate NUMERIC(5,2)  
)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    v_balance NUMERIC(12,2);
    v_interest NUMERIC(12,2);
BEGIN
    SELECT balance
    INTO v_balance
    FROM accounts
    WHERE account_id = p_account_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Account does not exist';
    END IF;

    IF v_balance <= 0 THEN
        RETURN 0;
    END IF;

    v_interest := ROUND(v_balance * (p_rate / 100), 2);

    UPDATE accounts
    SET balance = balance + v_interest
    WHERE account_id = p_account_id;

    INSERT INTO transactions(account_id, type, amount)
    VALUES (p_account_id, 'INTEREST', v_interest);

    RETURN v_interest;
END;
$$;

CREATE OR REPLACE FUNCTION check_loan_eligibility(
    p_customer_id INT
)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    v_balance NUMERIC(12,2);
    v_high_risk_count INT;
    v_kyc_status VARCHAR(20);
BEGIN
    -- Check KYC
    SELECT kyc_status
    INTO v_kyc_status
    FROM customers
    WHERE customer_id = p_customer_id;

    IF v_kyc_status <> 'VERIFIED' THEN
        RETURN 'NOT_ELIGIBLE_KYC';
    END IF;

    -- Get total balance across accounts
    SELECT COALESCE(SUM(balance),0)
    INTO v_balance
    FROM accounts
    WHERE customer_id = p_customer_id;

    -- Check fraud history
    SELECT COUNT(*)
    INTO v_high_risk_count
    FROM transactions t
    JOIN accounts a ON t.account_id = a.account_id
    WHERE a.customer_id = p_customer_id
      AND t.fraud_flag = 'HIGH_RISK';

    -- Decision logic
    IF v_balance >= 100000 AND v_high_risk_count = 0 THEN
        RETURN 'ELIGIBLE';
    ELSIF v_high_risk_count > 0 THEN
        RETURN 'REVIEW_REQUIRED';
    ELSE
        RETURN 'NOT_ELIGIBLE';
    END IF;
END;
$$;
