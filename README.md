# 8051 Digital Clock System - P89C51RD2 Implementation

[![Embedded Systems](https://img.shields.io/badge/Focus-Embedded%20Systems-orange.svg)](#)
[![Assembly](https://img.shields.io/badge/Language-Assembly%208051-blue.svg)](#)
[![Hardware](https://img.shields.io/badge/Hardware-Intel%208051%20/%208255%20/%208253-red.svg)](#)

## 📌 Descriere Proiect
Acest proiect cuprinde implementarea la nivel de registru a unui **sistem de ceas digital în timp real**, dezvoltat pentru microcontrolerul **P89C51RD2**. Proiectul demonstrează gestionarea precisă a timpului prin întreruperi hardware, interfațarea cu periferice de expansiune (Intel 8255) și controlul afișajelor cu 7 segmente prin maparea memoriei externe.

Sistemul respectă constrângerile de temporizare impuse de un cristal de cuarț de **11.0592 MHz**, asigurând o eroare de calcul zero pentru baza de timp.

## 🛠️ Specificații Tehnice & Arhitectură
* **Microcontroler:** P89C51RD2 (Arhitectură 8051).
* **Limbaj de programare:** ASM (Assembly 8051).
* **Gestiunea Timpului:** Utilizarea **Timer 0** în Modul 1 (16-bit) pentru generarea de tick-uri de 20ms.
* **Interfațare Periferice:**
    * **2x Intel 8255 (PPI):** Utilizate pentru extinderea porturilor I/O și controlul celor 6 unități de afișaj.
    * **Intel 8253 (PIT):** Configurat pentru generare de semnal (simulare hardware).
* **Afișaj:** 6 unități 7-segmente (Anod Comun) organizate în format `HH:MM:SS`.

### 🧮 Calcul Temporizare (Timer 0)
Pentru a obține un interval de exact **20ms** (50 Hz) necesar bazei de timp:
* **Frecvență tact:** $11.0592 \text{ MHz} / 12 = 921.6 \text{ kHz}$
* **Perioadă instrucțiune:** $\approx 1.085 \text{ \mu s}$
* **Valoare încărcare (Decimal):** $65536 - (0.02 / 1.085 \times 10^{-6}) = 47104$
* **Valoare Hexazecimală:** `B800H` (încărcată în `TH0` și `TL0`)



## 📂 Structura Registrelor și Adresare
Sistemul utilizează **External Memory Mapping** (XDATA) pentru controlul perifericelor:

| Periferic | Adresă Hardware | Funcție |
| :--- | :--- | :--- |
| **8255_0 (U4)** | `8000H - 8003H` | Control Secunde (Z/U) și Minute (Z) |
| **8255_1 (U5)** | `8004H - 8007H` | Control Minute (U) și Ore (Z/U) |
| **8253 (U6)** | `8008H - 800BH` | Canal 0 - Generator de tact |



## 🚀 Implementare Software
Programul este structurat modular pentru a asigura o execuție eficientă:

1.  **Vectori de Întrerupere:** Logica principală este tratată în rutina de serviciu `TIMER0_ISR`.
2.  **Logica de Tact:** Un contor software (`TICK_COUNTER`) cumulează 50 de iterații de 20ms pentru a genera o secundă.
3.  **Conversie BCD în 7-Segmente:** Utilizarea unui tabel de tip *Look-up Table* (`SEG_TABLE`) stocat în memoria de cod, accesat prin instrucțiunea `MOVC`.
4.  **Protecția Contextului:** Salvarea riguroasă a registrelor `ACC`, `PSW`, `DPH` și `DPL` în stivă pentru a preveni erorile de procesare la revenirea din întrerupere.

## 🔧 Metodologie de Testare (Keil uVision)
Verificarea funcționării se realizează prin simulatorul integrat din Keil, monitorizând magistrala de date externă:

1. **Configurare:** Setați procesorul la **NXP P89C51RD2** și frecvența la **11.0592 MHz**.
2. **Debug Mode:** Intrați în simulator (Ctrl+F5).
3. **Monitorizare:** Deschideți **Memory Window** și introduceți adresa `X:0x8000`.
4. **Validare:** Valorile hexazecimale de la adresele perifericelor se vor actualiza automat, reprezentând codurile de segment pentru trecerea timpului (ex: `3FH` pentru cifra 0).



## 📈 Optimizări Incluse
* **Afișare Directă:** Utilizarea instrucțiunilor `MOVX` pentru comunicarea rapidă cu perifericele mapate în memorie.
* **Stabilitate:** Resetare automată la `24:00:00` și gestionarea corectă a transferului (carry) între unități și zeci pentru secundar, minutar și orar.

---
© 2025 - Proiect dezvoltat de **Otelariu Teodora**