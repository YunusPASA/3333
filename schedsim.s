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
    .equ    PROC_REMAIN,    40
    .equ    PROC_DONE,      48
    .equ    PROC_SIZE,      56

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
    .space  560

    .balign 8
out_len:
    .space  8

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

    call    timeline_init
    call    parse_input

    leaq    algo_id(%rip),       %rcx
    movq    (%rcx),              %rax
    cmpq    $ALGO_FCFS,          %rax
    jne     .Lstart_done
    call    sched_fcfs
.Lstart_done:
    call    timeline_finalize
    call    timeline_write

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
    movq    %rax,                PROC_REMAIN(%r15)
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


fcfs_all_done:
    leaq    proc_count(%rip),    %rcx
    movq    (%rcx),              %rcx
    xorq    %rdx,                %rdx
    leaq    proc_array(%rip),    %r8
.Lfad_loop:
    cmpq    %rcx,                %rdx
    jge     .Lfad_yes
    imulq   $PROC_SIZE,          %rdx,    %r9
    movq    PROC_DONE(%r8,%r9,1),%rax
    testq   %rax,                %rax
    jz      .Lfad_no
    incq    %rdx
    jmp     .Lfad_loop
.Lfad_yes:
    movq    $1,                  %rax
    ret
.Lfad_no:
    xorq    %rax,                %rax
    ret


fcfs_pick:
    pushq   %rbx
    pushq   %r12
    pushq   %r13
    pushq   %r14
    movq    %rdi,                %r14
    movq    $-1,                 %rbx
    movq    $-1,                 %r12
    movq    $-1,                 %r13
    leaq    proc_count(%rip),    %rcx
    movq    (%rcx),              %rcx
    xorq    %rdx,                %rdx
    leaq    proc_array(%rip),    %r8
.Lfp_loop:
    cmpq    %rcx,                %rdx
    jge     .Lfp_done
    imulq   $PROC_SIZE,          %rdx,    %r9
    movq    PROC_DONE(%r8,%r9,1),%rax
    testq   %rax,                %rax
    jnz     .Lfp_next
    movq    PROC_ARRIVAL(%r8,%r9,1),%rax
    cmpq    %r14,                %rax
    ja      .Lfp_next
    cmpq    %r12,                %rax
    jb      .Lfp_update
    ja      .Lfp_next
    movq    PROC_ORDER(%r8,%r9,1),%rax
    cmpq    %r13,                %rax
    jae     .Lfp_next
    movq    %rax,                %r13
    movq    %rdx,                %rbx
    jmp     .Lfp_next
.Lfp_update:
    movq    %rax,                %r12
    movq    PROC_ORDER(%r8,%r9,1),%r13
    movq    %rdx,                %rbx
.Lfp_next:
    incq    %rdx
    jmp     .Lfp_loop
.Lfp_done:
    movq    %rbx,                %rax
    popq    %r14
    popq    %r13
    popq    %r12
    popq    %rbx
    ret


sched_fcfs:
    pushq   %rbx
    xorq    %rbx,                %rbx
.Lfc_outer:
    call    fcfs_all_done
    testq   %rax,                %rax
    jnz     .Lfc_end
    movq    %rbx,                %rdi
    call    fcfs_pick
    cmpq    $-1,                 %rax
    je      .Lfc_idle
    imulq   $PROC_SIZE,          %rax,    %rax
    leaq    proc_array(%rip),    %rcx
    addq    %rcx,                %rax
    pushq   %rax
    movq    PROC_BURST(%rax),    %rcx
    movzbl  PROC_ID(%rax),       %edi
.Lfc_run:
    pushq   %rdi
    pushq   %rcx
    call    timeline_append
    popq    %rcx
    popq    %rdi
    incq    %rbx
    decq    %rcx
    jnz     .Lfc_run
    popq    %rax
    movq    $1,                  PROC_DONE(%rax)
    jmp     .Lfc_outer
.Lfc_idle:
    call    timeline_append_idle
    incq    %rbx
    jmp     .Lfc_outer
.Lfc_end:
    popq    %rbx
    ret


timeline_init:
    leaq    out_len(%rip),       %rcx
    movq    $0,                  (%rcx)
    ret


timeline_append:
    leaq    out_len(%rip),       %rcx
    movq    (%rcx),              %rax
    leaq    output_buf(%rip),    %rdx
    movb    %dil,                (%rdx,%rax,1)
    incq    %rax
    movq    %rax,                (%rcx)
    ret


timeline_append_idle:
    movq    $0x58,               %rdi
    jmp     timeline_append


timeline_finalize:
    movq    $0x0a,               %rdi
    jmp     timeline_append


timeline_write:
    leaq    out_len(%rip),       %rcx
    movq    (%rcx),              %rdx
    movq    $1,                  %rax
    movq    $1,                  %rdi
    leaq    output_buf(%rip),    %rsi
    syscall
    ret
