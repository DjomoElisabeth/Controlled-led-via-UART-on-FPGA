library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

package UART_Communication_pkg is

    -- Composant pour la réception UART
    component UART_Receiver
        generic (
            CLKS_PER_BIT : integer := 1250  -- Nombre de cycles horloge pour un bit (12 MHz horloge à 9600 bps)
        );
        port (
            clk             : in  std_logic;  -- Horloge principale 12 MHz
            reset           : in  std_logic;  -- Réinitialisation
            rx_serial       : in  std_logic;  -- Entrée série (UART)
            led_output      : out std_logic;  -- Sortie LED (allumé ou éteint)
            data_ready      : out std_logic;  -- Indique que des données sont prêtes à être envoyées
            received_byte   : out std_logic_vector(7 downto 0)  -- Données reçues (octet UART)
        );
    end component;

    -- Composant de contrôle des données entre RX et TX
    component UART_Controller
        port (
            clk             : in  std_logic;  -- Horloge principale 12 MHz
            clear_ctrl           : in  std_logic;  -- Signal de réinitialisation
            data_in         : in  std_logic_vector(7 downto 0);  -- Données entrantes
            data_in_ready   : in  std_logic;  -- Indique que des données sont prêtes à être traitées
            data_out_ready  : out std_logic;  -- Indique que des données sont prêtes à être envoyées
            data_out        : out std_logic_vector(7 downto 0)  -- Données sortantes
        );
    end component;

    -- Composant pour l'émission UART
    component UART_Transmitter
        generic (
            CLKS_PER_BIT : integer := 1250  -- Nombre de cycles horloge pour un bit (12 MHz horloge à 9600 bps)
        );
        port (
            data_out_ready  : in  std_logic;  -- Indique que des données sont prêtes à être transmises
            clear_emitter           : in  std_logic;  -- Signal de réinitialisation
            data_out        : in  std_logic_vector(7 downto 0);  -- Données à transmettre
            tx_serial       : out std_logic;  -- Sortie série (UART)
            clk             : in  std_logic   -- Horloge principale 12 MHz
        );
    end component;

end package UART_Communication_pkg;


library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

entity UART_Receiver is
    generic (
        CLKS_PER_BIT : integer := 1250  -- Nombre de cycles horloge pour un bit (12 MHz horloge à 9600 bps)
    );
    port (
        clk             : in  std_logic;  -- Horloge principale 12 MHz
        reset           : in  std_logic;  -- Réinitialisation
        rx_serial       : in  std_logic;  -- Entrée série UART
        led_output      : out std_logic;  -- Indique l'état de la LED (ON/OFF)
        data_ready      : out std_logic;  -- Indique que des données sont prêtes à être envoyées
        received_byte   : out std_logic_vector(7 downto 0)  -- Octet reçu
    );
end UART_Receiver;

architecture Behavioral of UART_Receiver is

    -- États de la machine d'état pour le module RX
    type rx_state_type is (Idle, Start_Bit, Receiving_Data, Stop_Bit, Cleanup);
    signal rx_state        : rx_state_type := Idle;  -- État actuel

    signal rx_serial_sync  : std_logic := '1';  -- Signal série synchronisé
    signal bit_clk_count   : integer range 0 to CLKS_PER_BIT-1 := 0;  -- Compteur pour générer le timing UART
    signal bit_index       : integer range 0 to 7 := 0;  -- Index pour parcourir les bits de l'octet
    signal rx_byte         : std_logic_vector(7 downto 0) := (others => '0');  -- Octet reçu
    signal rx_data_ready   : std_logic := '0';  -- Indique que des données sont prêtes

    signal led_state       : std_logic := '0';  -- État interne de la LED
    signal received_data   : std_logic_vector(7 downto 0) := (others => '0');  -- Données reçues finales

begin

    -- Machine d'état UART RX
    process (clk, reset)
    begin
        if reset = '1' then
            rx_state <= Idle;
            rx_data_ready <= '0';
            bit_clk_count <= 0;
            bit_index <= 0;
            rx_byte <= (others => '0');
        elsif rising_edge(clk) then
            case rx_state is
                when Idle =>
                    rx_data_ready <= '0';  -- Réinitialisation des données prêtes
                    bit_clk_count <= 0;    -- Réinitialisation du compteur
                    bit_index <= 0;        -- Réinitialisation de l'index des bits

                    if rx_serial = '0' then  -- Détection du bit de Start
                        rx_state <= Start_Bit;
                    end if;

                when Start_Bit =>
                    if bit_clk_count = (CLKS_PER_BIT-1)/2 then
                        if rx_serial = '0' then
                            bit_clk_count <= 0;
                            rx_state <= Receiving_Data;  -- Passe à la réception des données
                        else
                            rx_state <= Idle;  -- Retour à l'état d'attente en cas d'erreur
                        end if;
                    else
                        bit_clk_count <= bit_clk_count + 1;
                    end if;

                when Receiving_Data =>
                    if bit_clk_count < CLKS_PER_BIT-1 then
                        bit_clk_count <= bit_clk_count + 1;
                    else
                        bit_clk_count <= 0;  -- Réinitialisation du compteur pour chaque bit
                        rx_byte(bit_index) <= rx_serial;  -- Stocke le bit reçu
                        if bit_index < 7 then
                            bit_index <= bit_index + 1;  -- Passe au bit suivant
                        else
                            rx_state <= Stop_Bit;  -- Passe à l'état de réception du bit de Stop
                        end if;
                    end if;

                when Stop_Bit =>
                    if bit_clk_count = CLKS_PER_BIT-1 then
                        rx_state <= Cleanup;  -- Passe à l'état de nettoyage
                        rx_data_ready <= '1';  -- Indique que les données sont prêtes
                    else
                        bit_clk_count <= bit_clk_count + 1;
                    end if;

                when Cleanup =>
                    rx_state <= Idle;  -- Retour à l'état d'attente
                    rx_data_ready <= '0';  -- Réinitialisation du signal de données prêtes

            end case;
        end if;
    end process;

    -- Traitement des commandes reçues
    process (clk, reset)
    begin
        if reset = '1' then
            led_state <= '0';  -- LED éteinte par défaut
        elsif rising_edge(clk) then
            if rx_data_ready = '1' then
                case rx_byte is
                    when "01001110" =>  -- ASCII 'N' (ON)
                        led_state <= '1';  -- Allumer la LED
                       
                        data_ready <= '0';
                    when "01000110" =>  -- ASCII 'F' (OFF)
                        led_state <= '0';  -- Éteindre la LED
                      
			            data_ready <= '0';
                    when "01010011" =>  -- ASCII 'S' (STATE)
                      
                        -- Note : La commande 'S' déclenche la transmission de l'état ailleurs
                       data_ready <= '1';
                       if led_state = '1' then
                         received_data <= "01001110";  -- Stocker la commande 'N'
                       else
                        received_data <= "01000110";  -- Stocker la commande 'F'
                       end if;
                                                   
                    when others =>
                        received_data <= (others => '0');  -- Aucune commande valide reçue
			            data_ready <= '0';
                end case;
            end if;
        end if;
    end process;

    -- Assignations des sorties
    led_output <= led_state;
    received_byte <= received_data;  -- Octet reçu

end Behavioral;

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

entity UART_Controller is
    port (
        clk             : in  std_logic;  -- Horloge principale 12 MHz
        clear_ctrl      : in  std_logic;  -- Signal de réinitialisation
        data_in         : in  std_logic_vector(7 downto 0);  -- Données entrantes
        data_in_ready   : in  std_logic;  -- Indique que des données sont prêtes à être traitées
        data_out_ready  : out std_logic;  -- Indique que des données sont prêtes à être transmises
        data_out        : out std_logic_vector(7 downto 0)  -- Données à transmettre
    );
end UART_Controller;

architecture Behavioral of UART_Controller is
begin
    -- Processus principal de contrôle des données
    process (clk, clear_ctrl)
    begin
        if clear_ctrl = '1' then
            data_out_ready <= '0';  -- Réinitialise la disponibilité des données en sortie
            data_out <= (others => '0');  -- Réinitialise les données en sortie
        elsif rising_edge(clk) then
            data_out_ready <= data_in_ready;  -- Transfère l'indicateur de disponibilité des données
            data_out <= data_in;  -- Transfère les données reçues à la sortie
        end if;
    end process;

end Behavioral;


library ieee;
use ieee.std_logic_1164.ALL;

entity UART_Transmitter is
    generic (
        CLKS_PER_BIT : integer := 1250  -- Nombre de cycles horloge pour un bit (12 MHz horloge à 9600 bps)
    );
    port (
        data_out_ready  : in  std_logic;  -- Indique que des données sont prêtes à être transmises
        clear_emitter   : in  std_logic;  -- Signal de réinitialisation
        data_out        : in  std_logic_vector(7 downto 0);  -- Données à transmettre
        tx_serial       : out std_logic;  -- Sortie série (UART)
        clk             : in  std_logic   -- Horloge principale 12 MHz
    );
end UART_Transmitter;

architecture Behavioral of UART_Transmitter is
    -- États de la machine d'état pour le module TX
    type tx_state_type is (Idle, Start_Bit, Transmitting_Data, Stop_Bit);
    signal tx_state       : tx_state_type := Idle;  -- État actuel

    signal bit_clk_count  : integer range 0 to CLKS_PER_BIT-1 := 0;  -- Compteur pour générer le timing UART
    signal bit_index      : integer range 0 to 7 := 0;  -- Index pour parcourir les bits de l'octet
    signal tx_byte        : std_logic_vector(7 downto 0) := (others => '0');  -- Octet à transmettre
begin

    -- Machine d'état UART TX
    process (clk, clear_emitter)
    begin
        if clear_emitter = '1' then
            tx_state <= Idle;
            tx_serial <= '1';  -- Ligne UART à l'état haut au repos
            bit_clk_count <= 0;
            bit_index <= 0;
            tx_byte <= (others => '0');
        elsif rising_edge(clk) then
            case tx_state is
                when Idle =>
                    tx_serial <= '1';  -- Ligne UART à l'état haut au repos
                    bit_clk_count <= 0;
                    bit_index <= 0;
                    if data_out_ready = '1' then
                        tx_byte <= data_out;  -- Charge les données à transmettre
                        tx_state <= Start_Bit;
                    end if;

                when Start_Bit =>
                    tx_serial <= '0';  -- Envoi du bit de Start (0)
                    if bit_clk_count < CLKS_PER_BIT-1 then
                        bit_clk_count <= bit_clk_count + 1;
                    else
                        bit_clk_count <= 0;
                        tx_state <= Transmitting_Data;
                    end if;

                when Transmitting_Data =>
                    tx_serial <= tx_byte(bit_index);  -- Envoi du bit courant
                    if bit_clk_count < CLKS_PER_BIT-1 then
                        bit_clk_count <= bit_clk_count + 1;
                    else
                        bit_clk_count <= 0;
                        if bit_index < 7 then
                            bit_index <= bit_index + 1;  -- Passe au bit suivant
                        else
                            tx_state <= Stop_Bit;  -- Passe à l'envoi du bit de Stop
                        end if;
                    end if;

                when Stop_Bit =>
                    tx_serial <= '1';  -- Envoi du bit de Stop (1)
                    if bit_clk_count < CLKS_PER_BIT-1 then
                        bit_clk_count <= bit_clk_count + 1;
                    else
                        bit_clk_count <= 0;
                        tx_state <= Idle;  -- Retour à l'état de repos
                    end if;

                when others =>
                    tx_state <= Idle;  -- Par défaut, retourne à l'état de repos
            end case;
        end if;
    end process;

end Behavioral;


