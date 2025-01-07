# LED Contrôlée via UART sur FPGA

## Description
Ce projet implémente un système basé sur un FPGA permettant de contrôler une LED à l'aide de commandes UART.
Les commandes envoyées via une interface série permettent d'allumer/éteindre une LED et de demander son état actuel.

## Fonctionnalités
- **Commandes disponibles :**
  - `N` : Allumer la LED
  - `F` : Éteindre la LED
  - `S` : Demander l'état actuel de la LED (ON ou OFF)

## Matériel Requis
- FPGA : Digilent Cmod A7 (Artix-7)
- Horloge à 12 MHz
- Interface USB-UART (par exemple, un adaptateur FTDI)

## Logiciels Requis
- Python 3.x
- IDE Thonny (pour envoyer les commandes via UART)
- Vivado (ou un autre outil de synthèse FPGA)

## Instructions
1. **Configurer le matériel :**
   - Charger le bitstream sur le FPGA en utilisant Vivado.
   - Connecter l'adaptateur USB-UART au port série correspondant.

2. **Configurer le logiciel :**
   - Utiliser le script Python fourni (avec Thonny) pour envoyer des commandes UART.

3. **Tester les fonctionnalités :**
   - Envoyer les commandes `N`, `F` ou `S` pour observer l'état de la LED.
   - La LED s'allume/s'éteint selon la commande, et une réponse (`N`, `F`) est envoyée via UART.

