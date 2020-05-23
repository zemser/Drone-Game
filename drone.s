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
    format_string: db "Drone id %d: I am a winner", 10, 0	; format string
    const_180: dd 180.0
    value_360: dd 360.0
    value_100: dd 100.0
    value_0: dd 0.0
    value_2: dd 2.0
    value_minus_1: dd -1.0
    STKSIZE equ 16*1024
    stkpointer equ 4
    dateBaseSize equ 20
    zero_const equ 0
    const_360 equ 360
    const_100 equ 100
    const_60 equ 60
    minus_60_const equ -60
    const_50 equ 50
    lsfr_constant equ 45

section .bss   
    x: resd 1
    y: resd 1
    alpha: resd 1 
    wins: resd 1
    id: resd 1
    SPT: resd 1
    delta_alpha: resd 1
    moving_distance: resd 1
    tempPointer: resd 1
    tempy: resd 1
    tempx: resd 1
    offSet: resd 1
    gamma: resd 1
    rad_alpha: resd 1
    temp: resd 1
    retval: resd 1
    memory_to_store: resd 1

section .text
    align 16
     global drone_func
     extern pdrones
     extern pdatabase
     extern scale
     extern lsfr
     extern seed
     extern beta
     extern distance
     extern index
     extern target_x
     extern target_y
     extern scheduler
     extern target
     extern printer
     extern t
     extern printf 
     extern co_end
     extern resume

drone_func:
    mov eax, [index]     ;get drone's id
    dec eax             ;for the offset (its like an array so if we want drone 1 we need the 0 position)
    mov [id], eax

    ;generate new angle
    push dword [seed]
    call lsfr
    add esp, 4
    mov [seed], eax
    push const_60
    push minus_60_const
    push dword [seed]
    call scale 
    add esp, 12
    mov [delta_alpha], eax
    ;generate distcane
    push dword [seed]
    call lsfr 
    add esp, 4
    mov [seed], eax
    push const_50
    push zero_const
    push dword [seed]
    call scale 
    add esp, 12
    mov [moving_distance], eax
    ;add the angles
    mov ebx, [id]
    mov eax, dateBaseSize
    mul ebx  ;after mul in eax is id* databasesize(20)
    mov esi,eax   ;esi-offset to the drone in the data base    
    finit
    mov ebx,[pdatabase]
    add ebx,esi
    mov [offSet], ebx   ;save for later purpose (it is the pointer to the drone in pdatabase)
    add ebx, 8
    fld dword [ebx] ;push the curr angle
    fld dword [delta_alpha] ;push the random angle 
    faddp 
    fld dword [value_360]  ;push 360 
    fcomip
    jb sub_360  ;jump if the value i greater than 360 
    fld dword [value_0]
    fcomip
    jb no_patch  ;jump if number is in [0, 360]
    fld dword [value_360]
    faddp 
    jmp no_patch
    sub_360:  ;the angle is bigger than 360 
        fld dword [value_360]
        fsubp  ;st(1)-st(0) = angle - 360
    no_patch:
        fst dword [delta_alpha]   ;the new angle
        mov ebx, [offSet]  ;ebx points to the drone in the data base
        add ebx, 8  ;now ebx points to the angle of the drone in the database
        mov eax, [delta_alpha] 
        mov [ebx], eax 
    
	fldpi                   ;add pie to the stack (to convert delta aplha to radians)
	fmulp                   ;multiply alpha with pie
	fld	dword [const_180]
	fdivp	                ;divide by 180
    fsincos      ; Compute vectors in y and x 

    ;update x
    fld	dword [moving_distance]
	fmulp        ; multiply sin with distance to get new dx 
    mov ebx, [offSet]
    fld	dword [ebx]  ;load the curr x from the database
	faddp   ;now we have in st(0) the new cordiante x
    ;patch x to board boundaries 
    fld dword [value_100]  ;push 100
    fcomip
    jb sub_100_x  ;jump if the value i greater than 100 
    fld dword [value_0]
    fcomip
    jb no_patch_x  ;jump if number is in [0, 100]
    fld dword [value_100]
    faddp 
    jmp no_patch_x
    sub_100_x:  ;the number is bigger than 100 
        fld dword [value_100]
        fsubp  ;st(1)-st(0)
    no_patch_x:
     fstp dword [x]  
     mov ebx, [offSet]  ;ebx points to the drone in the data base
     mov eax, [x] 
     mov [ebx], eax ;store the new x  in dtabase

    ;update y
	fld	dword [moving_distance]
	fmulp                 ; multiply sin with distance to get dy
    add ebx,4
	fld	dword [ebx]  ;load the curr y from the database
	faddp	
    ;patch y to board boundaries 
    fld dword [value_100]  ;push 360 
    fcomip
    jb sub_100_y  ;jump if the value i greater than 360 
    fld dword [value_0]
    fcomip
    jb no_patch_y  ;jump if number is in [0, 360]
    fld dword [value_100]
    faddp 
    jmp no_patch_y
    sub_100_y:  ;the agnle is bigger than 360 
        fld dword [value_100]
        fsubp 
    no_patch_y:
      fstp dword [y]		
      mov ebx, [offSet]  ;ebx points to the drone in the data base
      add ebx, 4  ;point to y in the database
      mov eax, [y] ;store the new y in the dtabase
      mov [ebx], eax


may_destroy: 
    finit
    fld dword [y]
    fld dword [target_y]
    fsubrp         ;st(0)-st(1) = traget_y - y
    fld dword [x]
    fld dword [target_x]
    fsubrp       ;st(0)-st(1) = traget_x - x
    fpatan      ;gamma is in st(0)
    fstp dword [gamma]
    ; put alpha in the stack and convert it to radians
    fld dword [delta_alpha]  
    fldpi                   ;add pie to the stack (to convert delta aplha to radians)
	fmulp                   ;multiply alpha with pie
	fld	dword [const_180]
	fdivp       ;now: st(0)=alpha(in radians), st(1)=gamma(radians)
    fst dword [rad_alpha]  ;save alpha in radians


    ;check if the distance between alpha and gamma is not greater than 1 pie
    fld dword [gamma]
    fsubp   ;st(1) - st(0) = alpha - gamma  --> into st(0)
    fldpi  
    fcomip 
    jb add_to_gamma    ; should be st(0) < st(1)   
    fldpi
    fld dword [value_minus_1]
    fmulp
    fcomip 
    ja add_to_alpha 
    jmp contiue_conditions_check
    add_to_alpha: ;add 2 pie to rad_alpha
    finit 
    fld dword [rad_alpha]
    fldpi
    fldpi
    faddp
    faddp
    fstp dword [rad_alpha]
    jmp contiue_conditions_check ;jumping with empty stack
    add_to_gamma:
    finit 
    fld dword [gamma]
    fldpi
    fldpi
    faddp
    faddp
    fstp dword [gamma]  ;continue with empty stack
    

    contiue_conditions_check:
    finit
    fld dword [rad_alpha]
    fld dword [gamma]
    fsubp ;alpha-gamma
    fabs 
    fld dword [beta]    ;convert beta to radians:
    fldpi                   ;add pie to the stack (to convert delta aplha to radians)
	fmulp                   ;multiply alpha with pie
	fld	dword [const_180]
	fdivp       ;now: st(0)=alpha(in radians), st(1)=gamma(radians)
    fcomip 
    jb no_destruction   ;jump if (!(abs(alpha-gamma)<beta)) 
    ;jb jumps if st(1)>st(0) 

    ;check second condition 
    finit
    fld dword [x]
    fld dword [target_x]
    fsubrp ;should be st(0)-st(1)
    fst dword [temp]
    fld dword [temp]
    fmulp   ;(x_target-x)*(x_target-x)
    fld dword [y]
    fld dword [target_y]
    fsubrp
    fst dword [temp]
    fld dword [temp]
    fmulp   ;(y_target-y)*(y_target-y)
    faddp
    fsqrt
    fld dword [distance]
    fcomip
    jb no_destruction   ;jump if (!sqrt((y2-y1)^2+(x2-x1)^2) < d)
    
    
    destroy: 
        mov ebx,[offSet]
        add ebx, 12  ;ebx points to drone's num of wins
        mov ecx, [ebx]  ;ecx- num of wins
        inc ecx
        mov [ebx], ecx   ;store the updated num of wins
        cmp ecx, [t]  ;check if the player won
        je game_over
        mov ebx, target     ;the game continues, genarate a new target
        call resume
        jmp no_destruction
        game_over:
            push dword [index]
            push format_string
            call printf
            add esp,8
            jmp co_end  ;return to main and exit


    no_destruction:
        mov ebx, scheduler
        call resume
        jmp drone_func


