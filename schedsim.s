   #PAZARTESİ BAŞLIYOR
   
    .equ    MAX_PROC,       10

    .equ    ALGO_FCFS,      0
    .equ    ALGO_SJF,       1
    .equ    ALGO_SRTF,      2
    .equ    ALGO_PF,        3
    .equ    ALGO_RR,        4

    .equ    PROC_ID,        0
    .equ    PROC_BURST,     8
    .equ    PROC_ARRIVAL,   16
    .equ    PROC_PRIORITY,  24
    .equ    PROC_REMAIN,    32
    .equ    PROC_ORDER,     40
    .equ    PROC_DONE,      48
    .equ    PROC_SIZE,      56

# constant data
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

# global buffers and tokenizer state
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
    .space  MAX_PROC * PROC_SIZE

# code section and entry point
    .section .text
    .global _start

proc_array:
    .space  MAX_PROC * PROC_SIZE

    .balign 8
out_len:
    .space  8

proc_array:
    .space  560

    .equ    PROC_DONE,      48
    .equ    PROC_SIZE,      56


    #PAZARTESİ BİTİYOR


    #CUMARTESİ BAŞLIYOR

# read stdin, initialize tokenizer bounds, write placeholder newline, exit
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
    jne     .Lstart_sjf
    call    sched_fcfs
    jmp     .Lstart_done
.Lstart_sjf:
    cmpq    $ALGO_SJF,           %rax
    jne     .Lstart_done
    call    sched_sjf
.Lstart_done:
    call    timeline_finalize
    call    timeline_write

    movq    $60,                 %rax
    movq    $0,                  %rdi
    syscall


# advance a pointer past consecutive space characters
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

# return the next space-delimited token and its length, and update tok_ptr
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

# compare a token against a null-terminated keyword of the same length
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

# convert a digit-only substring to an integer value
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

# find the first '-' character inside a bounded token
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

    #CUMARTESİ BİTİYOR


    #PAZAR BAŞLIYOR

# extract one field from a descriptor
extract_field:
    ret

# advance to the next field in a descriptor
advance_field:
    ret

# store one qword into the current process slot
store_proc_qword:
    ret

# identify the algorithm token
identify_algo:
    ret

# parse one process descriptor
parse_proc:
    ret

# parse the full input stream
parse_input:
    ret

movq    %rax,                PROC_BURST(%r15)
movq    %rax,                PROC_REMAIN(%r15)

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

    sjf_pick:
    pushq   %rbx
    pushq   %r12
    pushq   %r13
    movq    $-1,                 %rbx
    movq    $-1,                 %r12
    movq    $-1,                 %r13
    leaq    proc_count(%rip),    %rcx
    movq    (%rcx),              %rcx
    xorq    %rdx,                %rdx
    leaq    proc_array(%rip),    %r8
.Lsp_loop:
    cmpq    %rcx,                %rdx
    jge     .Lsp_done
    imulq   $PROC_SIZE,          %rdx,    %r9
    movq    PROC_DONE(%r8,%r9,1),%rax
    testq   %rax,                %rax
    jnz     .Lsp_next
    movq    PROC_BURST(%r8,%r9,1),%rax
    cmpq    %r12,                %rax
    jb      .Lsp_update
    ja      .Lsp_next
    movq    PROC_ORDER(%r8,%r9,1),%rax
    cmpq    %r13,                %rax
    jae     .Lsp_next
    movq    %rax,                %r13
    movq    %rdx,                %rbx
    jmp     .Lsp_next
.Lsp_update:
    movq    %rax,                %r12
    movq    PROC_ORDER(%r8,%r9,1),%r13
    movq    %rdx,                %rbx
.Lsp_next:
    incq    %rdx
    jmp     .Lsp_loop
.Lsp_done:
    movq    %rbx,                %rax
    popq    %r13
    popq    %r12
    popq    %rbx
    ret


sched_sjf:
    pushq   %rbx
.Lsj_outer:
    call    fcfs_all_done
    testq   %rax,                %rax
    jnz     .Lsj_end
    call    sjf_pick
    imulq   $PROC_SIZE,          %rax,    %rax
    leaq    proc_array(%rip),    %rcx
    addq    %rcx,                %rax
    pushq   %rax
    movq    PROC_BURST(%rax),    %rcx
    movzbl  PROC_ID(%rax),       %edi
.Lsj_run:
    pushq   %rdi
    pushq   %rcx
    call    timeline_append
    popq    %rcx
    popq    %rdi
    decq    %rcx
    jnz     .Lsj_run
    popq    %rax
    movq    $1,                  PROC_DONE(%rax)
    jmp     .Lsj_outer
.Lsj_end:
    popq    %rbx
    ret


    #PAZAR BİTİYOR