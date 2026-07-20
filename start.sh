#!/bin/bash
set -e

# ─────────────────────────────────────────────────────────
# Variables injectees par Pterodactyl (via l'egg) :
#   SERVER_PORT     - port alloue au serveur (auto, par Pterodactyl)
#   SSH_PUBLIC_KEY  - cle publique du client (variable d'egg, editable)
#   ROOT_PASSWORD   - mot de passe root (variable d'egg, editable, fallback)
# ─────────────────────────────────────────────────────────

mkdir -p /root/.ssh
chmod 700 /root/.ssh

if [ -n "$SSH_PUBLIC_KEY" ]; then
    echo "$SSH_PUBLIC_KEY" > /root/.ssh/authorized_keys
    chmod 600 /root/.ssh/authorized_keys
    passwd -l root || true
    sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
    echo "[start.sh] Cle SSH installee, mot de passe desactive."
elif [ -n "$ROOT_PASSWORD" ]; then
    echo "root:${ROOT_PASSWORD}" | chpasswd
    passwd -u root || true
    echo "[start.sh] Mot de passe root defini."
else
    # Genere un mot de passe aleatoire pour ne jamais laisser un acces vide
    RANDOM_PASS=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 20)
    echo "root:${RANDOM_PASS}" | chpasswd
    passwd -u root || true
    echo "[start.sh] ATTENTION: aucune cle/mdp fourni. Mot de passe genere: ${RANDOM_PASS}"
    echo "[start.sh] Recuperez-le dans la console Pterodactyl et changez-le."
fi

ssh-keygen -A >/dev/null 2>&1 || true

PORT="${SERVER_PORT:-22}"
echo "[start.sh] Demarrage de sshd sur le port ${PORT}"

exec /usr/sbin/sshd -D -e -p "${PORT}" -o ListenAddress=0.0.0.0
