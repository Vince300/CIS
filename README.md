# Projet CIS - Equipe 2

## Mise en place du front-end

installation de debian avec serveur ssh et utilitaires classique
installation de sudo
creation de l'utilisateur admin avec adduser
inscription de admin au groupe sudo

`groupadd limited` creation du group limitied pour lequel on restreindra les ressources
(il faut lors de la création d'utilisateurs ajouter `gpasswd -a user group`)
modification de `/etc/security/limits.conf` pour restreindre les inscrit au groupe limited

mise en place de [quota](https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/6/html/Storage_Administration_Guide/ch-disk-quotas.html)
(il faut lors de la création d'utilisateurs ajouter `setquota -u USER X X X X -a /`)
