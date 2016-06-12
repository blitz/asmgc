;; -*- Mode: nasm -*-

DEFAULT REL
BITS 64

%include "gc.inc"

GLOBAL garbage_collect

SECTION .text

garbage_collect:
  ; Nothing here yet.
  ud2a


;; EOF
