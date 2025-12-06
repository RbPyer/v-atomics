module atomics


pub fn add_i32(dest &i32, delta i32) i32 {
	mut result := i32(0)
	$if amd64 {
		asm volatile amd64 {
			mov rdx, dest
			// check 4-byte alignment: ZF=1 if (rdx & 3) == 0	
			test rdx, 3
			jz aligned_add_i32_amd64
			call panicUnaligned
			jmp done_add_i32_amd64

		aligned_add_i32_amd64:
			mov eax, delta
			lock xadd [rdx], eax
			add eax, delta
			mov result, eax

		done_add_i32_amd64:
			; =r(result)
			;  r(dest) r(delta)
			;  eax rdx
			   memory
		}
	} $else $if i386 {
		asm volatile i386 {
			mov edx, dest
			// check 4-byte alignment: ZF=1 if (rdx & 3) == 0	
			test edx, 3
			jz aligned_add_i32_i386
			call panicUnaligned
			jmp done_add_i32_i386

		aligned_add_i32_i386:
			mov eax, delta
			lock xadd [edx], eax
			add eax, delta
			mov result, eax

		done_add_i32_i386:
			; =r(result)
			;  r(dest) r(delta)
			;  eax edx
			   memory
		}
	} $else {
		panic('atomic_add_i32: unsupported arch')
	}

	return result
}

pub fn swap_i32(dest &i32, new i32) i32 {
	mut old := i32(0)

	$if amd64 {
		asm volatile amd64 {
			mov rdx, dest
			// check 4-byte alignment: ZF=1 if (rdx & 3) == 0		
			test rdx, 3
			jz aligned_swap_i32_amd64
			call panicUnaligned
			jmp done_swap_i32_amd64

		aligned_swap_i32_amd64:
			mov eax, new
			xchg [rdx], eax
			mov old, eax
		
		done_swap_i32_amd64:
			; =r(old)
			; r(dest) as dest
			  r(new) as new
			; eax rdx
			  memory
		}
	} $else $if i386 {
		asm volatile i386 {		
			mov edx, dest
			// check 4-byte alignment: ZF=1 if (rdx & 3) == 0					
			test edx, 3
			jz aligned_swap_i32_i386
			call panicUnaligned
			jmp done_swap_i32_i386

		aligned_swap_i32_i386:
			mov eax, val
			xchg [edx], eax
			mov old, eax

		done_swap_i32_i386:
			; =r(old)
			;  r(dest) r(new)
			;  eax edx
			   memory
		}
	} $else {
		panic('atomic_swap_i32: unsupported arch')
	}

	return old
}


pub fn store_i32(dest &i32, value i32) {
	$if amd64 {
		asm volatile amd64 {
			mov rdx, dest
			// check 4-byte alignment: ZF=1 if (rdx & 3) == 0				
			test rdx, 3
			jz aligned_store_i32_amd64
			call panicUnaligned
			jmp done_store_i32_amd64

		aligned_store_i32_amd64:
			mov eax, value
			xchg eax, [rdx]

		done_store_i32_amd64:
			;
			; r(dest) as dest
			  r(value) as value
			; eax rdx memory
		}
	} $else $if i386 {
		asm volatile i386 {
			mov edx, dest
			// check 4-byte alignment: ZF=1 if (rdx & 3) == 0	
			test edx, 3
			jz aligned_store_i32_i386
			call panicUnaligned
			jmp done_store_i32_i386

		aligned_store_i32_i386:
			mov eax, value
			xchg eax, [edx]

		done_store_i32_i386:
			;
			;r(dest) as dest
			 r(value) as value
			; eax rdx memory 		
		}
	} $else {
		panic('atomic_store_i32: unsupported arch')
	}
}


pub fn load_i32(num &i32) i32 {
	mut out := i32(0)

	$if amd64 {
		asm volatile amd64 {
			mov rdx, num
			// check 4-byte alignment: ZF=1 if (rdx & 4) == 0
			test rdx, 3
			jz aligned_load_i32_amd64
			call panicUnaligned
			jmp done_load_i32_amd64

		aligned_load_i32_amd64:
			mov eax, [rdx]
			mov out, eax

		done_load_i32_amd64:
			; =r(out)
			; r(num)
			; eax rdx
			  memory
		}
	} $else $if i386 {
		asm volatile i386 {
			mov edx, num
			test edx, 3
			jz aligned_load_i32_i386
			call panicUnaligned
			jmp done_load_i32_i386

		aligned_load_i32_i386:
			mov eax, [edx]
			mov out, eax
		
		done_load_i32_i386:
			; =r(out)
			; r(num)
			; eax edx
			  memory
		}
	} $else {
		panic('atomic_load_i32: unsupported arch')
	}

	return out
}


pub fn cas_i32(addr &i32, old i32, new i32) bool {
	mut swapped := false;

	$if amd64 {
		asm volatile amd64 {
			mov rdx, addr
			// check 4-byte alignment: ZF=1 if (rdx & 3) == 0		
			test rdx, 3
			jz aligned_cas_i32_amd64
			call panicUnaligned
			jmp done_cas_i32_amd64

		aligned_cas_i32_amd64:
			mov eax, old
			mov ecx, new
			lock cmpxchg [rdx], ecx
			sete al
			mov swapped, al

		done_cas_i32_amd64:
			;=r(swapped)
			;r(addr) r(old) r(new)
			; eax ecx rdx
			  memory	
		}
	} $else $if i386 {
		asm volatile i386 {
			mov edx, addr
			test edx, 3
			jz aligned_cas_i32_i386
			call panicUnaligned
			jmp done_cas_i32_i386

		aligned_cas_i32_i386:
			mov eax, old
			mov ecx, new
			lock cmpxchg [edx], ecx
			sete al
			mov swapped, al

		done_cas_i32_i386:
			;=r(swapped)
			;r(addr) r(old) r(new)
			; eax ecx edx
			  memory
		}
	} $else {
		panic('atomoc_cas_i32: unsupported arch')
	}
	return swapped
}