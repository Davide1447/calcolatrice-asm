format PE64 console
entry start
include 'win64a.inc'

section '.text' code readable executable

start:
    sub rsp, 40h                    ; 32 bytes shadow space + 8 bytes allineamento

    lea rcx, [msg]
    call [printf]                   ; messaggio di benvenuto

    lea rcx, [formatosafe]          ; format string %10s (protezione overflow)
    lea rdx, [utente]
    call [scanf]

    ; controllo overflow: se l'utente ha inserito più di 10 caratteri
    ; il byte all'offset 10 non sarà zero allora esci
    lea rdx, [utente]
    cmp BYTE [rdx+0Ah], 0h
    jne quit

antidebugchecks:

    ; Controllo vendor CPU (rilevamento VM)
    mov rax, 0
    cpuid
    mov [cpuiddata],   ebx
    mov [cpuiddata+4], edx
    mov [cpuiddata+8], ecx

    mov eax, [cpuiddata]
    cmp eax, 61774D56h              ; "VMwa" -> VMware
    je quit
    cmp eax, 786F4256h              ; "VBox" -> VirtualBox
    je quit

    ; Controllo debugger
    xor rax, rax
    call [IsDebuggerPresent]
    test al, al
    jne quit

    ; Leggi il nome utente completo
    lea rcx, [formatos]
    lea rdx, [utente]
    call [scanf]

    ; Mostra menu
    lea rcx, [benv]
    lea rdx, [utente]
    call [printf]

    ; Leggi la scelta
    lea rcx, [formatos]
    lea rdx, [utente]
    call [scanf]

    cmp BYTE [utente], 49           ; '1' -> Addizione
    jz addizione
    cmp BYTE [utente], 50           ; '2' -> Moltiplicazione
    jz moltiplicazione
    cmp BYTE [utente], 51           ; '3' -> Divisione
    jz divisione
    cmp BYTE [utente], 52           ; '4' -> Sottrazione
    jz sottrazione
    jmp quit                        ; scelta non valida

; ---------------------------------------------
quit:
    lea rcx, [sgamato]
    call [printf]
    xor ecx, ecx
    call [ExitProcess]

; ---------------------------------------------
addizione:
    sub rsp, 40h

    lea rcx, [str_addizione]
    call [printf]

    lea rcx, [formatod]
    lea rdx, [numero1]
    call [scanf]

    lea rcx, [str_secondo]
    call [printf]

    lea rcx, [formatod]
    lea rdx, [numero2]
    call [scanf]

    mov rax, [numero1]
    mov rdx, [numero2]
    add rax, rdx
    mov [numero3], rax

    lea rcx, [risultatop]
    mov rdx, [numero3]
    call [printf]

    mov rcx, 2000h
    call [Sleep]

    add rsp, 40h
    jmp quit                        ; jmp evita fall-through in moltiplicazione

; ---------------------------------------------
moltiplicazione:
    sub rsp, 40h

    lea rcx, [strmol]
    call [printf]

    lea rcx, [formatod]
    lea rdx, [num1molt]
    call [scanf]

    lea rcx, [str_secondo]
    call [printf]

    lea rcx, [formatod]
    lea rdx, [num2molt]
    call [scanf]

    xor eax, eax
    xor ecx, ecx
    mov rax, [num1molt]
    mov rcx, [num2molt]
    mul rcx                         ; risultato senza segno in rdx:rax
    mov [risulmol], rax

    lea rcx, [risultatop]
    mov rdx, [risulmol]
    call [printf]

    add rsp, 40h
    jmp quit                     

; ---------------------------------------------
divisione:
    sub rsp, 40h                 

    lea rcx, [strdiv]
    call [printf]

    lea rcx, [formatod]
    lea rdx, [num1div]
    call [scanf]

    lea rcx, [str_secondo]
    call [printf]

    lea rcx, [formatod]
    lea rdx, [num2div]
    call [scanf]

    ; Controllo divisione per zero
    mov rbx, [num2div]
    test rbx, rbx
    jz divisione_zero

    mov rax, [num1div]
    cqo                             ; estende il segno di rax in rdx
    div rbx                         ; quoziente in rax, resto in rdx
    mov [risultatodiv], rax

    lea rcx, [risultatop]
    mov rdx, [risultatodiv]
    call [printf]

    add rsp, 40h
    jmp quit

divisione_zero:
    lea rcx, [str_divzero]
    call [printf]
    add rsp, 40h
    jmp quit

; ---------------------------------------------
sottrazione:
    sub rsp, 40h                   

    lea rcx, [sottrazi]
    call [printf]

    lea rcx, [formatod]
    lea rdx, [num1sub]
    call [scanf]

    lea rcx, [sottrazi2]
    call [printf]

    lea rcx, [formatod]
    lea rdx, [num2sub]
    call [scanf]

    mov rax, [num1sub]
    mov rdx, [num2sub]
    sub rax, rdx
    mov [risultatosub], rax

    lea rcx, [risultatop]           
    mov rdx, [risultatosub]
    call [printf]

    add rsp, 40h
    jmp quit

; -----------------------------------------------
section '.data' data readable writeable
; db  Define Byte        1 byte  / 8 bit
; dw  Define Word        2 byte  / 16 bit
; dd  Define Doubleword  4 byte  / 32 bit
; dq  Define Quadword    8 byte  / 64 bit

    msg           db 'Benvenuto nella calcolatrice! Inserisci il tuo nome:', 10, 0
    benv          db 'Ciao %s! Cosa vuoi fare?  1) Addizione  2) Moltiplicazione  3) Divisione  4) Sottrazione', 10, 0
    str_addizione db 'Addizione: inserisci il primo numero:', 10, 0
    str_secondo   db 'Inserisci il secondo numero:', 10, 0
    strmol        db 'Moltiplicazione: inserisci il primo numero:', 10, 0
    strdiv        db 'Divisione: inserisci il dividendo:', 10, 0
    sottrazi      db 'Sottrazione: inserisci il primo numero:', 10, 0
    sottrazi2     db 'Inserisci il numero da sottrarre:', 10, 0
    risultatop    db 'Risultato: %lld', 10, 0
    str_divzero   db 'Errore: divisione per zero!', 10, 0
    sgamato       db 'Accesso negato. Processo terminato.', 10, 0
    formatos      db '%s', 0
    formatod      db '%lld', 0
    formatosafe   db '%10s', 0

    utente        rb 32

    numero1       dq 0
    numero2       dq 0
    numero3       dq 0
    num1molt      dq 0
    num2molt      dq 0
    risulmol      dq 0
    num1div       dq 0
    num2div       dq 0
    risultatodiv  dq 0
    num1sub       dq 0
    num2sub       dq 0
    risultatosub  dq 0
    cpuiddata     dd 0, 0, 0, 0

section '.idata' import data readable writeable
    library kernel32, 'KERNEL32.DLL', \
            msvcrt,   'MSVCRT.DLL'

    import kernel32, ExitProcess, 'ExitProcess', Sleep, 'Sleep', IsDebuggerPresent, 'IsDebuggerPresent'
    import msvcrt, printf, 'printf', scanf, 'scanf'
