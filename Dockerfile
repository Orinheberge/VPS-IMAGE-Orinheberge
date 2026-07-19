FROM ubuntu:22.04

LABEL maintainer="Orinheberge"
LABEL description="Image VPS custom - Ubuntu 22.04 + systemd + SSH"

ENV DEBIAN_FRONTEND=noninteractive

# Paquets de base + systemd + SSH
RUN apt-get update && apt-get install -y --no-install-recommends \
        systemd \
        systemd-sysv \
        openssh-server \
        sudo \
        curl \
        wget \
        nano \
        vim \
        htop \
        net-tools \
        iproute2 \
        ca-certificates \
        cron \
        gnupg \
        lsb-release \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Nettoyage des unités systemd inutiles/problématiques en conteneur
RUN cd /lib/systemd/system/sysinit.target.wants/ \
    && for i in *; do [ "$i" = "systemd-tmpfiles-setup.service" ] || rm -f "$i"; done \
    && rm -f /lib/systemd/system/multi-user.target.wants/* \
    && rm -f /etc/systemd/system/*.wants/* \
    && rm -f /lib/systemd/system/local-fs.target.wants/* \
    && rm -f /lib/systemd/system/sockets.target.wants/*udev* \
    && rm -f /lib/systemd/system/sockets.target.wants/*initctl* \
    && rm -f /lib/systemd/system/basic.target.wants/* \
    && (rm -f /lib/systemd/system/anaconda.target.wants/* || true)

# Config SSH
RUN mkdir -p /var/run/sshd \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && echo 'root:changeme' | chpasswd

# Mot de passe root desactive par defaut tant qu'aucune cle/mdp n'est fournie
# (l'entrypoint le regenere au demarrage du conteneur)
RUN passwd -l root

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Necessaire pour que systemd fonctionne correctement en conteneur
STOPSIGNAL SIGRTMIN+3
VOLUME [ "/sys/fs/cgroup" ]

EXPOSE 22

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/sbin/init"]
