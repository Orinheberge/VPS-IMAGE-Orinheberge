# vps-ssh (egg Pterodactyl)

Image Docker + egg Pterodactyl fournissant un accès VPS via SSH (Ubuntu 22.04),
pour les offres **VPS Basic / Medium / Premium / Mythic** d'Orinheberge.

Contrairement à une première approche envisagée (conteneur privilégié +
systemd), cette version est pensée pour tourner **nativement sous Wings**
(le daemon Pterodactyl), sans mode privilégié : `sshd` est lancé directement
comme process principal, sur le port alloué par Pterodactyl.

## Fichiers

| Fichier              | Rôle                                                        |
|-----------------------|-------------------------------------------------------------|
| `Dockerfile`          | Image Ubuntu 22.04 + openssh-server + outils de base        |
| `start.sh`            | Script de démarrage : injecte clé/mdp, lance `sshd`          |
| `egg-vps-ssh.json`    | Egg Pterodactyl à importer (format `PTDL_v2`)                |
| `018_vps_ssh_egg.sql` | Migration SQL : ajoute l'egg + les 4 offres dans le panel     |

## 1. Build & push de l'image

```bash
docker build -t ghcr.io/TON-USER/vps-ssh:latest .
docker push ghcr.io/TON-USER/vps-ssh:latest
```

Wings (le daemon sur tes nodes Pterodactyl) doit pouvoir pull cette image —
si le repo GitHub Container Registry est privé, il faut configurer un
`docker login ghcr.io` sur chaque node, ou rendre l'image publique.

## 2. Import de l'egg dans Pterodactyl

1. Panel Pterodactyl → **Admin → Nests** → choisis (ou crée) un nest, ex. `VPS`
2. **Import Egg** → uploade `egg-vps-ssh.json`
3. Vérifie/édite l'image Docker si besoin (doit correspondre à celle pushée)
4. Note le **Egg ID** et le **Nest ID** affichés (nécessaires à l'étape 3)

## 3. Lier l'egg à ton panel (Orinheberge)

Édite `018_vps_ssh_egg.sql` : remplace `<PANEL_EGG_ID>` et `<PANEL_NEST_ID>`
par les valeurs notées à l'étape 2, ajuste `node_id` si tu utilises un node
Pterodactyl dédié aux VPS, puis exécute la migration :

```bash
mysql -u ton_user -p ta_base < 018_vps_ssh_egg.sql
```

Les 4 offres (`vps-basic`, `vps-medium`, `vps-premium`, `vps-mythic`)
apparaissent alors dans `products`, exactement comme tes offres existantes
(Minecraft, FiveM, etc.) — la commande, la facturation et le cycle de vie
(suspension/renouvellement) sont gérés par le code déjà en place, aucune
logique supplémentaire à coder côté panel.

## Variables d'egg (visibles/éditables par le client)

| Variable         | Description                                                        |
|-------------------|---------------------------------------------------------------------|
| `SSH_PUBLIC_KEY`  | Clé publique SSH. Si renseignée, désactive la connexion par mot de passe. |
| `ROOT_PASSWORD`   | Mot de passe root, utilisé seulement si aucune clé n'est fournie.    |

Si ni l'une ni l'autre n'est fournie, `start.sh` génère un mot de passe
aléatoire visible dans les logs/console du serveur (à récupérer et changer).

## Mapping resources par offre

| Offre        | vCPU | RAM   | Disque |
|--------------|:----:|:-----:|:------:|
| VPS Basic    | 1    | 2 Go  | 20 Go  |
| VPS Medium   | 2    | 4 Go  | 40 Go  |
| VPS Premium  | 4    | 8 Go  | 80 Go  |
| VPS Mythic   | 8    | 16 Go | 160 Go |

## Notes de sécurité

- Pas de mode `--privileged` requis : Wings applique ses limites CPU/RAM/disque
  standard comme pour n'importe quel autre serveur du panel.
- Le client a un accès root **dans le conteneur** (nécessaire pour un vrai
  usage VPS : installer des paquets, gérer des services...). Il n'a pas accès
  à l'hôte ni aux autres conteneurs — l'isolation Docker standard s'applique.
- Le port SSH exposé correspond à l'allocation Pterodactyl du serveur (visible
  et gérable depuis le panel, comme n'importe quel port de jeu).
