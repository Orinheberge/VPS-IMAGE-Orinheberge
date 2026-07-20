FROM ubuntu:22.04

LABEL maintainer="Orinheberge"
LABEL description="Image VPS SSH pour egg Pterodactyl (Basic/Medium/Premium/Mythic)"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
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
        tmux \
        screen \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/run/sshd \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && sed -i 's/^#*UsePAM.*/UsePAM no/' /etc/ssh/sshd_config

# Root dans le conteneur (necessaire pour un vrai acces VPS) -> pas de USER ici.

COPY start.sh /start.sh
RUN chmod +x /start.sh

CMD ["/bin/bash", "/start.sh"]
