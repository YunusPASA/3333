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
    .equ    PROC_SIZE,      48

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

    call    parse_input

    movq    $1,                  %rax
    movq    $1,                  %rdi
    leaq    newline_char(%rip),  %rsi
    movq    $1,                  %rdx
    syscall

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