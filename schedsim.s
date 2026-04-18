    .equ    ALGO_FCFS,      0
    .equ    ALGO_SJF,       1
    .equ    ALGO_SRTF,      2
    .equ    ALGO_PF,        3
    .equ    ALGO_RR,        4

    .equ    PROC_ID,        0
    .equ    PROC_BURST,     8
    .equ    PROC_ARRIVAL,   16
    .equ    PROC_PRIORITY,  24
    .equ    PROC_ORDER,     32
    .equ    PROC_SIZE,      40

    .section .rodata

newline_char:
    .byte   0x0a

str_fcfs:
    .asciz  "FCFS"
str_sjf:
    .asciz  "SJF"
str_srtf:
    .asciz  "SRTF"
str_pf:
    .asciz  "PF"
str_rr:
    .asciz  "RR"

    .section .bss

    .balign 8
input_buf:
    .space  4096

    .balign 8
output_buf:
    .space  1025

    .balign 8
tok_ptr:
    .space  8

    .balign 8
input_end:
    .space  8

    .balign 8
algo_id:
    .space  8

    .balign 8
proc_count:
    .space  8

    .balign 8
rr_quantum:
    .space  8

    .balign 8
proc_array:
    .space  400

    .section .text
    .global _start

_start:
    movq    $0,                  %rax
    movq    $0,                  %rdi
    leaq    input_buf(%rip),     %rsi
    movq    $4096,               %rdx
    syscall

    movq    %rax,                %r8
    leaq    input_buf(%rip),     %rcx
    leaq    tok_ptr(%rip),       %rdx
    movq    %rcx,                (%rdx)
    addq    %r8,                 %rcx
    leaq    input_end(%rip),     %rdx
    movq    %rcx,                (%rdx)

    call    parse_input

    movq    $1,                  %rax
    movq    $1,                  %rdi
    leaq    newline_char(%rip),  %rsi
    movq    $1,                  %rdx
    syscall

    movq    $60,                 %rax
    movq    $0,                  %rdi
    syscall


skip_spaces:
.Lss_loop:
    movb    (%rdi),              %al
    cmpb    $0x20,               %al
    jne     .Lss_done
    incq    %rdi
    jmp     .Lss_loop
.Lss_done:
    movq    %rdi,                %rax
    ret


next_token:
    pushq   %rbx
    leaq    tok_ptr(%rip),       %rcx
    movq    (%rcx),              %rdi
    call    skip_spaces
    movq    %rax,                %rdi
    leaq    input_end(%rip),     %rcx
    movq    (%rcx),              %rbx
    cmpq    %rbx,                %rdi
    jge     .Lnt_eof
    movb    (%rdi),              %al
    testb   %al,                 %al
    jz      .Lnt_eof
    cmpb    $0x0a,               %al
    je      .Lnt_eof
    cmpb    $0x0d,               %al
    je      .Lnt_eof
    movq    %rdi,                %rax
    movq    %rdi,                %rcx
.Lnt_scan:
    cmpq    %rbx,                %rcx
    jge     .Lnt_scan_done
    movb    (%rcx),              %dl
    testb   %dl,                 %dl
    jz      .Lnt_scan_done
    cmpb    $0x0a,               %dl
    je      .Lnt_scan_done
    cmpb    $0x0d,               %dl
    je      .Lnt_scan_done
    cmpb    $0x20,               %dl
    je      .Lnt_scan_done
    incq    %rcx
    jmp     .Lnt_scan
.Lnt_scan_done:
    movq    %rcx,                %rdx
    subq    %rax,                %rdx
    leaq    tok_ptr(%rip),       %rdi
    movq    %rcx,                (%rdi)
    popq    %rbx
    ret
.Lnt_eof:
    xorq    %rax,                %rax
    xorq    %rdx,                %rdx
    leaq    tok_ptr(%rip),       %rcx
    movq    %rdi,                (%rcx)
    popq    %rbx
    ret


token_equals:
    movq    %rdi,                %r8
    movq    %rdx,                %r9
    movq    %rsi,                %rcx
.Lte_loop:
    testq   %rcx,                %rcx
    jz      .Lte_check_null
    movb    (%r8),               %al
    movb    (%r9),               %dl
    testb   %dl,                 %dl
    jz      .Lte_not_equal
    cmpb    %dl,                 %al
    jne     .Lte_not_equal
    incq    %r8
    incq    %r9
    decq    %rcx
    jmp     .Lte_loop
.Lte_check_null:
    movb    (%r9),               %dl
    testb   %dl,                 %dl
    jz      .Lte_equal
.Lte_not_equal:
    xorq    %rax,                %rax
    ret
.Lte_equal:
    movq    $1,                  %rax
    ret


parse_uint:
    xorq    %rax,                %rax
    movq    %rdi,                %rcx
    movq    %rsi,                %rdx
.Lpu_loop:
    testq   %rdx,                %rdx
    jz      .Lpu_done
    movzbl  (%rcx),              %r8d
    subl    $48,                 %r8d
    imulq   $10,                 %rax,    %rax
    addq    %r8,                 %rax
    incq    %rcx
    decq    %rdx
    jmp     .Lpu_loop
.Lpu_done:
    ret


find_dash:
    movq    %rdi,                %rcx
    movq    %rsi,                %rdx
.Lfd_loop:
    testq   %rdx,                %rdx
    jz      .Lfd_notfound
    movb    (%rcx),              %al
    cmpb    $0x2d,               %al
    je      .Lfd_found
    incq    %rcx
    decq    %rdx
    jmp     .Lfd_loop
.Lfd_found:
    movq    %rcx,                %rax
    ret
.Lfd_notfound:
    xorq    %rax,                %rax
    ret


extract_field:
    movq    %rdi,                %rax
    movq    %rdi,                %rcx
    movq    %rsi,                %r8
.Lef_loop:
    testq   %r8,                 %r8
    jz      .Lef_done
    movb    (%rcx),              %dl
    cmpb    $0x2d,               %dl
    je      .Lef_done
    incq    %rcx
    decq    %r8
    jmp     .Lef_loop
.Lef_done:
    movq    %rcx,                %rdx
    subq    %rax,                %rdx
    ret


identify_algo:
    pushq   %rbx
    pushq   %r12
    movq    %rdi,                %rbx
    movq    %rsi,                %r12
    leaq    str_fcfs(%rip),      %rdx
    call    token_equals
    testq   %rax,                %rax
    jz      .Lia_sjf
    movq    $ALGO_FCFS,          %rax
    jmp     .Lia_store
.Lia_sjf:
    movq    %rbx,                %rdi
    movq    %r12,                %rsi
    leaq    str_sjf(%rip),       %rdx
    call    token_equals
    testq   %rax,                %rax
    jz      .Lia_srtf
    movq    $ALGO_SJF,           %rax
    jmp     .Lia_store
.Lia_srtf:
    movq    %rbx,                %rdi
    movq    %r12,                %rsi
    leaq    str_srtf(%rip),      %rdx
    call    token_equals
    testq   %rax,                %rax
    jz      .Lia_pf
    movq    $ALGO_SRTF,          %rax
    jmp     .Lia_store
.Lia_pf:
    movq    %rbx,                %rdi
    movq    %r12,                %rsi
    leaq    str_pf(%rip),        %rdx
    call    token_equals
    testq   %rax,                %rax
    jz      .Lia_rr
    movq    $ALGO_PF,            %rax
    jmp     .Lia_store
.Lia_rr:
    movq    $ALGO_RR,            %rax
.Lia_store:
    leaq    algo_id(%rip),       %rcx
    movq    %rax,                (%rcx)
    popq    %r12
    popq    %rbx
    ret


parse_proc:
    pushq   %rbx
    pushq   %r12
    pushq   %r13
    pushq   %r14
    pushq   %r15
    movq    %rdi,                %rbx
    movq    %rsi,                %r12
    movq    %rdx,                %r13
    leaq    proc_count(%rip),    %rcx
    movq    (%rcx),              %r14
    imulq   $PROC_SIZE,          %r14,    %r15
    leaq    proc_array(%rip),    %rcx
    addq    %rcx,                %r15
    movq    %rbx,                %rdi
    movq    %r12,                %rsi
    call    extract_field
    movb    (%rax),              %cl
    movb    %cl,                 PROC_ID(%r15)
    addq    %rdx,                %rbx
    subq    %rdx,                %r12
    incq    %rbx
    decq    %r12
    movq    %rbx,                %rdi
    movq    %r12,                %rsi
    call    extract_field
    movq    %rax,                %rdi
    movq    %rdx,                %rsi
    addq    %rdx,                %rbx
    subq    %rdx,                %r12
    call    parse_uint
    movq    %rax,                PROC_BURST(%r15)
    cmpq    $ALGO_FCFS,          %r13
    je      .Lpp_arrival
    cmpq    $ALGO_SRTF,          %r13
    je      .Lpp_arrival
    cmpq    $ALGO_PF,            %r13
    je      .Lpp_arrival
    movq    $0,                  PROC_ARRIVAL(%r15)
    movq    $0,                  PROC_PRIORITY(%r15)
    jmp     .Lpp_finish
.Lpp_arrival:
    incq    %rbx
    decq    %r12
    movq    %rbx,                %rdi
    movq    %r12,                %rsi
    call    extract_field
    movq    %rax,                %rdi
    movq    %rdx,                %rsi
    addq    %rdx,                %rbx
    subq    %rdx,                %r12
    call    parse_uint
    movq    %rax,                PROC_ARRIVAL(%r15)
    cmpq    $ALGO_PF,            %r13
    jne     .Lpp_no_prio
    incq    %rbx
    decq    %r12
    movq    %rbx,                %rdi
    movq    %r12,                %rsi
    call    extract_field
    movq    %rax,                %rdi
    movq    %rdx,                %rsi
    call    parse_uint
    movq    %rax,                PROC_PRIORITY(%r15)
    jmp     .Lpp_finish
.Lpp_no_prio:
    movq    $0,                  PROC_PRIORITY(%r15)
.Lpp_finish:
    movq    %r14,                PROC_ORDER(%r15)
    leaq    proc_count(%rip),    %rcx
    incq    (%rcx)
    popq    %r15
    popq    %r14
    popq    %r13
    popq    %r12
    popq    %rbx
    ret


parse_input:
    pushq   %rbx
    pushq   %r12
    pushq   %r13
    call    next_token
    testq   %rdx,                %rdx
    jz      .Lpi_done
    movq    %rax,                %rdi
    movq    %rdx,                %rsi
    call    identify_algo
    movq    %rax,                %rbx
.Lpi_loop:
    call    next_token
    testq   %rdx,                %rdx
    jz      .Lpi_done
    movq    %rax,                %r12
    movq    %rdx,                %r13
    cmpq    $ALGO_RR,            %rbx
    jne     .Lpi_proc
    movq    %r12,                %rdi
    movq    %r13,                %rsi
    call    find_dash
    testq   %rax,                %rax
    jz      .Lpi_quantum
.Lpi_proc:
    movq    %r12,                %rdi
    movq    %r13,                %rsi
    movq    %rbx,                %rdx
    call    parse_proc
    jmp     .Lpi_loop
.Lpi_quantum:
    movq    %r12,                %rdi
    movq    %r13,                %rsi
    call    parse_uint
    leaq    rr_quantum(%rip),    %rcx
    movq    %rax,                (%rcx)
.Lpi_done:
    popq    %r13
    popq    %r12
    popq    %rbx
    ret
