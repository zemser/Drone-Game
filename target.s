%macro funcPrep 0
        push ebp        ;setup stack frame
        mov ebp, esp
    %endmacro

     %macro funcAfter 0		
        mov esp, ebp	
        pop ebp
        ret
    %endmacro

section	.data
    zero_const equ 0
    const_360 equ 360
    const_100 equ 100
    const_60 equ 60
    minus_60_const equ -60
    const_50 equ 50

section .bss   
    ptemp: resd 1
    counter: resd 1
    


section .text
    align 16
     global target_func
     extern seed
     extern n
     extern target_x
     extern target_y
     extern lsfr
     extern scale
     extern drone_pointer
     extern resume
    


target_func:
     ;generate 2 new random coordinates
    push dword [seed]
    call lsfr
    add esp,4
    mov [seed],eax
    push const_100
    push zero_const
    push dword [seed]
    call scale
    add esp,12  ;in eax is the scaled num
    mov [target_x],eax 
    push dword [seed]
    call lsfr
    add esp,4
    mov [seed],eax
    push const_100
    push zero_const
    push dword [seed]
    call scale
    add esp,12  ;in eax is the scaled num
    mov [target_y],eax 

    mov ebx, [drone_pointer]
    call resume
    jmp target_func
 
