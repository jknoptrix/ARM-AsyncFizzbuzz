.global main

.equ UART0_BASE, 0x4000C000   ; базовый адрес UART0
.equ UART_CLKDIV, 16          ; делитель частоты для UART (baud rate = 115200)

; инициализация UART0
init_uart:
    mov r0, #UART0_BASE        ; загружаем базовый адрес UART0 в регистр r0
    ldr r1, =UART_CLKDIV       ; загружаем делитель частоты в регистр r1
    ldr r2, [r0, #0x30]        ; загружаем значение регистра LCR (Line Control Register)
    orr r2, r2, #0x80          ; устанавливаем бит DLAB (Divisor Latch Access Bit)
    str r2, [r0, #0x30]        ; сохраняем обновленное значение регистра LCR
    mov r3, #0                 ; обнуляем регистр divisor latch (DLL) для установки частоты
    mov r4, #0                 ; обнуляем регистр divisor latch (DLH) для установки частоты
    udiv r3, r3, r1            ; вычисляем значение DLL
    udiv r4, r4, r1            ; вычисляем значение DLH
    str r3, [r0]               ; сохраняем значение DLL в регистре RBR/THR/DLL
    str r4, [r0, #4]           ; сохраняем значение DLH в регистре DLM/IER
    mov r2, #0x03              ; устанавливаем 8 бит данных, 1 стоп-бит, без контроля четности
    str r2, [r0, #0x30]        ; сохраняем обновленное значение регистра LCR
    mov r2, #0x01              ; устанавливаем бит THRE (Transmitter Holding Register Empty) в IER
    str r2, [r0, #0x04]        ; сохраняем обновленное значение регистра IER
    bx lr                      ; выходим из функции

; отправка слова "Connected" по UART0
send_connected:
    mov r0, #UART0_BASE        ; загружаем базовый адрес UART0 в регистр r0
    ldr r1, =msg               ; загружаем адрес строки "Connected" в регистр r1
    ldrb r2, [r1], #1          ; загружаем первый символ строки в регистр r2 и инкрементируем адрес
    cmp r2, #0                 ; проверяем, не достигнут ли конец строки
    beq end_send               ; если достигнут, завершаем отправку
    strb r2, [r0]              ; отправляем символ по UART0
    b send_connected           ; переходим к следующему символу строки

end_send:
    bx lr                      ; выходим из функции
; точка входа в программу
main:
    bl init_uart               ; вызываем функцию инициализации UART0
    bl send_connected          ; вызываем функцию отправки слова "Connected"
    bl fizzbuzz_main            ; покдлючаемся в Fizzbuzz.s
    b .                        ; бесконечный цикл
msg:
    .ascii "Connected\n"       ; строка для отправки по UART0
