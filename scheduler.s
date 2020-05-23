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
    STKSIZE equ 16*1024

section .bss   
   counter: resd 1
   index: resd 1
   drone_pointer: resd 1
   print_index:resd 1

section .text
    align 16
     global scheduler_func 
     global index
     global drone_pointer
     extern pdrones
     extern k
     extern printer
     extern resume
     extern n


scheduler_func:
    mov eax, [pdrones]
    mov [drone_pointer], eax
    mov dword [index], 1
    mov dword [print_index],0
    scheduler_loop:
        mov ebx, [drone_pointer]  ;put in ebx pointer to the drone's struct
        call resume   ;resume to the drone
        inc byte [index]
        inc byte [print_index]
        mov edx, [k]
        cmp dword [print_index], edx   ;check if index = k => if so print the board
        jne dont_print_board
        mov dword [print_index],0
        mov ebx, printer  ;put in ebx pointer to the strcut of co printer
        call resume  ;resume co printer
        dont_print_board:
        ;check if we are in the last drone - is so point to the first drone, else to the next
        mov edx,[n]
        inc edx
        cmp [index],edx
        jne continue
        ; return to the first drone
        mov eax, [pdrones]
        mov [drone_pointer], eax
        mov dword [index], 1
        jmp scheduler_loop
        continue:
        mov edx, STKSIZE 
        mov eax, [drone_pointer]
        add eax,  edx   ;move the ponter to the next drones struct
        mov [drone_pointer], eax  ;update the pointer into the label
        jmp scheduler_loop
