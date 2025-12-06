module atomics

pub fn add_i32(dest &i32, delta i32) i32 {
	mut result := i32(0)
	// vfmt off
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
	// vfmt on
	return result
}

pub fn swap_i32(dest &i32, new i32) i32 {
	mut old := i32(0)
	// vfmt off
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
	// vfmt on
	return old
}

pub fn store_i32(dest &i32, value i32) {
	// vfmt off
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
	// vfmt on
}

pub fn load_i32(num &i32) i32 {
	mut out := i32(0)
	// vfmt off
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
	// vfmt on
	return out
}

pub fn cas_i32(addr &i32, old i32, new i32) bool {
	mut swapped := false
	// vfmt off
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
	// vfmt on
	return swapped
}

pub fn store_i64(dest &i64, value i64) {
	// vfmt off
	asm volatile i386 {
		mov esi, num
		test esi, 7
		jz aligned_store_i64_i386
		call panicUnaligned
		jmp done_store_i64_i386

	aligned_store_i64_i386:
		movq mm0, value
		movq [esi], mm0
		emms
		xor eax, eax
		lock xaddl [esp], eax

	done_store_i64_i386:
		;
		; r(dest) as dest
		  r(value) as value
		; esi eax esp mm0
		  memory
	}
	// vfmt on
}

pub fn load_i64(num &i64) i64 {
	mut out := i64(0)
	// vfmt off
	asm volatile i386 {
		movl esi, num
		testl esi, 7
		jz aligned_load_i64_i386
		call panicUnaligned
		jmp done_load_i64_i386

	aligned_load_i64_i386:
		movq mm0, [esi]
		movq out, mm0
		emms

	done_load_i64_i386:
		;+m(out)
		; r(num)
		; esi mm0
		  memory
	}
	// vfmt on
	return out
}

pub fn add_i64(dest &i64, delta i64) i64 {
	mut result := i64(0)
	// vfmt off
	asm volatile i386 {
		mov esi, dest
		test esi, 7
		jz aligned_add_i64_i386
		call panicUnaligned
		jmp done_add_i64_i386

	aligned_add_i64_i386:
	addloop_i64_i386:
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

	done_add_i64_i386:
		;=r(result)
		; r(delta) as delta
		  r(dest) as dest
		; eax ebx ecx esi
		  memory
	}
	// vfmt on
	return result
}

pub fn swap_i64(dest &i64, value i64) i64 {
	mut old := i64(0)
	// vfmt off
	asm volatile i386 {
		mov esi, dest
		test esi, 7
		jz aligned_add_i64_i386
		call panicUnaligned
		jmp done_add_i64_i386

	aligned_add_i64_i386:
		mov ebx, [delta]
		mov ecx, [delta + 4]

	addloop_i64_i386:
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

	done_add_i64_i386:
		; =r(old)
		; r(dest) r(value)
		; eax ebx ecx edx esi edi ebp
		  memory
	}
	// vfmt on
	return old
}

pub fn cas_i64(addr &i64, old i64, new i64) bool {
	mut swapped := false
	// vfmt off
	asm volatile i386 {
		mov esi, addr
		test esi, 7
		jz aligned_cas_i64_i386
		call panicUnaligned
		jmp done_cas_i64_i386

	aligned_cas_i64_i386:
		mov eax, [old]
		mov edx, [old + 4]
		mov ebx, [new]
		mov ecx, [new + 4]
		lock cmpxchg8b [esi]
		sete al
		mov swapped, al

	done_cas_i64_i386:
		;=r(swapped)
		;r(addr) r(old) r(new)
		; eax edx ebx ecx al
		  memory
	}
	// vfmt on
	return swapped
}

pub fn add_u32(dest &u32, delta u32) u32 {
	mut result := u32(0)
	// vfmt off
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
	// vfmt on
	return result
}

pub fn swap_u32(dest &u32, new u32) u32 {
	mut old := u32(0)
	// vfmt off
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
	// vfmt on
	return old
}

pub fn store_u32(dest &u32, value u32) {
	// vfmt off
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
	// vfmt on
}

pub fn load_u32(num &u32) u32 {
	mut out := u32(0)
	// vfmt off
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
	// vfmt on
	return out
}

pub fn cas_u32(addr &u32, old u32, new u32) bool {
	mut swapped := false
	// vfmt off
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
	// vfmt on
	return swapped
}

pub fn load_u64(num &u64) u64 {
	mut out := u64(0)
	// vfmt off
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
	// vfmt on
	return out
}

pub fn store_u64(dest &u64, value u64) {
	// vfmt off
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
	// vfmt on
}

pub fn add_u64(dest &u64, delta u64) u64 {
	mut result := u64(0)
	// vfmt off
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
	// vfmt on
	return result
}

pub fn swap_u64(dest &u64, value u64) u64 {
	mut old := u64(0)
	// vfmt off
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
	// vfmt on
	return old
}

pub fn cas_u64(addr &u64, old u64, new u64) bool {
	mut swapped := false
	// vfmt off
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
	// vfmt on
	return swapped
}
