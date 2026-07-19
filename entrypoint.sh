#!/bin/bash
set -e

# ─────────────────────────────────────────────
# Variables d'environnement attendues (injectees par l'API VPS) :
#   SSH_PUBLIC_KEY   - cle publique SSH du client (recommande)
#   ROOT_PASSWORD    - mot de passe root (fallback si pas de cle)
#   HOSTNAME_VPS     - hostname a appliquer au conteneur
# ─────────────────────────────────────────────

mkdir -p /root/.ssh
chmod 700 /root/.ssh

if [ -n "$SSH_PUBLIC_KEY" ]; then
    echo "$SSH_PUBLIC_KEY" > /root/.ssh/authorized_keys
    chmod 600 /root/.ssh/authorized_keys
    passwd -l root || true
    sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
    echo "[entrypoint] Cle SSH installee, connexion par mot de passe desactivee."
fi

if [ -n "$ROOT_PASSWORD" ]; then
    echo "root:${ROOT_PASSWORD}" | chpasswd
    passwd -u root || true
    echo "[entrypoint] Mot de passe root defini."
fi

if [ -z "$SSH_PUBLIC_KEY" ] && [ -z "$ROOT_PASSWORD" ]; then
    echo "[entrypoint] ATTENTION: ni SSH_PUBLIC_KEY ni ROOT_PASSWORD fournis. Le compte root reste verrouille."
fi

if [ -n "$HOSTNAME_VPS" ]; then
    echo "$HOSTNAME_VPS" > /etc/hostname
    hostname "$HOSTNAME_VPS" 2>/dev/null || true
fi

# Regenere les cles hote SSH si absentes (premier demarrage)
ssh-keygen -A

exec "$@"
