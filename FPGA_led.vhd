library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.UART_Communication_pkg.all;  -- Mise à jour pour utiliser le nouveau package

entity FPGA_led is
    port (
        clk_12mhz    : in  std_logic;  -- Horloge principale à 12 MHz
        reset        : in  std_logic;  -- Réinitialisation globale
        rx_serial    : in  std_logic;  -- Entrée série (UART)
        led_output   : out std_logic;  -- Sortie LED (ON/OFF)
        tx_serial    : out std_logic   -- Sortie série (UART)
    );
end FPGA_led;

architecture Behavioral of FPGA_led is

    -- Signaux internes pour la communication entre les composants
    signal tx_data_ready    : std_logic;  -- Données prêtes pour la transmission
    signal tx_data          : std_logic_vector(7 downto 0);  -- Données transmises

    signal rx_data          : std_logic_vector(7 downto 0);  -- Données reçues
    signal command_ready    : std_logic;  -- Indique que des données sont prêtes à être traitées

begin

    -- Composant pour la réception UART
    uart_receive : UART_Receiver
        generic map (
            CLKS_PER_BIT => 1250  -- Pour 12 MHz horloge à 9600 bps
        )
        port map (
            clk           => clk_12mhz,  -- Horloge principale
            reset         => reset,  -- Signal de réinitialisation
            rx_serial     => rx_serial,  -- Entrée série UART
            led_output    => led_output,  -- Contrôle de la LED
            data_ready    => command_ready,  -- Signale que des données sont prêtes
            received_byte => rx_data  -- Données reçues
        );

    -- Composant de contrôle des données entre réception et émission
    uart_control : UART_Controller
        port map (
            clk             => clk_12mhz,  -- Horloge principale
            clear_ctrl      => reset,  -- Réinitialisation
            data_in         => rx_data,  -- Données entrantes depuis le récepteur
            data_in_ready   => command_ready,  -- Indique que des données sont prêtes à être traitées
            data_out_ready  => tx_data_ready,  -- Signale que des données sont prêtes à être transmises
            data_out        => tx_data  -- Données prêtes pour l'émission
        );

    -- Composant pour l'émission UART
    uart_transmit : UART_Transmitter
        generic map (
            CLKS_PER_BIT => 1250  -- Pour 12 MHz horloge à 9600 bps
        )
        port map (
            clk           => clk_12mhz,  -- Horloge principale
            clear_emitter => reset,  -- Réinitialisation
            data_out_ready=> tx_data_ready,  -- Données prêtes à être transmises
            data_out      => tx_data,  -- Données transmises
            tx_serial     => tx_serial  -- Sortie série UART
        );

end Behavioral;
