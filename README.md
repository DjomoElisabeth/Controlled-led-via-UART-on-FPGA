Ce projet permet de contrôler une LED connectée à une carte FPGA via une interface utilisateur développée en Python avec Tkinter. Il utilise une communication UART pour envoyer et recevoir des commandes entre l'IHM et la carte.

 # Fonctionnalités
- Allumer ou éteindre une LED via des commandes UART.
- Interface utilisateur graphique intuitive développée avec Tkinter.
- Affichage en temps réel de l'état de la LED (ON, OFF, ou Inconnu).

# Plateforme de Test
Ce projet a été testé sur la carte FPGA suivante :

- Carte utilisée : CMOD A7 35T**
- Fabricant : Digilent
  - FPGA : Xilinx Artix-7 XC7A35T
  - Ressources :
    - [Documentation officielle](https://digilent.com/reference/programmable-logic/cmod-a7/start)
    - [Guide de l'utilisateur (User Guide)](https://digilent.com/reference/_media/programmable-logic/cmod-a7/cmod_a7_rm.pdf)

Cette carte FPGA compacte, idéale pour les projets nécessitant une communication UART, dispose des caractéristiques suivantes :
- FPGA Artix-7 avec 33 280 cellules logiques.
- 44 broches GPIO, compatibles avec les systèmes externes.
- Port UART pour la communication série.

Ce projet peut également être adapté pour d'autres cartes FPGA avec un port UART.


Ce projet peut être adapté pour d'autres cartes FPGA avec un port UART.

 Interface Utilisateur : Thonny
L'IHM a été développée et testée avec Thonny (éditeur Python).

 # Installation de Thonny
1. Téléchargez et installez Thonny depuis : [https://thonny.org](https://thonny.org).
2. Lancez Thonny et ouvrez le fichier `main.py`.
3. Exécutez le script pour démarrer l'IHM.

 # Compatibilité
 FPGA
Le projet est conçu pour des cartes FPGA disposant d'un port UART. Des modifications peuvent être nécessaires pour des plateformes différentes.

 # Python
- Testé avec Python 3.7.
- Bibliothèques utilisées : `serial`, `tkinter`.

 # Fonctionnement
1. Carte FPGA :
   - Recevoir des commandes via UART :
     - `N` : Allumer la LED.
     - `F` : Éteindre la LED.
     - `S` : Demander l'état de la LED.
   - Répondre à l'IHM avec l'état actuel (ON/OFF).

2. Application Python :
   - Interface utilisateur développée avec Tkinter.
   - Envoi des commandes et affichage des réponses en temps réel.

Diagramme de communication

plaintext
+-------------+                +----------------+
|  Python IHM | --(UART)--->  |    FPGA UART    |
+-------------+                +----------------+
