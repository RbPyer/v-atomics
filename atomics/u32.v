module atomics


pub fn add_u32(dest &u32, delta u32) u32 {
	mut result := u32(0)
	$if amd64 {
		asm volatile amd64 {
			mov rdx, dest
			//  check 4-byte alignment: ZF=1 if (rdx & 3) == 0
			test rdx, 3
			jz aligned_add_u32_amd64
			call panicUnaligned
			jmp done_add_u32_amd64

		aligned_add_u32_amd64:
			mov eax, delta
			lock xadd [rdx], eax
			add eax, delta
			mov result, eax

		done_add_u32_amd64:
			; =r(result)
			;  r(dest) r(delta)
			;  rax rdx
			   memory
		}
	} $else $if i386 {
		asm volatile i386 {
			mov edx, dest
			// check 4-byte alignment: ZF=1 if (edx & 3) == 0
			test edx, 3
			jz aligned_add_u32_i386
			call panicUnaligned
			jmp done_add_u32_i386

		aligned_add_u32_i386:
			mov eax, delta
			lock xadd [edx], eax
			add eax, delta
			mov result, eax

		done_add_u32_i386:
			; =r(result)
			;  r(dest) r(delta)
			;  eax edx
			   memory
		}
	} $else { panic('atomic_add_u32: unsupported arch') }
	return result
}


pub fn swap_u32(dest &u32, new u32) u32 {
	mut old := u32(0)

	$if amd64 {
		asm volatile amd64 {
			mov rdx, dest
			// check 4-byte alignment: ZF=1 if (rdx & 3) == 0		
			test rdx, 3
			jz aligned_swap_u32_amd64
			call panicUnaligned
			jmp done_swap_u32_amd64

		aligned_swap_u32_amd64:
			mov eax, new
			xchg [rdx], eax
			mov old, eax
		
		done_swap_u32_amd64:
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
			jz aligned_swap_u32_i386
			call panicUnaligned
			jmp done_swap_u32_i386

		aligned_swap_u32_i386:
			mov eax, val
			xchg [edx], eax
			mov old, eax

		done_swap_u32_i386:
			; =r(old)
			;  r(dest) r(new)
			;  eax edx
			   memory
		}
	} $else {
		panic('atomic_swap_u32: unsupported arch')
	}

	return old
}

pub fn store_u32(dest &u32, value u32) {
	$if amd64 {
		asm volatile amd64 {
			mov rdx, dest
			// check 4-byte alignment: ZF=1 if (rdx & 3) == 0				
			test rdx, 3
			jz aligned_store_u32_amd64
			call panicUnaligned
			jmp done_store_u32_amd64

		aligned_store_u32_amd64:
			mov eax, value
			xchg eax, [rdx]

		done_store_u32_amd64:
			;
			; r(dest) as dest
			  r(value) as value
			; eax rdx
			  memory
		}
	} $else $if i386 {
		asm volatile i386 {
			mov edx, dest
			// check 4-byte alignment: ZF=1 if (rdx & 3) == 0	
			test edx, 3
			jz aligned_store_u32_i386
			call panicUnaligned
			jmp done_store_u32_i386

		aligned_store_u32_i386:
			mov eax, value
			xchg eax, [edx]

		done_store_u32_i386:
			;
			;r(dest) as dest
			 r(value) as value
			; eax edx
			  memory 		
		}
	} $else {
		panic('atomic_store_u32: unsupported arch')
	}
}


pub fn load_u32(num &u32) u32 {
	mut out := u32(0)

	$if amd64 {
		asm volatile amd64 {
			mov rdx, num
			// check 4-byte alignment: ZF=1 if (rdx & 4) == 0
			test rdx, 3
			jz aligned_load_u32
			call panicUnaligned
			jmp done_load_u32

		aligned_load_u32:
			mov eax, [rdx]
			mov out, eax

		done_load_u32:
			; =r(out)
			; r(num)
			; rax rdx
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
		panic('atomic_load_u32: unsupported arch')
	}

	return out
}


pub fn cas_u32(addr &u32, old u32, new u32) bool {
	mut swapped := false;

	$if amd64 {
		asm volatile amd64 {
			mov rdx, addr
			// check 4-byte alignment: ZF=1 if (rdx & 3) == 0		
			test rdx, 3
			jz aligned_cas_u32_amd64
			call panicUnaligned
			jmp done_cas_u32_amd64

		aligned_cas_u32_amd64:
			mov eax, old
			mov ecx, new
			lock cmpxchg [rdx], ecx
			sete al
			mov swapped, al

		done_cas_u32_amd64:
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
		panic('atomoc_cas_u32: unsupported arch')
	}

	return swapped
}