module atomics

pub fn load_u64(num &u64) u64 {
    mut out := u64(0)

    $if amd64 {
        asm volatile amd64 {
            mov rdx, num
            test rdx, 7
            jz aligned_load_u64
            call panicUnaligned
            jmp done_load_u64

        aligned_load_u64:
            mov rax, [rdx]
            mov out, rax

        done_load_u64:
            ; =r(out)
            ; r(num)
            ; rax rdx
              memory
        }
    } $else $if i386 {
        asm volatile i386 {
            mov esi, num
            test esi, 7
            jz aligned_load_i64_i386
            call panicUnaligned
            jmp done_load_i64_i386

        aligned_load_i64_i386:
            movq mm0, [esi]
            movq [out], mm0
            emms

        done_load_i64_i386:
            ; =r(out)
            ; r(num)
            ; esi mm0
              memory
        }
    } $else {
        panic('atomic load_u64: unsupported arch')
    }

    return out
}

pub fn store_u64(dest &u64, value u64) {
    $if amd64 {
        asm volatile amd64 {
            mov rdx, dest
            test rdx, 7
            jz aligned_store_u64_amd64
            call panicUnaligned
            jmp done_store_u64_amd64

        aligned_store_u64_amd64:
            mov rax, value
            xchg rax, [rdx]

        done_store_u64_amd64:
            ;
            ;r(dest) as dest
             r(value) as value
            ; rax rdx
              memory
        }
    } $else $if i386 {
        asm volatile i386 {
            mov esi, num
            test esi, 7
            jz aligned_store_u64_i386
            call panicUnaligned
            jmp done_store_u64_i386

        aligned_store_u64_i386:
            movq mm0, value
            movq [esi], mm0
            emms
            xor eax, eax
            lock xaddl [esp], eax

        done_store_u64_i386:
            ;
            ; r(dest) as dest
              r(value) as value
            ; esi eax esp mm0
              memory
        }
    } $else {
        panic('atomic store_u64: unsupported arch')
    }
}

pub fn add_u64(dest &u64, delta u64) u64 {
    mut result := u64(0)

    $if amd64 {
        asm volatile amd64 {
            mov rdx, dest
            test rdx, 7
            jz aligned_add_u64_amd64
            call panicUnaligned
            jmp done_add_u64_amd64

        aligned_add_u64_amd64:
            mov rax, delta
            lock xadd [rdx], rax
            add rax, delta
            mov result, rax

        done_add_u64_amd64:
            ; =r(result)
            ; r(dest) r(delta)
            ; rax rdx
              memory
        }
    } $else $if i386 {
        asm volatile i386 {
            mov esi, dest
            test esi, 7
            jz aligned_add_u64_i386
            call panicUnaligned
            jmp done_add_u64_i386

        aligned_add_u64_i386:
        addloop_u64_i386:
            mov edi, [esi]
            mov ebp, [esi + 4]
            add edi, [delta]
            adc ebp, [delta + 4]
            mov ebx, edi
            mov ecx, ebp
            lock cmpxchg8b [esi]
            jnz addloop_i64_i386
            mov [result], edi
            mov [result + 4], ebp

        done_add_u64_i386:
            ;=r(result)
            ; r(delta) as delta
              r(dest) as dest
            ; eax ebx ecx esi
              memory
        }
    } $else {
        panic('atomic add_u64: unsupported arch')
    }
    return result
}

pub fn swap_u64(dest &u64, value u64) u64 {
    mut old := u64(0)

    $if amd64 {
        asm volatile amd64 {
            mov rdx, dest
            test rdx, 7
            jz aligned_swap_u64
            call panicUnaligned
            jmp done_swap_u64

        aligned_swap_u64:
            mov rax, value
            xchg [rdx], rax
            mov old, rax

        done_swap_u64:
            ; =r(old)
            ; r(dest) r(value)
            ; rax rdx
              memory
        }
    } $else $if i386 {
        asm volatile i386 {
            mov esi, dest
            test esi, 7
            jz aligned_add_u64_i386
            call panicUnaligned
            jmp done_add_u64_i386

        aligned_add_u64_i386:
            mov ebx, [delta]
            mov ecx, [delta + 4]

        addloop_u64_i386:
            mov eax, [esi]
            mov edx, [esi + 4]
            mov edi, eax
            mov ebp, edx
            add edi, ebx
            adc ebp, ecx
            mov ebx, edi
            mov ecx, ebp
            lock cmpxchg8b [esi]
            jnz addloop_i64_i386
            mov [old], edi
            mov [old + 4], ebp

        done_add_u64_i386:
            ; =r(old)
            ; r(dest) r(value)
            ; eax ebx ecx edx esi edi ebp
              memory
        }
    } $else {
        panic('atomic swap_u64: unsupported arch')
    }

    return old
}

pub fn cas_u64(addr &u64, old u64, new u64) bool {
    mut swapped := false

    $if amd64 {
        asm volatile amd64 {
            mov rdx, addr
            test rdx, 4
            jz aligned_cas_u64_amd64
            call panicUnaligned
            jmp done_cas_u64_amd64

        aligned_cas_u64_amd64:
            mov rax, old
            mov rcx, new
            lock cmpxchgq [rdx], rcx
            sete al
            mov swapped, al

        done_cas_u64_amd64:
            ;=r(swapped)
            ;r(addr) r(old) r(new)
            ; rax rcx rdx
              memory
        }
    } $else $if i386 {
        asm volatile i386 {
            mov esi, addr
            test esi, 7
            jz aligned_cas_u64_i386
            call panicUnaligned
            jmp done_cas_u64_i386

        aligned_cas_u64_i386:
            mov eax, [old]
            mov edx, [old + 4]
            mov ebx, [new]
            mov ecx, [new + 4]
            lock cmpxchg8b [esi]
            sete al
            mov swapped, al

        done_cas_u64_i386:
            ;=r(swapped)
            ;r(addr) r(old) r(new)
            ; eax edx ebx ecx al
              memory
        }
    } $else {
        panic('atomic cas_u64: unsupported arch')
    }
    return swapped
}
