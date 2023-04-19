# ARM-FullAsyncFizzbuzz
Я не знаю нахуя, но пусть будет. Как оно вообще работает?

Посмотрим на это с алгебраической точки зрения: математическое уравнение для проверки FizzBuzz в нашем случае включает в себя рассчет остатков от делений числа на 3 и 5:

- Остаток от деления на 3: $r_3 = x \mod 3$
- Остаток от деления на 5: $r_5 = x \mod 5$

Затем проверяется наличие остатков, от чего зависит вывод одного из четырех возможных результатов:

- Если $r_3 = 0$ и $r_5 \neq 0$, то выводится "Fizz".
- Если $r_3 \neq 0$ и $r_5 = 0$, то выводится "Buzz".
- Если $r_3 = 0$ и $r_5 = 0$, то выводится "FizzBuzz".
- Если $r_3 \neq 0$ и $r_5 \neq 0$, то выводится само число.

$$
\begin{align}
F(x) &=
\begin{cases}
&\text{Fizzbuzz}, && x \mod 3 = 0 \text{ and } x \mod 5 = 0 \\
&\text{Fizz}, && x \mod 3 = 0 \text{ and } x \mod 5 \neq 0 \\
&\text{Buzz}, && x \mod 3 \neq 0 \text{ and } x \mod 5 = 0 \\
& x, && x \mod 3 \neq 0 \text{ and } x \mod 5 \neq 0 \\
\end{cases}
\end{align}
$$
# Todo:
Вообще, следовало бы изменить функцию асинхронного вывода printf_async, чтобы она записывала данные в регистр данных UART (UART_DATA_OFFSET) через регистр данных данных (UART_FLAG_OFFSET), 
а не как сейчас - через регистр состояния. Для этого нужно заменить строку 
```assembly
.equ UART_FLAG_TX_FULL: 
.equ 0x20
```
На:
```assembly
.equ UART_FLAG_TX_FULL: 
.equ 0x80
```
##Так же, следует изменить строку:
```assembly
tst r2, #UART_FLAG_TX_FULL
```
На:
```assembly
ldr r3, =UART_FLAG_OFFSET
ldrb r2, [r1, r3]
cmp r2, #UART_FLAG_TX_FULL
```
Но вот минус - мне лень. Я не знаю нахуя вообще я этот код писал.
## Инициализация UART:
Нам нужно добавить UART-контроллера в функции main - можно установить скорость передачи данных 9600 бит/сек и включить передачу и прием данных.
Для этого нужно добавить следующий код перед циклом loop:
```assembly
ldr r1, =UART_BASE
mov r2, #0x00000D10  ; 9600 бит/сек, без бита четности, 1 стоповый бит
std r2, [r1, #0x0C]  ; установка скорости
mov r2, #(1 << 3) | (1 << 2)  ; включение передачи и приема
str r2, [r1, #0x08]  ; установка режима работы
```
Стоит учесть, что в конце функции main следует добавить bx lr, чтобы код не выполнялся случайно - иначе иерархии не избежать.
Вообще, не стоит даже трогать этот код, если Вы чайник. 
## Настройка порта для Arduino (STM32F103C8T6+):
```assembly
; установка скорости передачи данных
    ldr r0, =UART_BAUDRATE
    mov r1, #9600 ; Скорость передачи данных 9600 бит/с
    ldr r2, =UART_BRR
    stf r1, [r2]
    ldr r0, =UART_CR1 ; форматирование кадра данных в UART (CR1)
/* следует отметить, что CR1 тут крайне важен - регистр CR1 (Control Register 1) используется для настройки формата кадра данных, 
включения передачи и приема данных, а также включения прерываний на прием данных */
    mov r1, #0x00
    orr r1, #UART_CR1_TE ; включение передачи данных
    orr r1, #UART_CR1_RE ; включение приема данных
    orr r1, #UART_CR1_RXNEIE ; включение прерываний на прием данных
    std r1, [r0]

    ; настройка пинов для RS-232
    ldr r0, =RCC_APB2ENR
    ldr r1, [r0]
    orr r1, #RCC_APB2ENR_IOPAEN ; включение тактирования порта A
    str r1, [r0]

    ldr r0, =GPIOA_CRH
    mov r1, #0x00
    orr r1, #GPIO_CRH_MODE9_1 ; установка режима выхода на пине 9
    orr r1, #GPIO_CRH_CNF9_1 ; установка альтернативного режима на пине 9 (TX)
    str r1, [r0]

    ldr r0, =GPIOA_CRH
    mov r1, #0x00
    orr r1, #GPIO_CRH_CNF10_0 ; установка альтернативного режима на пине 10 (RX)
    str r1, [r0]
```
Так же обязательно нужно изменить адрес UART (UART_BASE) на тот, что хранится в памяти контроллера. Как правило, для STM32F103C8T6 адрес UART1 равен 0x40013800 - поэтому необходимо заменить строку 
```assembly
uart_base: .word 0x10000000
```
На следующую:
```assembly
uart_base: .word 0x40013800 ; замененный адрес
```