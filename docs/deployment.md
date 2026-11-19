# BloomWell Production Deployment Guide

This guide walks through deploying the BloomWell backend and HTTPS reverse proxy to production on AWS using Docker, Caddy, and managed PostgreSQL.

---

## 1. Prerequisites

Before beginning the deployment, prepare the following:
1. **Domain Name or Subdomain:** A public domain or subdomain (for example, `api.bloomwell.org` or `api.example.com`) pointed via DNS A record to your server's future public IP address.
2. **AWS Account & Billing Alert:**
   - Create an AWS account.
   - Configure a Billing Budget Alert in the AWS Billing Console (e.g. set an alert threshold of \$15/month) to avoid unexpected charges.
3. **SSH Key Pair:**
   - Generate an SSH key pair locally if you do not have one:
     ```bash
     ssh-keygen -t ed25519 -C "admin@bloomwell.org" -f ~/.ssh/bloomwell_ec2
     ```
   - Keep the private key secure on your local workstation; you will upload the public key (`~/.ssh/bloomwell_ec2.pub`) to AWS.

---

## 2. Infrastructure Setup (AWS VPC & Subnets)

Deploy the application and database into an isolated Virtual Private Cloud (VPC) with public and private subnets.

### 2.1 Managed PostgreSQL Instance (AWS RDS)
1. In the AWS RDS console, create a PostgreSQL 16 instance:
   - **DB Engine:** PostgreSQL 16.x.
   - **Instance Class:** `db.t4g.micro` or `db.t3.micro` (budget-friendly).
   - **VPC Subnet Group:** Place RDS in a **Private Subnet** (no public IP, unreachable from the internet).
   - **Storage:** General Purpose SSD (gp3), 20 GB with storage autoscaling enabled.
   - **Backup Retention:** Set automated backup retention to at least 14 days with automated snapshot window.
   - **Database Name:** `bloomwell`.
   - **Master Username:** `bloomwell_admin`.
   - **Master Password:** Generate a strong random password (store in a password manager).
2. Note the RDS endpoint (e.g. `bloomwell-db.cxxxxxx.us-east-1.rds.amazonaws.com`).

### 2.2 Application Host Server (AWS EC2)
1. Launch an EC2 instance:
   - **AMI:** Ubuntu 24.04 LTS (x86_64 or arm64/Graviton).
   - **Instance Type:** `t4g.small` or `t3.small` (1-2 GB RAM minimum).
   - **VPC:** Same VPC as the RDS instance, placed in the **Public Subnet**.
   - **Public IP:** Assign an Elastic IP to ensure the public IP remains static across restarts.
   - **Key Pair:** Select your uploaded SSH public key.
2. Point your DNS A record (e.g. `api.bloomwell.org`) to the Elastic IP.

### 2.3 Security Groups Configuration
Configure two distinct security groups to enforce network isolation:

1. **`bloomwell-ec2-sg` (Application Host):**
   - **Inbound Rules:**
     - Port `80` (HTTP) from `0.0.0.0/0` (public, required for ACME HTTP challenges).
     - Port `443` (HTTPS) from `0.0.0.0/0` (public, user API traffic).
     - Port `22` (SSH) restricted strictly to your current workstation IP (`<YOUR_WORKSTATION_IP>/32`). Never leave port 22 open to `0.0.0.0/0`.
   - **Outbound Rules:**
     - All traffic allowed (`0.0.0.0/0`).

2. **`bloomwell-rds-sg` (Database Instance):**
   - **Inbound Rules:**
     - Port `5432` (PostgreSQL) allowed ONLY from `bloomwell-ec2-sg` (select the security group ID as source). Zero public ingress.
   - **Outbound Rules:**
     - None required.

---

## 3. Server Preparation & Docker Installation

SSH into the newly created server:
```bash
ssh -i ~/.ssh/bloomwell_ec2 ubuntu@<SERVER_PUBLIC_IP>
```

Install Docker Engine and Docker Compose plugin:
```bash
# Update packages and install prerequisites
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg git

# Install official Docker
curl -fsSL https://get.docker.com | sudo sh

# Add the ubuntu user to the docker group
sudo usermod -aG docker ubuntu
newgrp docker

# Verify Docker and Compose installations
docker --version
docker compose version
```

---

## 4. Repository Setup & Secret Generation

1. Clone the repository to the server:
   ```bash
   git clone https://github.com/radhika817/BloomWell.git
   cd BloomWell
   ```

2. Initialize `.env.production` from the template:
   ```bash
   cp .env.production.example .env.production
   chmod 600 .env.production
   ```

3. Generate strong secrets locally on the server without printing them to logs or bash history:
   ```bash
   # Generate a 64-character hex secret for APP_SECRET_KEY and insert directly
   NEW_SECRET=$(openssl rand -hex 32)
   sed -i "s|replace_with_at_least_32_characters_random_hex_secret|${NEW_SECRET}|g" .env.production
   unset NEW_SECRET
   ```

4. Edit `.env.production` using `nano .env.production` or `vim .env.production` to fill in:
   - `DATABASE_URL`: `postgresql+psycopg://bloomwell_admin:<DB_PASSWORD>@<RDS_ENDPOINT>:5432/bloomwell`
   - `DOMAIN`: Your actual DNS hostname (e.g. `api.bloomwell.org`).
   - `CORS_ORIGINS`: Allowed origins (e.g. `https://app.bloomwell.org`). Never use `*`.
   - `TRUSTED_PROXY_IPS`: Keep `127.0.0.1,::1,172.16.0.0/12,192.168.0.0/16,10.0.0.0/8`.

---

## 5. First Deployment

Deploy BloomWell using the automated deployment script:
```bash
./scripts/deploy.sh
```

What `deploy.sh` performs automatically:
1. Pulls the latest code from `main`.
2. Tags existing container image for safe rollback.
3. Builds the production `bloomwell-api:latest` Docker image.
4. Executes database migrations (`alembic upgrade head`) as an isolated one-off container before modifying running services.
5. Starts the API container (never published to host ports, reachable only via Caddy).
6. Starts Caddy reverse proxy, which provisions a Let's Encrypt TLS certificate automatically and handles HTTP->HTTPS redirection.
7. Waits for `/health` to report `{"status":"ok"}`.

Verify the service is live from your local machine:
```bash
curl -i https://api.yourdomain.com/health
```

---

## 6. Create Initial Resource Admin

Promote your initial administrative account using the safety-guarded role assignment script:
```bash
docker compose -f docker-compose.prod.yml exec -T api python scripts/set_role.py <admin_email@example.com> resource_admin --yes
```

---

## 7. Configure GitHub Actions Mobile Build

1. Go to your GitHub repository -> **Settings** -> **Secrets and variables** -> **Actions** -> **Variables** tab.
2. Click **New repository variable**.
3. Name: `API_BASE_URL`.
4. Value: `https://api.yourdomain.com` (must begin with `https://`).
5. In GitHub Actions, navigate to **Build Release APK** -> **Run workflow** -> select branch `main` -> click **Run workflow**.

---

## 8. Automated Backups & Off-Site Replication

1. Create a secure backup storage directory and credentials file on the server:
   ```bash
   sudo mkdir -p /var/backups/bloomwell /etc/bloomwell
   sudo chmod 700 /var/backups/bloomwell /etc/bloomwell
   
   # Optional: set backup encryption passphrase
   openssl rand -base64 32 | sudo tee /etc/bloomwell/backup.pass > /dev/null
   sudo chmod 600 /etc/bloomwell/backup.pass
   ```

2. Schedule daily database backups via `crontab -e`:
   ```cron
   # Run BloomWell database backup every night at 02:00 UTC
   0 2 * * * cd /home/ubuntu/BloomWell && BACKUP_RETENTION_DAYS=14 BACKUP_PASSPHRASE=$(cat /etc/bloomwell/backup.pass) ./scripts/backup.sh >> /var/log/bloomwell-backup.log 2>&1
   ```

3. **Off-Site Sync:** Sync local backups to an encrypted S3 bucket:
   ```bash
   aws s3 sync /var/backups/bloomwell s3://bloomwell-encrypted-backups/ --sse aws:kms
   ```

---

## 9. Monthly Restore Drill Procedure

Never trust an untested backup. Execute this drill once a month:

1. SSH into the server and identify the latest backup dump:
   ```bash
   LATEST_DUMP=$(ls -t /var/backups/bloomwell/*.dump* | head -n 1)
   ```
2. Create an isolated verification database:
   ```bash
   docker compose -f docker-compose.prod.yml exec -T api python -c "
   from sqlalchemy import create_engine, text
   import os
   url = os.environ['DATABASE_URL'].rsplit('/', 1)[0] + '/postgres'
   engine = create_engine(url)
   with engine.connect().execution_options(isolation_level='AUTOCOMMIT') as conn:
       conn.execute(text('DROP DATABASE IF EXISTS bloomwell_restore_drill;'))
       conn.execute(text('CREATE DATABASE bloomwell_restore_drill;'))
   print('Verification database created.')
   "
   ```
3. Run the restore script into the verification database:
   ```bash
   BACKUP_PASSPHRASE=$(cat /etc/bloomwell/backup.pass) ./scripts/restore.sh "${LATEST_DUMP}" bloomwell_restore_drill
   ```
4. Check record consistency and clean up:
   ```bash
   docker compose -f docker-compose.prod.yml exec -T api python -c "
   from sqlalchemy import create_engine, text
   import os
   url = os.environ['DATABASE_URL'].rsplit('/', 1)[0] + '/bloomwell_restore_drill'
   engine = create_engine(url)
   with engine.connect() as conn:
       res = conn.execute(text('SELECT count(*) FROM users;')).scalar()
       print(f'Restored user count: {res}')
   with create_engine(os.environ['DATABASE_URL'].rsplit('/', 1)[0] + '/postgres').connect().execution_options(isolation_level='AUTOCOMMIT') as conn:
       conn.execute(text('DROP DATABASE bloomwell_restore_drill;'))
   print('Drill completed and verification database cleaned up.')
   "
   ```
