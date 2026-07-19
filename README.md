# vps-image

Image Docker custom servant de base aux offres VPS (Basic / Medium / Premium / Mythic)
d'Orinheberge. Ubuntu 22.04 + systemd + SSH, pensee pour etre pilotee par l'API VPS
maison (pas Pterodactyl, pas l'API LXD).

## Build

```bash
docker build -t orinheberge/vps-base:latest .
```

## Lancement manuel (test)

```bash
docker run -d \
  --name vps-client-demo \
  --privileged \
  --tmpfs /run --tmpfs /run/lock \
  -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
  -e SSH_PUBLIC_KEY="ssh-ed25519 AAAA... client@example.com" \
  -e HOSTNAME_VPS="vps-basic-demo" \
  -p 2201:22 \
  --memory="2g" \
  --cpus="1.0" \
  orinheberge/vps-base:latest
```

Connexion :

```bash
ssh -p 2201 root@IP_DU_HOST
```

## Variables d'environnement

| Variable         | Obligatoire | Description                                              |
|------------------|:-----------:|------------------------------------------------------------|
| `SSH_PUBLIC_KEY` | recommande  | Cle publique du client, injectee dans `~/.ssh/authorized_keys`. Desactive le mot de passe root si presente. |
| `ROOT_PASSWORD`  | optionnel   | Mot de passe root, utilise seulement si `SSH_PUBLIC_KEY` n'est pas fourni. |
| `HOSTNAME_VPS`   | optionnel   | Hostname applique au conteneur au demarrage.               |

Si aucune des deux premieres n'est fournie, le compte root reste verrouille
(pas d'acces possible) - a gerer cote API pour toujours envoyer au moins une cle
ou un mot de passe genere automatiquement.

## Mapping resources par offre

A appliquer via les flags `--memory` / `--cpus` (ou l'equivalent JSON de l'API
Docker Engine : `Memory`, `NanoCpus`) au moment du `docker create`.

| Offre        | vCPU | RAM   | Disque (via `--storage-opt` ou quota volume) |
|--------------|:----:|:-----:|:---------------------------------------------:|
| VPS Basic    | 1    | 2 Go  | 20 Go                                         |
| VPS Medium   | 2    | 4 Go  | 40 Go                                         |
| VPS Premium  | 4    | 8 Go  | 80 Go                                         |
| VPS Mythic   | 8    | 16 Go | 160 Go                                        |

## Notes de securite importantes

- Le conteneur tourne en `--privileged` pour permettre a `systemd` de fonctionner
  correctement (necessaire pour offrir une experience "VPS complet" avec
  plusieurs services). Cela reduit l'isolation par rapport a une vraie VM ou a
  LXC : un client root dans le conteneur a potentiellement plus de surface
  d'attaque vis-a-vis de l'hote qu'avec un hyperviseur classique.
- Limiter les risques : noyau a jour sur l'hote, `AppArmor`/`seccomp` par
  defaut de Docker non desactives (le mode `--privileged` desactive
  `seccomp`/`AppArmor` cote conteneur - a evaluer selon le niveau de confiance
  que vous accordez a vos clients), et surveillance des conteneurs (`docker
  stats`, alerting).
- Chaque conteneur doit avoir un port SSH host unique (mappe dynamiquement par
  l'API VPS lors de la creation) et idealement un reseau Docker dedie/isole
  entre clients (`docker network create` par client ou VLAN, a definir selon
  vos besoins).

## Prochaine etape

Ce repo fournit uniquement l'image. Le provisioning (creation/demarrage/arret/
suppression des conteneurs, attribution des ports, generation des cles) est
gere par l'API PHP maison, separee de ce repo.
