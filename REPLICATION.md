---
title: |
  Démonstrateur "Pendule Inversé" \
  Réplication de l'environnement logiciel
author: Eric PASCUAL (Terra Numerica)
date: \today
papersize: a4
geometry: margin=2.5cm
toc-depth: 2
toc-title: Sommaire
include-before:
  - '`\newpage`{=latex}'       
  - '`\tableofcontents`{=latex}'
  - '`\newpage`{=latex}'
lang: fr-FR
mainfont: DejaVu Sans
monofont: DejaVu Sans Mono
header-includes: |
  \usepackage{fvextra}
  \usepackage{xcolor}
  \RecustomVerbatimEnvironment{verbatim}{Verbatim}{
    frame=single,
    rulecolor=\color{gray!50},
    framesep=2mm,
    fontsize=\small
  }
  \usepackage{fancyhdr}
  \pagestyle{fancy}
  \fancyhead[LO,RE]{Démonstrateur "Pendule Inversé"}

abstract: |
    Ce document détaille les opérations à effectuer pour répliquer la partie logicielle
    du démonstrateur du pendule inversé.

    Ces opérations concernent la création et la configuration du système d'exploitation,
    l'installation des dépendances externes et enfin celles des logiciels spécifiques.
    
    L'installation aussi bien des dépendances externes que des logiciels spécifiques
    se faisant à partir de leur code source et non en utilisant des paquets pré-compilés,
    leur mise en &oelig;uvre suppose une connaissance du système Linux mais aussi une 
    expérience préalable des outils et procédures de développement logiciel.

    Il a par ailleurs été rédigé en se basant sur l'utilisation d'un environnement Linux 
    comme station de travail. Il appartient à l'utilisateur de faire ses propres recherches
    pour trouver les modes opératoires équivalentes pour son système d'exploitation si nécessaire.
---

# Environnement système

## Création de la carte SD

Utiliser l'outil **Raspberry Pi Imager** pour créer la carte SD. 16Gb sont suffisants.

### Sélection de la version 

La version servant de base à la configuration actuelle est **Raspbian Buster**.

Cette version n'est pas du tout la dernière en date, mais est celle qui fonctionne
actuellement sur les démonstrateurs en service. 

Même si un tel choix peut sembler contraire aux principes de sécurité, le contexte particulier
d'un système embarqué et non connecté permet de déroger aux bonnes pratiques. 

N'étant pas proposée par défaut par Imager, il faut donc la télécharger
depuis la section archive du site Raspberry et la sélectionner ensuite via 
l'option "Custom image".

Choisir la version avec environnement graphique, mais sans les applications recommandées.

### Configuration de l'image avant flash

(via le bouton **EDIT SETTINGS**)

#### hostname

Évitez de laisser le hostname par défaut si vous utilisez des Raspberry 
sur différents démonstrateurs. Utilisez à la place un pattern comme `rpi-pendulum-<n>`,
`n` représentant un identificateur numérique ou autre vous permettant de différencier
plusieurs exemplaires du système.

#### username et password

Même si cela est maintenant signalé par l'outil comme *unsafe*, utilisez le
username historique `pi`. Cela simplifiera la maintenance par des tiers. Pour
ce qui est du password, à vous de le gérer pour là encore ne pas
transformer une intervention de maintenance en escape game.

#### ssh

Activez-le, car il est plus confortable de travailler depuis votre machine habituelle
que de devoir connecter un écran, un clavier et une souris à la Raspberry. 

Il est conseillé de choisir l'option *public-key authentication only*, 
surtout si vous avez opté pour un mot de passe pouvant être deviné.

### Patch de l'image

La version Buster étant ancienne, elle ne démarre pas sur les RPi 4 récentes. Il faut donc
la patcher en récupérant les fichiers récents depuis une image récente.

La procédure ci-après est basée sur l'utilisation d'un système Linux.

#### Préparation

- monter la carte SD
- télécharger l'image ISO de la version actuelle (Trixie en date de rédaction)
- la décompresser puis la monter localement pour avoir accès aux filesystems `rootfs` 
et `bootfs`

### Mise à jour des fichiers de boot et du firmware  

Copier les fichiers et répertoires suivants depuis la partition `bootfs` de l'image récente 
vers celle de la carte SD :

```
cp /path/to/modern/iso/bootfs/start*.elf /path/to/buster/bootfs/
cp /path/to/modern/iso/bootfs/fixup*.dat /path/to/buster/bootfs/
```

### Mise à jour du layout tree et du kernel

Le hardware des ports USB et Ethernet a évolué depuis les modèles de Raspberry supportés 
par `buster`. Les fichiers systèmes de la distribution ne les supportant pas, il faut mettre
à jour le *device tree* également :

```
cp /path/to/modern/iso/bootfs/*.dtb /path/to/buster/bootfs/
cp -r /path/to/modern/iso/bootfs//overlays/ /path/to/buster/bootfs/
```

Idem pour le kernel :

```
cp /path/to/modern/iso/bootfs/kernel*.img /path/to/buster/bootfs/
```

Ainsi que les kernel modules.

**Attention :** ça se passe dans le `rootfs` et non plus le `bootfs` cette fois-ci.

```
cp -r /path/to/modern/iso/rootfs/lib/modules/* /path/to/buster/rootfs/
```

Une fois ces patchs effectués, faire un `unmount` des partitions `rootfs` et `bootfs` 
de la carte SD, insérez-la dans la Raspberry et mettez cette dernière sous tension.

## Configuration post-boot initial

Les opérations à faire sont décrites ici en mode CLI. Ce choix est motivé par le fait
que leur équivalent via l'interface graphique évolue au gré des versions de l'OS 
alors que les commandes en mode CLI sont stables.

L'outil utilisé est `raspi-config`.

### System options / Wireless LAN (S1)

A vous de voir si le WiFi est nécessaire. Il peut être pratique pour intervenir sur la
carte si vous n'avez pas la possibilité de la connecter avec un câble Ethernet, mais 
il n'est pas nécessaire en conditions opérationnelles. 

Par ailleurs, le désactiver réduit la consommation électrique et par conséquent
l'échauffement de la carte. 

Cela permet aussi d'éviter de laisser traîner des informations de connexion 
à vos réseaux internes ou personnels sur la carte SD.

### System options / Admin Password (S10)

Il est activé par défaut dans les versions récentes de l'OS Raspberry, à
l'image de toutes les autres distributions Linux. 

Dans le cas présent, certaines commandes de lancement des composants du
contrôleur du pendule nécessitent le mode `sudo`. Demander le password à
l'animateur à chaque fois peut poser un problème s'il ne le connaît pas
et il finira probablement écrit sur un Post-It bien en évidence sur le
dispositif :/

Par conséquent, désactivez-le dans ce contexte précis, le système n'étant pas de
nature critique et n'étant pas supposé accéder à des ressources à protéger. 

**A ne surtout pas utiliser comme configuration par défaut** sur vos autres 
applications, sauf très bonne raison comme ici.

# Installation des dépendances

La couche logicielle du démonstrateur est composée de deux programmes :

- `low_level_interface` : contrôleur bas niveau, interagissant directement avec le hardware et 
fournissant une interface de communication aux applications
- `demo` : l'application utilisée pour l'animation

La communication entre le contrôleur et les applications est basée sur le protocole **ZeroMQ**.

Ces deux programmes ont des dépendances directes ou indirectes avec les bibliothèques externes
suivantes :

- `libzmq` : moteur de communication ZeroMQ
- `zmqpp` : binding C++ de `libzmq`
- `pigpio` : interactions avec les GPIOs de la Raspberry
- `yaml-cpp` : accès aux fichiers de configuration, qui sont au format YAML

Afin de disposer des versions adaptées à l'environnement matériel et système, toutes ces 
dépendances sont compilées à partir de leur code source. Cela nécessite plusieurs outils :

- `gcc` : normalement déja présent dans la distribution Raspberry
- `make` : déjà présent également
- `cmake` : non présent par défaut

Afin d'isoler les dépendances externes des codes du projet lui-même, leurs codes sources sont
installés dans une arborescence séparée sous `$HOME/deps`. Préparez l'environnement comme
suit :

```
mkdir $HOME/deps 
```

La section suivante détaille l'installation de chacune des dépendances. Du fait de leurs 
inter-dépendances, l'installation doit être faite en respectant la séquence.

## CMake

La version de CMake présente dans le repository apt de Buster est la 3.16.3. Elle est trop
ancienne pour certains outils de développement
remote. Nous allons donc installer CMake en le compilant depuis les sources, mais en restant
sur la version utilisée pour les exemplaires précédents du démonstrateur (3.19.4) par
sécurité.  

**Ne pas tenter de passer à la version 4.x** de CMake tant que l'OS reste en version Buster.

La compilation de CMake depuis les sources nécessite que `libssl-dev` soit installée au préalable :

```
sudo apt install libssl-dev 
```

Si cette librairie n'est pas présente sur le système, le step `bootstrap` de la compilation 
de CMake échouera en le signalant. 

Récupérez maintenant les sources de CMake :

```
cd $HOME/deps
wget https://cmake.org/files/v3.19/cmake-3.19.4.tar.gz
tar xzvf cmake-3.19.4.tar.gz
```

Lancez la configuration de la compilation :

```
cd cmake-3.19.4
./bootstrap
```

Cette opération peut prendre un peu de temps. C'est pendant cette étape que l'absence de 
`libssl-dev` vous sera signalée le cas échéant.

Si tout est OK, lancez la compilation :

```
make -j 4
sudo make install
sudo ldconfig
```

Comme conseillé dans les documentations, rebooter la Raspberry avant de poursuivre.

Vérifiez la version pour finir cette étape :

```
cmake --version
cmake version 3.19.4

CMake suite maintained and supported by Kitware (kitware.com/cmake).
```

## ZeroMQ

Téléchargez les sources : 

```
cd $HOME/deps
wget \
    https://github.com/zeromq/libzmq/archive/refs/heads/master.zip \
    -O libzmq-master.zip
```

Décompressez l'archive:

```
unzip libzmq-master.git
```
Préparez l'environnement de compilation :

```
cd libzmq-master
mkdir build && cd build
```

Configurez et lancez la compilation :

```
cmake -DENABLE_CURVE=OFF -DWITH_LIBSODIUM=OFF ..
cmake --build .
```

**Note :** il n'y a pas besoin d'activer la couche de sécurité et le cryptage pour le type
d'application concerné ici. Les désactiver permet de plus d'être moins consommateur en CPU
à l'exécution.

Vérifiez que la commande `cmake` ne produit pas d'erreur, l'absence d'une dépendance requise
étant bloquante pour la suite de la procédure.

Installez la bibliothèque:

```
sudo cmake --install .
```

Pour plus de détail : https://github.com/zeromq/libzmq

## Bindings C++ pour ZeroMQ

Téléchargez les sources : 

```
cd $HOME/deps
wget \
    https://github.com/zeromq/zmqpp/archive/refs/heads/develop.zip \
    -O zmqpp-master.zip
```

**Note:** la branche `develop` du projet est utilisé car `master` semble accuser un retard
de mise à jour important en date de rédaction de ce document.

Décompressez l'archive :

```
unzip zmqpp-develop.git
```
Préparez l'environnement de compilation :

```
cd zmqpp-develop
mkdir build && cd build
```

Configurez et lancer la compilation :

```
cmake ..
cmake --build .
```

Vérifiez que la commande `cmake` ne produit pas d'erreur, l'absence d'une dépendance requise
étant bloquante pour la suite de la procédure.

Installez la bibliothèque :

```
sudo cmake --install .
sudo ldconfig
```

Pour plus de détail : https://github.com/zeromq/zmqpp

## pigpio

Téléchargez les sources : 

```
cd $HOME/deps
wget \
    https://github.com/joan2937/pigpio/archive/master.zip \
    -O pigpio-master.zip
```

Décompressez l'archive :
```
unzip pigpio-master.git
```

Préparez l'environnement de compilation :

```
cd pigpio-master
mkdir build && cd build
```

Lancez la compilation :

```
cmake ..
cmake --build .
```

Installez la bibliothèque:

```
sudo cmake --install .
```

Pour plus de détail : https://abyz.me.uk/rpi/pigpio/index.html

## yaml-cpp

Téléchargez les sources : 

```
cd ~/deps
wget \
    https://github.com/jbeder/yaml-cpp/archive/refs/heads/master.zip \
    -O yaml-cpp-master.git
```

Décompressez l'archive :

```
unzip yaml-cpp-master.git
```

Préparez l'environnement de compilation :

```
cd yaml-cpp-master
mkdir build && cd build
```

Configurer et lancer la compilation :

```
cmake ..
cmake --build .
```

Installez la bibliothèque :

```
sudo cmake --install .
```

Pour plus de détail : https://github.com/jbeder/yaml-cpp

# Exécutables du pendule

Les codes sources du projet sont installés dans une arborescence séparée, située sous `$HOME/devel`.

```
cd $HOME
mkdir devel
```

## Evolutions par rapport au projet original 

### Merge de digital_filters

Le projet original de F. Fusco inclut une dépendance interne
(`digital_filters`) qui fournit une bibliothèque de filtres numériques.

Si conserver cette bibliothèque sous forme d'artefact séparé avait du sens
pendant le projet initial, elle n'est utilisée que par le code *low level*
du contrôleur du pendule. Afin de simplifier la gestion du projet, les sources
correspondants ont été directement inclus dans le projet `pendulum-core`.

### Génération de la documentation interne

La documentation interne des classes modélisant le pendule et ses divers accessoires
(moteur, bouton,...) présente un intérêt dans le cadre d'un packaging de ces derniers dans
une bibliothèque indépendante, vouée à être utilisée par d'autres projets.

Ce scénario ne présente plus d'intérêt suffisant dans le contexte de la réplication du
démonstrateur pour justifier la complexité additionnelle de la production d'une documentation
technique au standard des pratiques. 

La documentation interne des sources eux-mêmes aurait de plus demandé à être très largement
complétée, pour ne pas dire rédigée.

Cette target du CMakeList initial a donc été supprimée et la dépendance à Doxygen a été retirée.
Les fichiers sources correspondant ont également été retirés du projet.

## `pendulum-core`

Version pour Raspberry Pi du code de contrôle et de démonstration du pendule inversé.

Le projet produit plusieurs exécutables :

- `low_level_interface` : le contrôleur bas niveau du dispositif matériel
- `demo` : la démonstration interactive
- `reset_gpio` : utilitaire de reset des GPIO de la Raspberry, en cas de nécessité

Téléchargez les sources : 

```
cd $HOME/devel
wget \
    https://github.com/Terra-Numerica/pendulum-core/archive/refs/heads/main.zip \
    -O pendulum_core-main.zip
```

Décompressez l'archive:

```
unzip pendulum_core-main.zip
```

Préparez l'environnement de compilation :

```
cd pendulum_core-main
mkdir build && cd build
```

Configurer et lancer la compilation des binaires exécutables :

```
cmake -DCMAKE_BUILD_TYPE=Release ..
cmake --build . --target low_level_interface --target demo --target reset_gpio
```
Vérifier que la commande `cmake` ne produit pas d'erreur, l'absence d'une dépendance requise
étant bloquante pour la suite de la procédure.

Il n'y a pas de phase d'installation ici, les exécutables produits dans `build` étant directement
utilisés.

# Environnent runtime

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
utilisés en *production*. On retrouve directement sous `stable/` une copie des exécutables 
produits dans `build/`

- `low_level_interface`
- `demo`
- `reset_gpio` *(outil pour réinitialiser les I/Os en cas de problème)*

Cette copie permet de figer leur version, indépendamment des modifications locales et compilations
faites dans le projet. Le contenu de `stable/config/` suit la même logique, sauvegardant les
fichiers de configuration validés pour la production.

Les fichiers homologues sous `dev/` sont des liens symboliques sur les artefacts produits dans `build/`
et les fichiers de configuration de travail. Ceci permet d'avoir en permanence la toute dernière 
version de développement sans nécessiter de copie manuelle. Ils ne sont à créer que si vous voulez
tester une version expérimentale en parallèle de la version stable. La branche `dev/` peut sinon
rester vide.

La bascule entre les configurations `dev` est `stable` se fait en modifiant le lien symbolique 
`active` à la racine de l'arborescence. Le script `pendulum.sh` utilise le path `$HOME/pendulum_pi/active`
pour accéder aux différents fichiers lors du lancement des exécutables. Ce script est copié 
depuis le projet `pendulum-core` lors du déploiement initial et à chaque mise à jour. On peut
aussi définir un lien symbolique vers l'original au lieu d'en faire la copie, afin d'en utiliser en
permanence la dernière version.

## Mise en place

Exécutez les commandes suivantes pour la mise en place de cette structure :

```
cd $HOME
wget \
    https://github.com/Terra-Numerica/pendulum-deploy/archive/refs/heads/main.zip \
    -O pendulum-deploy-main.zip
unzip pendulum-deploy-main.zip .
```

**Important :** Attention à ne pas omettre le point en fin de commande unzip pour ne pas créer un
sous repertoire. Vérifiez bien que la structure a été créée directement à la racine du home dir.

## Initialisation des contenus

Après avoir généré les exécutables, copier les binaires dans la branche `stable/` :

```
copy devel/pendulum-core/build/{low_level_interface,demo,reset_gpio} \
    pendulum_pi/stable
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
│  └── config/
├── pendulum.sh
└── stable/
    ├── config/
    │   ├── demo.yaml
    │   └── pendule_pi_config.yaml
    ├── demo
    ├── low_level_interface
    └── reset_gpio
```

# Finalisation

Il s'agit ici d'ajouter quelques configurations permettant de rendre l'utilisation du
démonstrateur la plus simple et intuitive possible.

## Commande end-user

Pour simplifier l'utilisation de script end-user, ajouter un lien symbolique dans le chemin
de recherche par défaut du shell :

```
cd $HOME
mkdir -p .local/bin
ln -s ~/pendulum_pi/pendulum.sh .local/bin/pendulum
```

La commande `pendulum` sera ainsi accessible de n'importe où.

Pour en simplifier l'usage, créer le fichier `pendulum` (même nom que la 
commande) dans le répertoire de configuration des complétions bash :

```
mkdir -p ~/.local/share/bash-completion/completions
echo 'complete -W "start stop reset demo status help" pendulum' \
    >> .local/share/bash-completion/completions/pendulum
```

La touche <kbd>Tab</kbd> après la commande `pendulum` affichera alors les sous-commandes disponibles. 

**Note :** il faut relancer la session bash pour que ces modifications soient effectives.

## Affichage par défaut de la notice 

Afin de fournir aux animateurs les instructions de base directement à l'ouverture du terminal, 
ajouter la ligne suivante à la fin du fichier `$HOME/.bashrc`:

```
clear && cat NOTICE.txt
```

## La commande `pendulum`

Elle permet de gérer simplement les actions suivantes :

- démarrage du contrôleur de bas niveau
- lancement de la démo 
- arrêt du contrôleur

Elle dispose d'une aide en ligne :

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
