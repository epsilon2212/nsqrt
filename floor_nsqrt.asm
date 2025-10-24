section .text
global nsqrt

; void nsqrt(uint64_t *Q, uint64_t *X, unsigned n)
; Q = RDI, X = RSI, n = RDX
nsqrt:
    push rbp
    mov rbp, rsp
    push r12
    ; test czy Q, X != NULL
    test rdi, rdi
    je wyjdz_z_j            ; jesli Q = null, wyjdz
    test rsi, rsi
    je wyjdz_z_j            ; jesli X = null, wyjdz
    ; test czy n != 0
    test rdx, rdx
    je wyjdz_z_j            ; jesli n = 0, wyjdz

    mov rax, rdx
    and rax, 63             ; rax = n mod 64
    test rax, rax
    jne wyjdz_z_j           ; jesli n mod 64 != 0, wyjdz

    xor rax, rax
    xor rcx, rcx
    xor r8, r8
    xor r9, r9
    xor r10, r10
    xor r11, r11
    xor r12, r12
wyzeruj_Q:
    mov rax, rdi             ; rax = Q
    mov r8d, edx             ; r8 = n
    shr r8d, 6               ; r8 = n/64

wyzeruj_Q_petla:
    cmp r8d, 0
    je rozpocznij_algorytm

    mov qword [rax], 0
    add rax, 8
    dec r8d
    jmp wyzeruj_Q_petla
    
rozpocznij_algorytm:
    xor rax, rax
    mov r11, 1              ; j = 1

j_petla:
    ; Glowna petla odpowiadajaca za iteracyjne obliczanie wyniku
    cmp r11, rdx
    jg wyjdz_z_j

    mov eax, edx            ; eax = n
    shl eax, 1              ; eax = 2n
    dec eax                 ; eax = 2n - 1

    mov r10, 2

    ; rejestr eax (rax) bedzie licznikiem pętli i
    ; petla i jest odpowiedzialna za stwierdzenie, ktora liczba jest wieksza
    ; R_j-1 czy T_j-1. Bedziemy porownywac od najstaszego bitu
    ; r10 to rejestr w ktorym trzymamy informacje o rownosci liczb R i t
    ; r10 = 2 - liczby R, T rowne
    ; r10 = 1 - liczba R wieksza od T
    ; r10 = 0 - liczba R mniejsza od T

i_petla:
    cmp eax, 0
    jl wyjdz_z_i

    ; Wyliczamy bit z T
    mov ecx, edx            ; ecx = n
    sub ecx, r11d           ; ecx = n - j
    shl ecx, 1              ; ecx = 2(n - j)

    cmp eax, ecx            ; czy i == 2(n - j)
    je ustaw_bit_T_na_1     ; jesli tak, to bit T jest ustawiony
    jl ustaw_bit_T_na_0     ; jesli i < 2(n - j), to bit T jest wyzerowany

    mov ecx, edx            ; ecx = n
    shl ecx, 1              ; ecx = 2n
    sub ecx, r11d           ; ecx = 2n - j

    cmp eax, ecx            ; czy i == 2n - j
    jg ustaw_bit_T_na_0     ; jesli i > 2n - j, to bit T jest wyzerowany

    ; jezeli dotad nie zostal wykonany skok warunkowy, to znaczy ze
    ; i jest w przedziale (2n - 2j; 2n - j]

    mov ecx, edx            ; ecx = n
    sub ecx, r11d           ; ecx = n - j
    inc ecx                 ; ecx = n - j + 1

    mov r8d, eax            ; r8d = i
    sub r8d, ecx            ; r8d = i - (n - j + 1)

    mov ecx, r8d            ; ecx = i - (n - j + 1)

    and r8d, 63             ; r8d = i - (n - j + 1) mod 64
    shr ecx, 6              ; ecx = i - (n - j + 1) / 64

    mov r9, [rdi + rcx*8]   ; r9 = slowo w T
    bt r9, r8               ; wybieramy bit w T
    jc ustaw_bit_T_na_1     ; jesli jest ustawiony, to zapisujemy ten fakt

ustaw_bit_T_na_0:
    xor r9, r9              ; r9 = bit w T = 0
    jmp porownaj_bity_i

ustaw_bit_T_na_1:
    mov r9, 1               ; r9 = bit w T = 1

porownaj_bity_i:
    ; porownujemy bit z T i bit z R
    ; w r9 jest juz zapisany bit z T
    ; teraz musimy tylko wybrac bit z R

    xor r8, r8
    xor rcx, rcx            ; zerujemy aby zapewnic poprawnosc obliczen

    mov ecx, eax            ; ecx = i
    shr ecx, 6              ; ecx = i / 64 

    mov r8d, eax            ; r8d = i
    and r8d, 63             ; r8d = i mod 64

    mov r10, [rsi + rcx*8]  ; r10 = slowo w R

    xor ecx, ecx            ; rcx = 0
    bt r10, r8              ; wybieramy bit w R
    setc cl                 ; rcx = bit w R

    xor r8d, r8d            ; r8 = 0

    cmp cl, r9b             ; porownujemy bit w R z bitem w T
    je kontynuuj_petle_i    ; jezeli sa rowne, to nie mozemy stwierdzic ktora wartosc jest wieksza, zatem kontynuujemy petle
    jl Twiekszy             ; jesli bit R < bit T, to liczba T jest wieksza

Rwiekszy:
    mov r10, 1
    jmp wyjdz_z_i

Twiekszy:
    mov r10, 0
    jmp wyjdz_z_i

kontynuuj_petle_i:
    mov r10, 2              ; przywracamy rownosc liczby R i T (gdyz wczesniej uzylismy r10 jako rejestr do trzymania slowa R)
    dec eax                 ; i--
    jmp i_petla

wyjdz_z_i:
    ; r10 to rejestr ktory trzyma informacje o stosunku R do T
    ; dla przypomnienia:
    ; r10 = 2 - liczby R, T rowne
    ; r10 = 1 - liczba R wieksza od T
    ; r10 = 0 - liczba R mniejsza od T
    ; jesli r10 != 0, to trzeba wykonac odejmowanie
    xor rax, rax
    xor rcx, rcx
    xor r9, r9
    xor r8, r8
    ; dla poprawnosci obliczen zerujemy uzytkowe rejestry

    cmp r10, 0
    jne wykonaj_odejmowanie
    jmp nastepny_bit_0

wykonaj_odejmowanie:
    ; tutaj przyjmijmy r8 jako rejestr ktory trzyma informacje czy bedzie 'poczyczka bitu' przy odejmowaniu
    ; eax - licznik petli odejmowania
    xor r10, r10
    mov r9, rdx             ; rdx = n
    shl r9d, 1              ; rdx = 2n

k_petla:
    cmp eax, r9d            ; czy k == 2n
    je wyjdz_z_k

    ; wyliczmy bit z T
    mov ecx, edx            ; ecx = n
    sub ecx, r11d           ; ecx = n - j
    shl ecx, 1              ; ecx = 2(n - j)

    cmp eax, ecx            ; czy k == 2(n - j)
    je ustaw_bit_t          ; bit w T == 1
    jl wyczysc_bit_t        ; bit w T == 0

    mov ecx, edx            ; ecx = n
    shl ecx, 1              ; ecx = 2n
    sub ecx, r11d           ; ecx = 2n - j

    cmp eax, ecx            ; czy k == 2n - j
    jg wyczysc_bit_t        ; bit w T == 0

    ; jestesmy w przedziale (2n - 2j; 2n - j]
    mov ecx, edx            ; ecx = n
    sub ecx, r11d           ; ecx = n - j
    inc ecx                 ; ecx = n - j + 1

    mov r10d, eax           ; r10d = k
    sub r10d, ecx           ; r10d = k - (n - j + 1)

    mov ecx, r10d           ; ecx = k - (n - j + 1)

    shr ecx, 6              ; ecx = k - (n - j + 1) / 64
    and r10d, 63            ; r10d = k - (n - j + 1) mod 64

    mov r12, [rdi + rcx*8]  ; r12 = slowo w T
    bt r12, r10             ; wybieramy bit w T
    jc ustaw_bit_t          ; jest ustawiony
    jmp wyczysc_bit_t

ustaw_bit_t:
    mov r12, 1              ; bit w T == 1
    jmp odejmij_bity

wyczysc_bit_t:
    xor r12, r12            ; bit w T == 0

odejmij_bity:
    ; w r12 mamy bit z T
    ; teraz wybieramy bit z R
    mov ecx, eax            ; ecx = k
    shr ecx, 6              ; ecx = k/64

    mov r10, [rsi + rcx*8]  ; slowo w R

    mov ecx, eax            ; ecx = k
    and ecx, 63             ; ecx = k mod 64

    bt r10, rcx             ; wybieramy bit z R
    setc r10b               ; w r10b mamy bit z R

    xor rcx, rcx
    mov cl, r10b
    xor r10, r10
    mov r10, rcx

    sub r10, r12            ; r10 = bit z R - bit z T
    sub r10, r8             ; r10 = bit z R - bit z T - pozyczka

    cmp r10, 0
    jl odejmij_z_pozyczka

odejmij_bez_pozyczki:
    xor r8, r8              ; zerujemy pozyczke
    jmp ustaw_roznice_bitow_w_R

odejmij_z_pozyczka:
    mov r8, 1
    add r10, 2              ; r10 = bit z R - bit z T - pozyczka + 2

ustaw_roznice_bitow_w_R:
    test r10, r10           ; czy r10 zawiera 0?
    jz zeruj_bit_w_R        ; jesli tak, zerujemy bit w R
    ; wpp ustawiamy bit 

    mov ecx, eax            ; ecx = k
    shr ecx, 6              ; ecx = k / 64

    mov r10, rax            ; r10 = k
    and r10, 63             ; r10 = k mod 64
    bts [rsi + rcx*8], r10  ; ustawiamy bit w R
    jmp kontynuuj_petle_k

zeruj_bit_w_R:
    mov ecx, eax            ; ecx = k
    shr ecx, 6              ; ecx = k / 64

    mov r10, rax            ; r10 = k
    and r10, 63             ; r10 = k mod 64

    btr [rsi + rcx*8], r10  ; zerujemy bit w R

kontynuuj_petle_k:
    inc eax                 ; k++
    xor rcx, rcx
    xor r10, r10
    xor r12, r12
    jmp k_petla

wyjdz_z_k:
    xor rax, rax
    xor rcx, rcx
    xor r10, r10
    xor r12, r12
    xor r9, r9
    xor r8, r8
    
nastepny_bit_1:
    mov r12, rdx            ; r12 = n
    sub r12, r11            ; r12 = n - j

    mov rax, r12            ; rax = n - j

    shr r12, 6              ; r12 = (n - j) / 64
    and rax, 63             ; rax = (n - j) mod 64

    bts [rdi + r12*8], rax  ; ustaw bit z Q na 1
    jmp kontynuuj_petle_j

nastepny_bit_0:
    ; nic nie robimy bo i tak bit juz jest wyzerowany

kontynuuj_petle_j:
    inc r11                 ; j++
    xor rax, rax
    xor rcx, rcx
    xor r8, r8
    xor r9, r9
    xor r10, r10
    xor r12, r12
    jmp j_petla

wyjdz_z_j:
    pop r12
    pop rbp
    ret