# 🚀 SentinelPay — Secure Cloud Deployment, IaC, DevSecOps & Purple Team Simulation
A full end‑to‑end security engineering project covering Application Security, Cloud Security, Infrastructure‑as‑Code, DevSecOps, and a Purple Team attack simulation.
This repository contains the final, hardened version of the SentinelPay platform after completing the 21‑day VaultBridge Capstone.

# 📌 Executive Summary
This project transforms an intentionally vulnerable fintech platform into a secure, cloud‑native, production‑ready system using:

- AWS (ECS, RDS, ALB, VPC, Secrets Manager, CloudTrail, GuardDuty)

- Terraform (IaC, remote backend, modules, drift detection)

- GitHub Actions (multi‑stage DevSecOps pipeline)

- Container security (Trivy)

- IaC security (tfsec, Checkov)

- Secrets scanning (Gitleaks)

- Policy‑as‑Code (OPA)

- Runtime threat detection (Falco)

- The final deliverable includes:

- A secure AWS deployment

- A hardened CI/CD pipeline

- A documented attack simulation

- A full remediation report

- A complete teardown of cloud resources

# 📚 Table of Contents
- Architecture

- Features

- Services

- Local Development

- Cloud Infrastructure (Terraform)

- Security Hardening

- DevSecOps Pipeline

- IaC Drift Attack Simulation

- Deliverables

# 🏗️ Final Architecture (Post‑Hardening)
Cloud Components
- VPC with public/private subnets

- ECS Fargate for containerized microservices

- Application Load Balancer

- RDS PostgreSQL (encrypted, private subnets)

- ElastiCache Redis (private subnets)

- Secrets Manager with automatic rotation

- CloudTrail + GuardDuty

- S3 remote backend + DynamoDB lock table

- IAM least‑privilege roles

- KMS encryption

# Security Layers
- Network segmentation

- IAM hardening

- Secrets rotation

- Runtime threat detection

- IaC drift detection

- Pipeline security gates

- Policy‑as‑code enforcement

# 🧩 Services

There are **two services**, sharing **one PostgreSQL database** and **one Redis cache**:

| Service        | Stack             | Port  | Responsibility                                            |
| -------------- | ----------------- | ----- | --------------------------------------------------------- |
| `payments-api` | Python 3.11 + Flask | 8001  | Authentication, accounts, wallets, transactions, webhooks |
| `kyc-api`      | Python 3.11 + Flask | 8002  | Identity verification, document upload, BVN/NIN lookup    |

Both services share:

PostgreSQL

Redis

# 🛠️ Local Development
bash

    docker compose up --build
    docker compose exec payments-api python -m app.seed
    
Endpoints:

http://localhost:8001

http://localhost:8002

# 🌩️ Cloud Infrastructure (Terraform)
Key Features
- Modular Terraform structure

- Remote backend (S3 + DynamoDB)

- Encrypted state

- Automated drift detection

- Secure IAM roles

- Private networking

- Automated teardown

# Deployment
bash

     terraform init
      terraform plan
      terraform apply

# Teardown
bash

       terraform destroy
   
# 🔐 Security Hardening Completed
# - Application Security
    - 11 vulnerabilities identified & remediated

     - Authentication flaws fixed

    - IDOR eliminated

     - Input validation added

     - Secure session handling

     - Logging & monitoring added

# - Cloud Security
      -  Private subnets for all sensitive workloads

      - No public database access

      - IAM least‑privilege

       - Secrets Manager rotation

       -KMS encryption

       -CloudTrail + GuardDuty

# - Pipeline Security
       -Static code analysis

        -Dependency scanning

        -Container scanning (Trivy)

       -IaC scanning (tfsec, Checkov)

        -Secrets scanning (Gitleaks)

        -OPA policy checks

        -Drift detection

        -Signed Terraform plans

# 🔄 DevSecOps Pipeline (GitHub Actions)
# Stages
1. Build & Test

2. Linting & SAST

3. Dependency scanning

4. Container scanning

5. IaC scanning

6. Secrets scanning

7. OPA policy checks

8. Terraform plan

9. Manual approval

10. Terraform apply

11. Post‑deployment validation

This pipeline blocks insecure changes automatically.

# 🧨 IaC Drift Attack Simulation (Purple Team)
# - Attack Scenario
An attacker modifies AWS resources outside Terraform, including:

       - Security groups

       - IAM roles

       -S3 bucket policies

       -ECS task definitions

# - Detection
       -Drift detected by Terraform

       -Pipeline blocks deployment

       -Alerts triggered

       -Manual review required

# - Outcome
       -Drift remediated

       -Infrastructure restored to known‑good state

       -Attack chain documented

# 📦 Deliverables
- Threat model

- Vulnerability inventory

- Remediation report

- Terraform IaC

- Secure AWS architecture

- DevSecOps pipeline

- Attack simulation report

- Final teardown

- Updated documentation









