## 📊 Data Generation (Synthetic Banking Data)

To simulate a realistic banking environment for analytics and fraud testing, synthetic data was generated using the **Faker (en_IN locale)** Python library.

This approach allows large-scale testing of:

- Fraud detection logic
- Loan eligibility analysis
- Transaction analytics

---

### 🔹 Technologies Used

- Python
- Faker (Indian locale)
- Pandas
- Random module

---

### 🔹 Dataset Configuration

The following synthetic volumes were generated:

| Entity        | Records |
|--------------|----------|
| Customers     | 1000     |
| Accounts      | 1500     |
| Transactions  | 10000    |
| Loans         | 300      |

---

### 🔹 Customer Data Generation

Each customer record includes:

- `customer_id`
- `full_name`
- `email`
- `phone`
- `date_of_birth`
- `city`
- `kyc_status`

All customer data is randomly generated but structured to resemble realistic Indian banking data.

Cities are randomly selected from major Indian metropolitan areas.

KYC status is set to `"VERIFIED"` for baseline testing.
