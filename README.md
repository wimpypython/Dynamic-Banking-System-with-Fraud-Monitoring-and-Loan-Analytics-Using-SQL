# Banking-Transaction-System-with-Real-Time-Fraud-Detection
PostgreSQL banking system with atomic transactions, real-time fraud detection and demonstrating ACID transactions.

---

## 📌 Project Overview

This project simulates a real-world banking backend system with:

- Customer management
- Multi-account handling
- Transaction processing
- Fraud detection engine
- Loan eligibility evaluation
- Interest calculation
- Analytical customer views

The system is designed with modular SQL architecture and structured for scalability.

---

## Database Architecture

### Core Tables

- `customers`
- `accounts`
- `transactions`
- `loans`

### Key Features

- Identity-based transaction IDs
- Balance validation constraints
- Daily withdrawal limits
- Timestamp tracking
- Fraud scoring columns

---

## 💰 Core Banking Procedures

- `deposit_money`
- `withdraw_money`
- `transfer_money`
- `apply_interest`
- `check_loan_eligibility`

These procedures ensure secure and validated financial operations.

---

## 🔐 ACID Compliance

The Dynamic Banking System is designed to adhere strictly to ACID (Atomicity, Consistency, Isolation, Durability) principles to ensure reliable financial operations.

Atomicity: All transactions (deposits, withdrawals, transfers, interest updates) run within transactional boundaries. If any validation fails, the entire operation is rolled back to prevent partial updates.

Consistency: Database constraints such as non-negative balances, foreign keys, NOT NULL rules, and validated transaction types ensure the database always remains in a valid state.

Isolation: Row-level locking (FOR UPDATE) prevents race conditions and double spending during concurrent transactions.

Durability: PostgreSQL’s Write-Ahead Logging (WAL) guarantees that committed transactions remain permanent, even after system failures.

By enforcing ACID properties across core banking operations and fraud detection logic, the system simulates real-world financial database reliability standards.

---

## 🔐 Fraud Detection Rules

1. **High Value** - Transactions >150K (+30 pts), >100K (+15 pts)
2. **Rapid Transactions** - 3+ in 1 hour (+25 pts)
3. **Dormant Reactivation** - Inactive 90+ days (+20 pts)
4. **New Account Risk** - Account <30 days + >100K transaction (+15 pts)
5. **Withdrawal Velocity** - 5+ withdrawals same day (+10 pts)

**Fraud Levels And Scorin:**
- 0-39: NORMAL
- 40-59: SUSPICIOUS (monitoring required)
- 60-100: HIGH_RISK (immediate review)

---

## 📊 Customer Summary View

The `customer_summary` view provides:

- Customer demographics
- Account details
- Current balance
- Total transactions
- Fraud statistics
- Age calculation

This view powers Excel dashboards and KPI if needed.

---

## 🎓 Key SQL Concepts Demonstrated

- Row-level locking (`FOR UPDATE`)
- Transaction atomicity
- Database triggers (`BEFORE INSERT`)
- Stored procedures with error handling
- Parameterized functions
- Aggregate views with JOINs
- Check constraints
- Window Functions
- Generated identity columns
- COALESCE for NULL handling
- Date operations and filtering
**Built with:** PostgreSQL, PL/pgSQL, SQL, Python
**Focus:** Database design, fraud detection, transaction integrity
  
---

## 📂 Repository Structure
├── 1_database/          SQL scripts
├── 2_data_generation    Explains data collection and generation
└── 3_screenshots/       Visual documentation

---

## 📝 License

MIT License - Portfolio project demonstrating SQL proficiency.

---

## 📧 Contact

**Atharva Phalak**
- LinkedIn: www.linkedin.com/in/atharva-phalak-066962367
- Email: atharvaphalak12@gmail.com
- SQL | POWER BI | DATA ANALYTICS 

---
