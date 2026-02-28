#!/bin/bash
set -e

echo "========================================"
echo " FreeRADIUS 2FA Google Authenticator"
echo "========================================"

# Wait for PostgreSQL to be ready
echo "[*] Waiting for PostgreSQL..."
until pg_isready -h postgres -U "${POSTGRES_USER:-radius}" -q; do
echo "    PostgreSQL is not ready yet, retrying in 2s..."
sleep 2
done
echo "[+] PostgreSQL is ready!"

# Sync users from PostgreSQL to local GA secrets
echo "[*] Syncing users from database..."
/opt/api-venv/bin/python3 /opt/api/sync_users.py

# Enable PAM module in FreeRADIUS
if [ ! -L /etc/freeradius/3.0/mods-enabled/pam ]; then
ln -sf /etc/freeradius/3.0/mods-available/pam /etc/freeradius/3.0/mods-enabled/pam
echo "[+] PAM module enabled"
fi

# Ensure correct permissions
chown -R root:root /etc/freeradius/users-ga
chmod 700 /etc/freeradius/users-ga
chmod 600 /etc/freeradius/users-ga/* 2>/dev/null || true

echo "[+] Starting services with supervisor..."
exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf