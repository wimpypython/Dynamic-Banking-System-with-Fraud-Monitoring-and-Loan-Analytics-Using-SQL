from faker import Faker
import pandas as pd
import random

fake = Faker("en_IN")

NUM_CUSTOMERS = 1000
NUM_ACCOUNTS = 1500
NUM_TRANSACTIONS = 10000
NUM_LOANS = 300

indian_cities = [
    "Mumbai","Delhi","Bangalore","Chennai","Hyderabad",
    "Pune","Kolkata","Ahmedabad","Jaipur","Chandigarh",
    "Indore","Bhopal","Lucknow","Kanpur","Noida","Gurgaon"
]

# ---------------- CUSTOMERS ----------------
customers = []

for i in range(1, NUM_CUSTOMERS + 1):
    full_name = fake.name()
    email = full_name.lower().replace(" ", ".") + "@gmail.com"

    customers.append({
        "customer_id": i,
        "full_name": full_name,
        "email": email,
        "phone": fake.msisdn()[:10],
        "date_of_birth": fake.date_of_birth(minimum_age=18, maximum_age=65),
        "city": random.choice(indian_cities),
        "kyc_status": "VERIFIED"
    })

pd.DataFrame(customers).to_csv("customers.csv", index=False)

# ---------------- ACCOUNTS ----------------
accounts = []

for i in range(1, NUM_ACCOUNTS + 1):
    accounts.append({
        "account_id": i,
        "customer_id": random.randint(1, NUM_CUSTOMERS),
        "branch_city": random.choice(indian_cities),
        "account_type": random.choice(["SAVINGS","CURRENT"]),
        "balance": round(random.uniform(1000, 500000), 2),
        "status": "ACTIVE"
    })

pd.DataFrame(accounts).to_csv("accounts.csv", index=False)

# ---------------- TRANSACTIONS ----------------
transactions = []

for i in range(1, NUM_TRANSACTIONS + 1):
    transactions.append({
        "transaction_id": i,
        "account_id": random.randint(1, NUM_ACCOUNTS),
        "type": random.choice(["DEPOSIT","WITHDRAW","TRANSFER_IN","TRANSFER_OUT"]),
        "amount": round(random.uniform(100, 50000), 2)
    })

pd.DataFrame(transactions).to_csv("transactions.csv", index=False)

# ---------------- LOANS ----------------
loans = []

for i in range(1, NUM_LOANS + 1):
    loans.append({
        "loan_id": i,
        "customer_id": random.randint(1, NUM_CUSTOMERS),
        "principal": random.randint(100000, 1000000),
        "interest_rate": round(random.uniform(8, 14), 2),
        "outstanding_amount": random.randint(50000, 900000),
        "status": "ACTIVE",
        "tenure_months": random.randint(12, 60)
    })

pd.DataFrame(loans).to_csv("loans.csv", index=False)

print("Indian banking data generated successfully 🇮🇳")
