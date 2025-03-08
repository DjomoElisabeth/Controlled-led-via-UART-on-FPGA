import tkinter as tk
from tkinter import messagebox
import serial

# Configuration du port série
SERIAL_PORT = "COM7"  # Remplacez par votre port série
BAUD_RATE = 9600

try:
    ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1)
except serial.SerialException as e:
    messagebox.showerror("Erreur Série", f"Impossible d'ouvrir le port série : {e}")
    ser = None

def send_command(command):
    if ser:
        try:
            ser.write(f"{command}\n".encode())
        except Exception as e:
            messagebox.showerror("Erreur Série", f"Erreur lors de l'envoi : {e}")
    else:
        messagebox.showerror("Erreur Série", "Port série non configuré.")

# Fonction pour lire l'état de la LED (commande 'S')
def read_state():
    if ser:
        ser.write(b"S\n")  # Envoyer la commande 'S'
        response = ser.readline()  # Lire tout ce qui est reçu
        
        try:
            response = response.decode().strip()  # Décodage en texte
            if response:  # Vérifiez que la réponse n'est pas vide
                if response == "N":  # Si la réponse est 'N', afficher ON
                    update_state_text("État de la LED : ", "ON", "green")
                elif response == "F":  # Si la réponse est 'F', afficher OFF
                    update_state_text("État de la LED : ", "OFF", "red")
                else:
                    # Si une réponse inattendue est reçue
                    update_state_text("Réponse inattendue : ", response, "orange")
            else:
                # Cas où aucune réponse n'est reçue
                update_state_text("État de la LED : ", "Inconnu", "yellow")
        except Exception as e:
            update_state_text("Erreur : ", "Décodage impossible", "red")
    else:
        messagebox.showerror("Erreur Série", "Port série non configuré.")

def update_state_text(prefix, state, color):
    state_text_box.delete("1.0", tk.END)
    state_text_box.insert(tk.END, prefix, "default")
    state_text_box.insert(tk.END, state, color)

# Interface graphique avec Tkinter
root = tk.Tk()
root.title("Contrôle LED via FPGA")
root.geometry("400x200")  # Taille réduite : largeur=400, hauteur=300
root.configure(bg="black")  # Fond noir

title = tk.Label(
    root,
    text="Contrôlez votre LED FPGA",
    font=("Helvetica", 14, "bold"),
    fg="white",
    bg="black"
)
title.pack(pady=5)  # Réduction du padding vertical

btn_on = tk.Button(
    root,
    text="Allumer la LED",
    font=("Helvetica", 12),
    bg="#4caf50",
    fg="white",
    activebackground="#45a049",
    relief="raised",
    command=lambda: send_command("N")
)
btn_on.pack(pady=5, ipadx=5, ipady=2)

btn_off = tk.Button(
    root,
    text="Éteindre la LED",
    font=("Helvetica", 12),
    bg="#f44336",
    fg="white",
    activebackground="#e53935",
    relief="raised",
    command=lambda: send_command("F")
)
btn_off.pack(pady=5, ipadx=5, ipady=2)

btn_state = tk.Button(
    root,
    text="Demander l'état",
    font=("Helvetica", 12),
    bg="#2196f3",
    fg="white",
    activebackground="#1976d2",
    relief="raised",
    command=read_state
)
btn_state.pack(pady=5, ipadx=5, ipady=2)

state_text_box = tk.Text(
    root,
    height=1,
    width=60,
    font=("Helvetica", 12),
    bg="grey",
    fg="black",
    bd=0
)
state_text_box.tag_configure("green", foreground="green")
state_text_box.tag_configure("red", foreground="red")
state_text_box.tag_configure("yellow", foreground="yellow")
state_text_box.tag_configure("orange", foreground="orange")
state_text_box.tag_configure("default", foreground="white")
state_text_box.pack(pady=5)

def on_closing():
    if ser:
        ser.close()
    root.destroy()

root.protocol("WM_DELETE_WINDOW", on_closing)
root.mainloop()
