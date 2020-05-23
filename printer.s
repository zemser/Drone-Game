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
    format_string: db "%d, %.02lf, %.02lf, %.02lf, %d", 10, 0	; format string
    target_string: db "%.02lf, %.02lf", 10, 0  
    format_string1: db "%.02lf", 10, 0	; format string
    const_180: dd 180.0
    value_360: dd 360.0
    value_0: dd 0
    STKSIZE equ 16*1024

section .bss   
    ptemp: resd 1
    counter: resd 1
    printed_num: resq 1

section .text
    align 16
     global print_func
     extern pdatabase
     extern n
     extern printf
     extern target_x
     extern target_y
     extern scheduler
     extern resume
     extern co_end

print_func:
    mov ebx,[pdatabase]
    mov [ptemp], ebx   ;ptemp point to the data base
    xor ecx,ecx
    mov dword [counter],0
    
    ;print target
    finit 
    sub esp, 8
    fld dword [target_y]
    fstp qword [esp]

    sub esp, 8
    fld dword [target_x]
    fstp qword [esp]

    push target_string
    call printf
    add esp, 20

    print_loop:  ;print the database
        mov ecx,[counter]
        cmp ecx,[n]
        je end_print
        inc byte [counter]
        mov ebx, [ptemp]
        mov eax,[ebx+12] ;get the wins
        push eax


        mov eax, [ptemp]   
        sub esp, 8
        finit
        fld dword [eax+8]   ;load alpha 
        fstp qword [esp]

        sub esp, 8
        fld dword [eax+4]   ;load y 
        fstp qword [esp]
    
        sub esp, 8
        fld dword [eax]   ;load x 
        fstp qword [esp]
        
        push dword [counter]
        push format_string
        call printf
        add esp,36
        
        ;increase ptemp to the next drone
        mov eax, 20
        mov ebx,[ptemp]
        add ebx, eax 
        mov [ptemp], ebx

        jmp print_loop
   
    end_print:
    mov ebx, scheduler
    call resume
    jmp print_func
       
