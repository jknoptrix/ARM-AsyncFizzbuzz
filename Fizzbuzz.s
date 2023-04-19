// code for Arduino (STM32F103C8T6) via RS-232
.global main
main:
    mov r0, #1
loop:
    cmp r0, #101
    beq exit  
    mov r1, r0
    mov r2, #3
    bl mod    
    cmp r0, #0
    moveq r3, #1
    mov r4, #5
    bl mod    
    cmp r0, #0
    moveq r5, #1
    cmp r3, #1
    beq fizz  
    cmp r5, #1
    beq buzz  
    b print   
fizz:
    ldr r0, =fizz_msg
    b print_msg
buzz:
    ldr r0, =buzz_msg
    b print_msg

print:
    mov r0, r1
    bl printf_async
    add r0, r0, #1   
    b loop    

exit:
    ldr r0, =async_msg
    bl print_msg 
    mov r0, #0
    bx lr

mod:
    push {lr} 
    mov r3, #0
    cmp r2, #0
    beq end   
    mov r4, #0
    mov r5, #0
div:
    sub r2, r2, #1   
    add r3, r3, #1   
    cmp r1, r2
    blt end   
    add r4, r2, r2, lsl #1
    cmp r1, r4
    blt div   
    add r5, r2, r2, lsl #2
    cmp r1, r5
    blt end   
    add r2, r2, #1   
    b div     
end:
    pop {lr}  
    bx lr

print_msg:
    push {lr} 
    bl printf_async
    pop {lr}  
    bx lr

printf_async:
    push {lr}
    ldr r1, =uart_base
    ldrb r2, [r1, #UART_FLAG_OFFSET]
    tst r2, #UART_FLAG_TX_FULL
    bne $
    strb r0, r1, #UART_DATA_OFFSET
    pop {lr}
    bx lr
$:
    mov r0, #1
    bx lr

.data
fizz_msg: .asciz "Fizz"
buzz_msg: .asciz "Buzz"
async_msg: .asciz "I"
uart_base: .word 0x10000000  // change uart address to ur own
UART_DATA_OFFSET: .equ 0x00
UART_FLAG_OFFSET: .equ 0x18
UART_FLAG_TX_FULL: .equ 0x20.