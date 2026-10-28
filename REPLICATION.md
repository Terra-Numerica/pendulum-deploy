# Réplication du démonstrateur "Pendule Inversé"

## Environnement

Rasppberry Pi 4 modèle B 1Gb.

OS avec desktop (pour affichage des vidéos et documents support pendant l'animation)

## Procédure

### Création de la carte SD

Utiliser l'outil **Raspberry Pi Imager** pour créer la carte SD. 16Gb sont suffisants.

#### Sélection de la version 

- La version utilisée en date de rédaction est `Trixie`.
- Raspberry Pi OS (32 bits)

**TODO:** valider si le 32/64 bits est réellement la source des problèmes rencontrés.

#### Configuration de l'image

(via le bouton **EDIT SETIINGS**)

##### hostname

Eviter de laisser le hostname par défaut si vous utilisez des Raspberry 
sur différents démonstrateur. Utilisez à la place un pattern comme `rpi-pendulum-<n>`,
`n` représentant un identificateur numérique ou autre vous permettant de différencier
plusieurs exemplaires du système.

##### username et password

Même si cela est maintenant signalé par l'outil comme *unsafe* utilisez le
username historique `pi`. Cela simplifier ala maintenance par des tiers. Pour
ce qui est du password, à vous de le gérer pour que là encore ne pas
transformer une intervention de maintenance en escape game.

##### ssh

Activez-le car il est plus confortable de travailler depuis votre machine habituelle
que de devoir connecter un écran, un clavier et une souris à la Raspberry. 

Il est conseillé de choisir l'option *public-key authentication only*, 
surtout si vous avez opté pour un mot de passe pouvant être deviné.

### Configuration post-boot initial

Les opérations à faire sont décrites ici en mode CLI. La raison de ce choix
est que leur équivalent via l'interface graphique évolue au gré des versions de l'OS 
alors que les commandes en mode CLI sont stables.

L'outil utilisé est `raspi-config`.

### System options

#### Wireless LAN (S1)

A vous de voir si le WiFi est nécessaire. 

Dans le cas contraire, le désactiver réduit la consommation électrique et par conséquent
l'échauffement de la carte.

#### Admin Password (S10)

Il est activé par défaut dans les versions récentes de l'OS Raspberry, à
l'image de toutes les autes distributions Linux. 

Dans le cas présent, certaines commandes de lancement des composants du
contrôleur du pendule nécessite le mode `sudo`. Demander le password à
l'animateur à chaque fois peut poser un problème s'il ne le connaît pas. Par
conséquent, désactivez-le dans ce contexte précis, le système n'étant pas de
nature critique et n'étant pas supposé accéder à des ressources critiques. 

**A ne surtout pas reproduire** par défaut sur vos autres installation.

## Installation des dépendances

La couche logicielle du démonstrateur est composée de deux programmes :

- `low_level_interface` : contrôleur bas niveau, interagissant directement avec le hardware et 
fournissant une interface de communication aux applications
- `demo` : l'application utilisée pour l'animation

La communication entre le contrôleur et les applications est basée sur le protocole **ZeroMQ**.

Ces deux programmes ont des dépendances directes ou indirectes avec les bibliothèques externes
suivantes :

- `libsodium` : dépendance transitive de `zmq` 
- `libzmq` : moteur de communication ZeroMQ
- `zmqpp` : binding C++ de `libzmq`
- `pigpio` : interactions avec les IOs de la Raspberry
- `yaml-cpp` : lecture et écriture des fichiers de configuration au format YAML

Afin de disposer des versions adaptées à l'environnement matériel et système, toutes ces 
dépendances sont compilées à partir de leur code source. Cela nécessite plusieurs outils :

- `gcc` : normalement déja présent dans la distribution Rasppberry
- `make` : déjà présent également
- `CMake` : à installer via la commande `sudo apt install cmake`

Du fait des inter-dépendances, l'installation doit être faite dans la séquence suivante.

Afin d'isoler les dépendances externes des codes du projet lui-même, leurs codes sources sont
installés dans une arborescence séparée. Préparez l'environnement comment suit:
```
cd $HOME
mkdir deps 
cd deps
```

La section suivante détaillant l'installation de chacune d'entre elles suppose qu'on débute la
procédure en étant déjà dans le répertoire `$HOME/deps/`.

### libsodium

Télécharger les sources: 
```
wget https://github.com/jedisct1/libsodium/archive/refs/heads/master.zip libsodium-master.git
```

Décompresser l'archive:
```
unzip libsodium-master.git
```

Configurer et lancer la compilation:
```
cd libsodium-master
./configure 
make && nake check
```
Installer la bibliothèque:
```
sudo make install
```

Pour plus de détail : https://doc.libsodium.org/installation

### libzmq

Télécharger les sources: 
```
wget https://github.com/zeromq/libzmq/archive/refs/heads/master.zip libzmq-master.zip
```

Décompresser l'archive:
```
unzip libzmq-master.git
```
Préparer l'environnement de compilation:
```
cd libzmq-master
mkdir build && cd build
```

Configurer et lancer la compilation:
```
cmake ..
cmake --build .
```
Vérifier que la commande `cmake` ne produit pas d'erreur, l'absence d'une dépendance requise
étant bloquante pour la suite de la procédure.

Installer la bibliothèque:
```
sudo cmake install .
```

Pour plus de détail : https://github.com/zeromq/libzmq

### zmqpp

Télécharger les sources: 
```
wget https://github.com/zeromq/zmqpp/archive/refs/heads/develop.zip zmqpp-master.zip
```

**Note:** la branche `develop` du projet est utilisé car `master` semble accuser un retard
de mise à jour important en date de rédaction de ce document.

Décompresser l'archive:
```
unzip zmqpp-develop.git
```
Préparer l'environnement de compilation:
```
cd zmqpp-develop
mkdir build && cd build
```

Configurer et lancer la compilation:
```
cmake ..
cmake --build .
```
Vérifier que la commande `cmake` ne produit pas d'erreur, l'absence d'une dépendance requise
étant bloquante pour la suite de la procédure.

Installer la bibliothèque:
```
sudo cmake install .
```

Pour plus de détail : https://github.com/zeromq/zmqpp

### pigpio

Télécharger les sources: 
```
wget wget https://github.com/joan2937/pigpio/archive/master.zip pigpio-master.zip
```

Décompresser l'archive:
```
unzip pigpio-master.git
```

Lancer la compilation:
```
cmake --build .
```

Installer la bibliothèque:
```
sudo cmake install .
```

Pour plus de détail : https://abyz.me.uk/rpi/pigpio/index.html

### yaml-cpp

Télécharger les sources: 
```
wget https://github.com/jbeder/yaml-cpp/archive/refs/heads/master.zip yaml-cpp-master.git
```

Décompresser l'archive:
```
unzip yaml-cpp-master.git
```

Configurer et lancer la compilation:
```
cd yaml-cpp-master
cmake ..
cmake --build .
```
Installer la bibliothèque:
```
sudo cmake install .
```

Pour plus de détail : https://github.com/jbeder/yaml-cpp

## Exécutables du pendule

Les codes sources du projet sont installés dans une arborescence séparée, préparée comme suit:

```
cd $HOME
mkdir devel
cd devel
```

### `digital_filters`

Cette bibliothèque interne a été initialement créée par F. Fusco dans le cadre du développement
du démonstrateur. Elle est utilisée par le code de contrôle du pendule.

Télécharger les sources: 
```
wget https://github.com/Terra-Numerica/pendulum-digital_filters/archive/refs/heads/main.zip digital_filters-main.zip
```

Décompresser l'archive:
```
unzip digital_filters-main.zip
```
Préparer l'environnement de compilation:
```
cd digital_filters-main
mkdir build && cd build
```

Configurer et lancer la compilation:
```
cmake ..
cmake --build .
```
Vérifier que la commande `cmake` ne produit pas d'erreur, l'absence d'une dépendance requise
étant bloquante pour la suite de la procédure.

Installer la bibliothèque:
```
sudo cmake install .
```

### `pendulum_pi`

Version pour Raspberry Pi du code de contrôle et de démonstration du pendule inversé.
Le projet produit plusieurs exécutables:

- `low_level_interface` : le contrôleur bas niveau du dispositif matériel
- `demo` : la démonstration interactive

Télécharger les sources: 
```
wget https://github.com/Terra-Numerica/pendulum-core/archive/refs/heads/main.zip pendulum_core-main.zip
```

Décompresser l'archive:
```
unzip pendulum_core-main.zip
```
Préparer l'environnement de compilation:
```
cd pendulum_core-main
mkdir build && cd build
```

Configurer et lancer la compilation:
```
cmake ..
cmake --build .
```
Vérifier que la commande `cmake` ne produit pas d'erreur, l'absence d'une dépendance requise
étant bloquante pour la suite de la procédure.

Il n'y a pas de phase d'installation ici, les exécutables produits dans `build` étant directement
utilisés.

## Mise en place de l'espace de déploiement

Afin de sécuriser les versions stables des exécutables et des fichiers de configuration tout
en permettant d'effectuer des modifications expérimentales, une arborescence de fichiers dédiée
est définie directement sous `$HOME`.

Elle a la structure suivante :

```
pendulum_pi/
├── dev/
│   └── config/
├── pendulum.sh
└── stable/
    ├── config/
    │   ├── demo.yaml
    │   └── pendule_pi_config.yaml
    └── <binaires contrôleur, démo, outils...>
```

La branche `stable` sert à archiver les versions des exécutables et des fichiers de configuration
utilisés en *production*. On y retrouve directement sous `stable/` une copie des exécutables 
produits dans `build/`

- `low_level_interface`
- `demo`
- `reset_gpio` *(outil pour réinitialiser les I/Os en cas de problème)*

Cette copie permet de figer leur version, indépendemment des modifications locales et compilations
faites dans le projet. Le contenu de `stable/config/` suit la même logique, sauvegardant les
fichiers de configuration validés pour la prodcution.

Les fichiers homologues sous `dev/` sont des liens symboliques sur les artefacts produits dans `build/`
et les fichiers de configuration de travail. Ceci permet d'avoir en permanence la toute dernière 
version de développement sans nécessiter de copie manuelle. Ils ne sont à créer que si vous voulez
tester une version expérimentale en parallèle de la version stable. La branche `dev/` peut sinon
rester vide.

La bascule entre les configurations `dev` est `stable` se fait en modifiant le lien symbolique 
`active` à la racine de l'arborescence. Le script `pendulum.sh` utilise le path `$HOME/pendulum_pi/active`
pour accéder aux différents fichiers lors du lancement des exécutables. Ce script est copié 
depuis le projet `pendulum-core` lors du déploiement initial et à chaque mise à jour. On peut
aussi définir un lien symbolique vers l'orginal au lieu d'en faire la copie, ce script étant 
assez stable.

Exécutez les commandes suivantes pour la mise en place de cette structure :

```
cd $HOME
wget https://github.com/Terra-Numerica/pendulum-deploy/archive/refs/heads/main.zip pendulum-deploy-main.zip
unzip pendulum-deploy-main.zip .
```

**Important:** Attention à ne pas omettre le point en fin de commande unzip pour ne pas créer un
sous-repertoire. Vérifiez bien que la structure a été créée directement à la racine du home dir.

## Initialisation de l'espace de déploiement

Après avoir généré les exécutables, copier les binaires dans la branche `stable/`:

```
copy devel/pendulum-core/build/{low_level_interface,demo,reset_gpio} pendulum_pi/stable
```

Activez enfin l'accès à la version stable en créant le lien symbolique :

```
ln -s pendulum_pi/stable pendulum_pi/active
```

En fin de procédure, l'arborescence doit avoir ce contenu :

```
pendulum_pi/
├── active -> stable
├── dev/
│   └── config/
├── pendulum.sh
└── stable/
    ├── config/
    │   ├── demo.yaml
    │   └── pendule_pi_config.yaml
    ├── demo
    ├── low_level_interface
    └── reset_gpio
```

## Commande end-user

Pour simplifier l'utilisation de script end-user, ajouter un lien symbolique dans le chemin
de recherche par défaut du shell:

```
ln -s pendulum_pi/pendulum.sh .local.bin/pendulum
```

La commande `pendulum` sera ainsi accessible de n'importe où.

## Affichage par défaut de la notice 

Afin de fournir aux animateurs les instructions de base directement à l'ouverture du terminal, 
ajouter la ligne suivante à la fin du fichier `$HOME/.bashrc`:

```
clear && cat NOTICE.txt
```

## La commande `pendulum`

Elle permet de gérer simplement les actions suivantes:
- démarrage du contrôleur de bas niveau
- lancement de la démo 
- arrêt du contrôleur

Elle dispose d'une aide en ligne:

```
$ pendulum
Invalid command.
Usage: pendulum start|stop|status|demo|help

$ pendulum help
Usage: pendulum start|stop|status|demo|help

start  : starts the hardware controller and run it in background. 
         *** MUST BE DONE BEFORE RUNNING THE DEMO ***
stop   : stops the controller
status : displays the current status of the controller
    
demo   : starts the demonstration application
```
