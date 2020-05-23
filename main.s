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
    format_string: db "%s", 10, 0	; format string
    format_string_n0_newLine: db "%s", 0	; format string
    format_hexa: db "%X",10, 0	; format hexa
    fomrat_d: db "%d", 0
    format_f: db "%f", 0
    error_insuficent_num_of_argument: db 'Error: wrong number of arguments', 10, 0 
    error_insuficent_num_of_argument2: db 'Error: argument not equal six', 10, 0 
    int_max: dd 65535 ;2^16-1

    STKSIZE equ 16*1024
    stkpointer equ 4
    dateBaseSize equ 20
    lsfr_constant equ 45
    zero_const equ 0
    const_360 equ 360
    const_100 equ 100
    const_60 equ 60
    minus_60_const equ -60
    const_50 equ 50
    scheduler:  dd scheduler_func       ;pointer to scheduler function
                dd stk_scheduler+STKSIZE   ; pointer to the beginning of scheduler stack
    target: dd target_func       ;pointer to target function
            dd stk_target+STKSIZE    ; pointer to the beginning of target stack
    printer: dd print_func     ;pointer to printer function
             dd stk_print+STKSIZE    ; pointer to the beginning of printer stack

    

section .bss   
    pStruct: resd 1   ;pointer to the the calloc
    n: resd 1 ;number of drones
    t: resd 1 ;number of targets
    k: resd 1 ;number of steps between print
    beta: resd 1 ;drone field of view
    distance: resd 1   ;max distance to destroy
    seed: resd 1 
    CURR: resd 1
    SPT: resd 1 ; temporary stack pointer
    SPMAIN: resd 1 ; stack pointer of main
    stk_scheduler: resd STKSIZE
    stk_target: resd STKSIZE
    stk_print: resd STKSIZE
    pdrones: resd 1
    pdatabase: resd 1
    tempPointer: resd 1
    retval: resd 1
    scaled: resd 1
    ret87: resd 1
    counter: resd 1
    target_x: resd 1 
    target_y: resd 1
    


section .text
    align 16
     global main 
     global pdrones
     global pdatabase
     global lsfr
     global scale
     global seed
     global n
     global k
     global t
     global distance
     global beta
     global target_x
     global target_y
     global resume
     global do_resume
     global co_end
     global printer
     global target
     global scheduler

     extern index
     extern drone_func
     extern print_func
     extern target_func
     extern scheduler_func
     extern printf 
     extern fflush
     extern malloc 
     extern calloc 
     extern free 
     extern fgets 
     extern sscanf 

main:

 init_cos:
    funcPrep
    pushad
    
get_arguments_from_user:
    mov eax,[ebp + 8]     ;the first argument- argc
    cmp eax,7   ; check num of arguments given
    jne error
    mov dword eax, [ebp + 12] ; argv
    mov dword ebx, [eax + 4]  ; pointer to the 1st argument
    pushad
    push n
    push fomrat_d
    push ebx
    call sscanf  ;save the input number as hexa and put in the label
    add esp,12
    popad
   
    mov ebx, [eax+8]   ;pointer to the second argument
    pushad
    push t
    push fomrat_d
    push ebx
    call sscanf  ;save the input number as hexa and put in the label
    add esp,12
    popad

    mov ebx, [eax + 12]  ;pointer to the 3rd argument
    pushad
    push k
    push fomrat_d
    push ebx
    call sscanf  ;save the input number as hexa and put in the label
    add esp,12
    popad
   
    mov ebx, [eax + 16] ;pointer to the 4rd argument
    pushad
    push beta
    push format_f
    push ebx
    call sscanf  ;save the input number as hexa and put in the label
    add esp,12
    popad

    mov ebx, [eax + 20] ;pointer to the 5th argument
    pushad
    push distance
    push format_f
    push ebx
    call sscanf  ;save the input number as hexa and put in the label
    add esp,12
    popad

    mov ebx, [eax + 24]  ;pointer to the 6th argument
    pushad
    push seed
    push fomrat_d
    push ebx
    call sscanf  ;save the input number as hexa and put in the label
    add esp,12
    popad

    ;allocate memory for drones stack
    mov eax,[n]   ;move to ecx to number of drones
    mov ebx, STKSIZE
    mul ebx   ;the result will be be in edx and eax- for our purpose only eax is relevant
    mov ebx,1            ;argument 2 for calloc (number of elements)
    push ebx   ;we push 1 unit
    push eax   ;size of all the elements together    
    call calloc
    add esp,8
    mov [pdrones],eax        ;save the pointer to drone structure

    ;drone initialization:
    mov ecx,[n]  ;counter for the loop
    loop_drone_init:
        mov edx, drone_func
        mov [eax], edx   ;save in the memory pointer to the drone function
        mov edx, eax   ;edx point to the current drone (start of the struct)
        add eax,  4   ;put in eax the pointer to the beginig of the stack of this drone
        mov ebx, eax  ;ebx is the pointer of stack
        mov eax,edx  ;eax points to the current drone (start of the struct)
        add eax, STKSIZE  ;eax is the pointer to the bottom of the stack
        mov [ebx], eax
        loop loop_drone_init
    
    
    ;initalize target_x and target_y
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
    y:
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

    ;initalize the data base       
    mov eax, dateBaseSize   ;enter the size of the dataBase 34
    mov ebx,[n]   
    push ebx   ;we push 1 unit
    push eax   ;size of all the elements together    
    call calloc
    add esp,8
    mov [pdatabase],eax        ;save the pointer to drone structure
    mov [tempPointer],eax   ;temp pointer to the start of the dat base
    mov ecx, 0
    mov [counter],ecx  ;intialize counter
    data_loop:
        mov ecx, [n]
        cmp [counter], ecx
        je data_loop_end
        inc byte [counter]
        ;generate radom number for x
        push dword [seed]
        call lsfr
        add esp,4
        mov [seed],eax
        ;scale the random number for x
        push const_100
        push zero_const
        push dword [seed]
        call scale
        add esp,12  ;in lable ret87 is the scaled number from scale
        mov ebx, [tempPointer]
        mov [ebx], eax ;put in the database the scaled number for -x
        add ebx, 4    ;increase ebx to point to y
        mov [tempPointer], ebx    ;update temp pointer to y

        ;generate radom number for y
        push dword [seed]
        call lsfr
        add esp,4
        mov [seed],eax
        ;scale the random number for y
        push const_100
        push zero_const
        push dword [seed]
        call scale
        add esp,12  ;in eax is the scaled number from scale
        mov ebx, [tempPointer]
        mov [ebx], eax ;put in the database the scaled number for -y
        add ebx, 4     ;increase ebx to point to alpha
        mov [tempPointer], ebx    ;update temp pointer to alpha
        
        ;generate radom number for alpha
        push dword [seed]
        call lsfr
        add esp,4
        mov [seed],eax
        ;scale the random number for alpha
        push const_360
        push zero_const
        push dword [seed]
        call scale
        add esp,12  ;in eax is the scaled number from scale
        mov ebx, [tempPointer]
        mov [ebx], eax ;put in the database the scaled number for alpha
        add ebx, 4     ;increase ebx to point to num of wins
        mov [tempPointer], ebx    ;update temp pointer to num of wins
        
        ;intialize the num of wins and the drones id
        mov dword [ebx], 0 ;initalize the num of wins to 0
        add ebx, 4   ;increase eb to point to the id of the drone
        mov [tempPointer], ebx  ;update temp pointer to drone id
        mov ecx, [counter]
        mov [ebx], ecx   ;put in the memory the drone id
        add ebx, 4
        mov [tempPointer],ebx   ;update pointer to the next data struct
        jmp data_loop

    data_loop_end:

push dword scheduler
call init_co
add esp, 4
push dword target
call init_co
add esp, 4
push dword printer
call init_co
add esp, 4
mov ecx, [pdrones]  ;put in ecx pointer to the label
mov [tempPointer], ecx 
mov dword [counter], 0 
init_cos_loop:
    mov ecx, [n]
    cmp dword [counter], ecx
    je start_routines
    push dword [tempPointer]
    call init_co
    add esp, 4
    inc byte [counter]  
    mov ecx, [tempPointer]  ;save pointer to prev co-routine
    add ecx, STKSIZE
    mov [tempPointer], ecx   ;now the labler points to start of next drone
    jmp init_cos_loop
    

start_routines:
    jmp start_co_routines


start_co_routines:
    mov [SPMAIN], esp   ;save esp of ass3 (our main)
    mov ebx, scheduler
    jmp do_resume

    co_end: 
        push dword [pdatabase]
        call free
        add esp,4
        push dword [pdrones]
        call free
        add esp,4
        mov esp,[SPMAIN]
        popad
        funcAfter

init_co:
    funcPrep
    pushad
    mov ebx, [ebp+8] ;get pointer to the struct of the 'co'
    mov eax,[ebx] ;put in eax the pointer to the function
    mov [SPT], esp   ;save current esp 
    mov ecx, [ebx+4]
    mov esp, ecx ;put in esp the co's esp 
    push eax ;push return address- the funtion
    pushfd
    pushad 
    mov [ebx+stkpointer], esp  ;save the esp after the pushes
    mov esp, [SPT]  ;restore the prev esp
    popad
    funcAfter


resume:
    pushfd
    pushad
    mov edx, [CURR]
    mov [edx+stkpointer], esp   ;save the esp of the curr thread (the one that stops running)
do_resume:
    mov  esp, [ebx+stkpointer]   ;update esp to the new routine's stack pointer
    mov [CURR], ebx
    popad
    popfd 
    ret


lsfr:
    funcPrep
    pushad
    xor edx, edx
    mov edx,[ebp+8] ;in edx is the argument
    mov esi, 16
    lsfr_loop:
        cmp esi,0
        je lsfr_end  
        xor eax,eax  
        xor ecx, ecx
        mov bx, lsfr_constant   ;2d=101101
        mov cx,dx   ;duplicate ecx
        and dx,bx   ;leave in cx only the 11,13,14,16 bits
        jp yes_parity
        inc ax   ;add 1 to ax if there is a odd num of 1s (ax hold 0)
        yes_parity:
        shr cx,1   ;shift right the prev seed
        xor ebx,ebx
        mov bx, 32768 ;1...0^15 = 8000 
        mul bx   ;multiply ax (0 or 1) by bx (8000)
        add ax, cx   ;after mul if bx was 8000= ax would
        mov dx,ax
        dec esi 
        jmp lsfr_loop
    lsfr_end: 
    xor ebx,ebx 
    mov dword [retval], ebx  ;set retval to 0 before we store the new seed
    mov [retval],ax  ;the number after the shift and insert of 1 or 0 
    popad
    xor eax,eax 
    mov eax,[retval]
    funcAfter
    

scale:
    funcPrep
    sub esp,4 ;for the returned value
    pushad   

    finit
    fild dword [ebp + 8]
    fild dword [ebp + 12]
    fild dword [ebp + 16]
    fsubrp   ;b-a
    fmulp   ;(b-a)*seed
    fild dword [int_max]
    fdivp 
    fild dword [ebp + 12]
    faddp
    fstp dword [ret87]
    popad
    mov eax, [ret87]
    funcAfter

error: 
    push error_insuficent_num_of_argument
    push format_string
    call printf
    add esp,8
    jmp co_end
   
error2: 
    push error_insuficent_num_of_argument2
    push format_string
    call printf
    add esp,8    
    jmp co_end