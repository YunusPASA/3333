# schedsim.s
# Project 2 - SchedSim: CPU Scheduling Simulator
# CmpE 230, Systems Programming, Spring 2026
#
# Stage 4: Minimal buildable skeleton.
# Confirms: _start entry point, direct syscall I/O, no-libc build.
# No scheduling algorithm, tokenizer, or parser is implemented yet.

# ──────────────────────────────────────────────────────────────────────────────
    .section .rodata

newline_char:
    .byte   '\n'

# ──────────────────────────────────────────────────────────────────────────────
    .section .bss

    .balign 8
input_buf:
    .space  4096            # one full input line from stdin (well within spec)

    .balign 8
output_buf:
    .space  1025            # scheduling result: <=1024 output chars + newline

# ──────────────────────────────────────────────────────────────────────────────
    .section .text
    .global _start

# Program entry point.
# Current behavior (skeleton): read one line from stdin, write a single
# newline to stdout, exit 0.  All scheduling work is added in later stages.
_start:
    # ── read one input line from stdin ───────────────────────────────────────
    movq    $0,                  %rax    # syscall nr: read
    movq    $0,                  %rdi    # fd: stdin
    leaq    input_buf(%rip),     %rsi    # destination buffer
    movq    $4096,               %rdx    # max bytes to read
    syscall
    # rax = bytes read on success, negative on error (ignored in skeleton)

    # ── TODO stage 5: tokenize input_buf ─────────────────────────────────────
    # ── TODO stage 6: parse process descriptors ───────────────────────────────
    # ── TODO stage 7-9: dispatch algorithm, fill output_buf ──────────────────

    # ── write placeholder output to stdout ───────────────────────────────────
    # Replaced in later stages with the real output_buf write.
    movq    $1,                  %rax    # syscall nr: write
    movq    $1,                  %rdi    # fd: stdout
    leaq    newline_char(%rip),  %rsi    # single newline byte
    movq    $1,                  %rdx    # length: 1 byte
    syscall

    # ── exit cleanly ─────────────────────────────────────────────────────────
    movq    $60,                 %rax    # syscall nr: exit
    movq    $0,                  %rdi    # exit code: 0
    syscall
