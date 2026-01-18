; =====================================================================
; PROIECT_CEAS.A51 - SIMULARE CEAS DIGITAL 8051 CU P89C51RD2
; Versiunea finala - implementare completa conform cerintei
; =====================================================================

; -------------------------------------------------------------
; 1. DEFINI?II DE CONSTANTE ?I ADRESE
; -------------------------------------------------------------

; Adrese 8255_0 (U4) - Secunde si Minute Zeci
P0_PA   EQU 8000H      ; Secunde Zeci (SZ) - AFI?AJ 1
P0_PB   EQU 8001H      ; Secunde Unitati (SU) - AFI?AJ 2
P0_PC   EQU 8002H      ; Minute Zeci (MZ) - AFI?AJ 3
P0_CC   EQU 8003H      ; Registru Comanda 8255_0

; Adrese 8255_1 (U5) - Minute Unitati si Ore
P1_PA   EQU 8004H      ; Minute Unitati (MU) - AFI?AJ 4
P1_PB   EQU 8005H      ; Ore Zeci (HZ) - AFI?AJ 5
P1_PC   EQU 8006H      ; Ore Unitati (HU) - AFI?AJ 6
P1_CC   EQU 8007H      ; Registru Comanda 8255_1

; Adrese 8253 (U6) - Generator tick-uri (simulat)
CNT0    EQU 8008H      ; Canal 0 al 8253
CNT_CC  EQU 800BH      ; Cuvant de comanda 8253

; Configuratii 8255 (Modul 0 - toate porturile iesire)
CC_8255 EQU 80H        ; PA=OUT, PB=OUT, PC=OUT

; Configuratie 8253 (Modul 2 - generator impulsuri)
CC_8253 EQU 34H        ; Canal 0, Mod 2, BCD, citire/scriere LSB then MSB

; Constante Timer0 pentru 20ms la 11.0592MHz
; Calcul: (65536 - (11059200/12 * 0.02)) = 65536 - 18432 = 47104 = B800H
TH0_VAL EQU 0B8H       ; High byte pentru 20ms
TL0_VAL EQU 00H        ; Low byte pentru 20ms

; -------------------------------------------------------------
; 2. VARIABILE IN MEMORIA INTERNA
; -------------------------------------------------------------

ORG 30H                ; Zona de date din RAM intern

; Variabile pentru ceas
SECONDE_U  DATA 30H    ; SU (0-9) - Secunde unitati
SECONDE_Z  DATA 31H    ; SZ (0-5) - Secunde zeci
MINUTE_U   DATA 32H    ; MU (0-9) - Minute unitati
MINUTE_Z   DATA 33H    ; MZ (0-5) - Minute zeci
ORE_U      DATA 34H    ; HU (0-9) - Ore unitati
ORE_Z      DATA 35H    ; HZ (0-2) - Ore zeci

; Variabile auxiliare
TICK_COUNTER DATA 36H  ; Contor pentru 50 de tick-uri (20ms * 50 = 1s)
TEMP_VAR    DATA 37H   ; Variabila temporara

; -------------------------------------------------------------
; 3. VECTORI DE INTERUPERE SI PROGRAM PRINCIPAL
; -------------------------------------------------------------

ORG 0000H
LJMP MAIN              ; Salt la programul principal

ORG 000BH              ; Vector intrerupere Timer0
LJMP TIMER0_ISR

ORG 0013H              ; Vector intrerupere INT1 (nefolosit in acest proiect)
RETI

ORG 100H               ; Start program principal

; -------------------------------------------------------------
; 4. PROGRAMUL PRINCIPAL - MAIN
; -------------------------------------------------------------

MAIN:
    ; Initializare stiva
    MOV SP, #7FH
    
    ; Initializare variabile ceas la 00:00:00
    MOV SECONDE_U, #00H
    MOV SECONDE_Z, #00H
    MOV MINUTE_U, #00H
    MOV MINUTE_Z, #00H
    MOV ORE_U, #00H
    MOV ORE_Z, #00H
    MOV TICK_COUNTER, #00H
    MOV TEMP_VAR, #00H
    
    ; Initializare periferice externe (8255)
    LCALL INIT_8255
    
    ; Initializare timer intern (Timer0)
    LCALL INIT_TIMER0
    
    ; Afisare timp initial (00:00:00)
    LCALL DISPLAY_TIME
    
    ; Bucla principala - totul se face prin intreruperi
IDLE_LOOP:
    NOP
    SJMP IDLE_LOOP

; -------------------------------------------------------------
; 5. SUBRUTINE DE INITIALIZARE
; -------------------------------------------------------------

; Subrutina: Initializare circuite 8255
INIT_8255:
    ; Configurare 8255_0 (U4) - toate porturile output
    MOV DPTR, #P0_CC
    MOV A, #CC_8255
    MOVX @DPTR, A
    
    ; Configurare 8255_1 (U5) - toate porturile output
    MOV DPTR, #P1_CC
    MOV A, #CC_8255
    MOVX @DPTR, A
    
    ; Initial stinge toate afisajele
    MOV DPTR, #P0_PA
    MOV A, #00H
    MOVX @DPTR, A
    INC DPTR          ; P0_PB
    MOVX @DPTR, A
    INC DPTR          ; P0_PC
    MOVX @DPTR, A
    MOV DPTR, #P1_PA
    MOVX @DPTR, A
    INC DPTR          ; P1_PB
    MOVX @DPTR, A
    INC DPTR          ; P1_PC
    MOVX @DPTR, A
    
    RET

; Subrutina: Initializare Timer0 pentru 20ms
INIT_TIMER0:
    ; Timer0 in modul 1 (16-bit timer)
    MOV TMOD, #01H
    
    ; Setare valori initiale pentru 20ms
    MOV TH0, #TH0_VAL
    MOV TL0, #TL0_VAL
    
    ; Activare intreruperi Timer0
    SETB ET0
    
    ; Activare intreruperi globale
    SETB EA
    
    ; Pornire Timer0
    SETB TR0
    
    RET

; -------------------------------------------------------------
; 6. TABEL CONVERSIE BCD -> 7 SEGMENTE (ANOD COMUN)
; -------------------------------------------------------------

ORG 0200H

SEG_TABLE:
    ; Cifrele 0-9 pentru afisaj 7 segmente (anod comun)
    DB 3FH    ; 0 - cod 7 segmente
    DB 06H    ; 1
    DB 5BH    ; 2
    DB 4FH    ; 3
    DB 66H    ; 4
    DB 6DH    ; 5
    DB 7DH    ; 6
    DB 07H    ; 7
    DB 7FH    ; 8
    DB 6FH    ; 9

; -------------------------------------------------------------
; 7. SUBRUTINA DE AFISARE A TIMPULUI
; -------------------------------------------------------------

DISPLAY_TIME:
    PUSH ACC
    PUSH B
    PUSH DPH
    PUSH DPL
    
    ; Punem adresa tabelului in DPTR
    MOV DPTR, #SEG_TABLE
    
    ; 1. Afisare Secunde Unitati (SU) - P0_PB (8001h)
    MOV A, SECONDE_U
    MOVC A, @A+DPTR      ; Converteste in 7 segmente
    PUSH DPH
    PUSH DPL             ; Salveaza pointerul tabel
    MOV DPTR, #P0_PB
    MOVX @DPTR, A        ; Scrie la 8255_0 port B
    POP DPL
    POP DPH              ; Restaureaza pointerul tabel
    
    ; 2. Afisare Secunde Zeci (SZ) - P0_PA (8000h)
    MOV A, SECONDE_Z
    MOVC A, @A+DPTR
    PUSH DPH
    PUSH DPL
    MOV DPTR, #P0_PA
    MOVX @DPTR, A
    POP DPL
    POP DPH
    
    ; 3. Afisare Minute Unitati (MU) - P1_PA (8004h)
    MOV A, MINUTE_U
    MOVC A, @A+DPTR
    PUSH DPH
    PUSH DPL
    MOV DPTR, #P1_PA
    MOVX @DPTR, A
    POP DPL
    POP DPH
    
    ; 4. Afisare Minute Zeci (MZ) - P0_PC (8002h)
    MOV A, MINUTE_Z
    MOVC A, @A+DPTR
    PUSH DPH
    PUSH DPL
    MOV DPTR, #P0_PC
    MOVX @DPTR, A
    POP DPL
    POP DPH
    
    ; 5. Afisare Ore Unitati (HU) - P1_PC (8006h)
    MOV A, ORE_U
    MOVC A, @A+DPTR
    PUSH DPH
    PUSH DPL
    MOV DPTR, #P1_PC
    MOVX @DPTR, A
    POP DPL
    POP DPH
    
    ; 6. Afisare Ore Zeci (HZ) - P1_PB (8005h)
    MOV A, ORE_Z
    MOVC A, @A+DPTR
    PUSH DPH
    PUSH DPL
    MOV DPTR, #P1_PB
    MOVX @DPTR, A
    POP DPL
    POP DPH
    
    POP DPL
    POP DPH
    POP B
    POP ACC
    RET

; -------------------------------------------------------------
; 8. RUTINA DE SERVICIU TIMER0 (ISR) - LOGICA CEASULUI
; -------------------------------------------------------------

TIMER0_ISR:
    PUSH ACC
    PUSH PSW
    PUSH DPH
    PUSH DPL
    
    ; Reincarcare Timer0 pentru urmatorul interval de 20ms
    MOV TH0, #TH0_VAL
    MOV TL0, #TL0_VAL
    
    ; Incrementare contor tick-uri
    INC TICK_COUNTER
    MOV A, TICK_COUNTER
    CJNE A, #50, ISR_EXIT    ; Daca nu am ajuns la 1 secunda
    
    ; S-a scurs o secunda - resetare contor
    MOV TICK_COUNTER, #00H
    
    ; ========== LOGICA INCREMENTARE TIMP ==========
    
    ; --- Incrementare secunde ---
    INC SECONDE_U
    MOV A, SECONDE_U
    CJNE A, #10, UPDATE_DISPLAY  ; Daca SU < 10
    
    ; Secunde unitati au depasit 9
    MOV SECONDE_U, #00H
    INC SECONDE_Z
    MOV A, SECONDE_Z
    CJNE A, #6, UPDATE_DISPLAY   ; Daca SZ < 6
    
    ; Secunde zeci au depasit 5 (59->00)
    MOV SECONDE_Z, #00H
    
    ; --- Incrementare minute ---
    INC MINUTE_U
    MOV A, MINUTE_U
    CJNE A, #10, UPDATE_DISPLAY  ; Daca MU < 10
    
    ; Minute unitati au depasit 9
    MOV MINUTE_U, #00H
    INC MINUTE_Z
    MOV A, MINUTE_Z
    CJNE A, #6, UPDATE_DISPLAY   ; Daca MZ < 6
    
    ; Minute zeci au depasit 5 (59->00)
    MOV MINUTE_Z, #00H
    
    ; --- Incrementare ore ---
    INC ORE_U
    MOV A, ORE_U
    CJNE A, #10, CHECK_HOURS     ; Daca HU < 10
    
    ; Ore unitati au depasit 9
    MOV ORE_U, #00H
    INC ORE_Z
    
CHECK_HOURS:
    ; Verificare daca am ajuns la 24:00:00
    MOV A, ORE_Z
    CJNE A, #2, UPDATE_DISPLAY    ; Daca HZ nu sunt 2
    
    MOV A, ORE_U
    CJNE A, #4, UPDATE_DISPLAY    ; Daca HU nu sunt 4
    
    ; Reset la 00:00:00 (24:00:00 -> 00:00:00)
    MOV ORE_Z, #00H
    MOV ORE_U, #00H
    
UPDATE_DISPLAY:
    ; Actualizare afisaj
    LCALL DISPLAY_TIME
    
ISR_EXIT:
    POP DPL
    POP DPH
    POP PSW
    POP ACC
    RETI

; -------------------------------------------------------------
; 9. SUBRUTINA SIMULARE 8253 (OPTIONALA - pentru debugging)
; -------------------------------------------------------------

; Aceasta subrutina simuleaza functionalitatea 8253
; In realitate, 8253 ar genera intreruperi la fiecare tick
SIMULATE_8253:
    PUSH ACC
    PUSH DPTR
    
    ; Simulare scriere comanda 8253
    MOV DPTR, #CNT_CC
    MOV A, #CC_8253
    MOVX @DPTR, A
    
    ; Simulare scriere valoare in canalul 0
    ; Pentru debugging, putem scrie o valoare care sa fie citita mai tarziu
    MOV DPTR, #CNT0
    MOV A, #50           ; Valoarea 50 pentru 50 de tick-uri/secunda
    MOVX @DPTR, A
    
    POP DPTR
    POP ACC
    RET

; -------------------------------------------------------------
; 10. SFARSIT PROGRAM
; -------------------------------------------------------------

END