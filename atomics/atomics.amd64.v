module atomics

pub fn add_i32(dest &i32, delta i32) i32 {
	mut result := i32(0)
	// vfmt off
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
	// vfmt on
	return result
}

pub fn swap_i32(dest &i32, new i32) i32 {
	mut old := i32(0)
	// vfmt off
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
	// vfmt on
	return old
}

pub fn store_i32(dest &i32, value i32) {
	// vfmt off
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
	// vfmt on
}

pub fn load_i32(num &i32) i32 {
	mut out := i32(0)
	// vfmt off
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
	// vfmt on
	return out
}

pub fn cas_i32(addr &i32, old i32, new i32) bool {
	// vfmt off
	mut swapped := false;
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
	// vfmt on
	return swapped
}

pub fn store_i64(dest &i64, value i64) {
	// vfmt off
	asm volatile amd64 {
		mov rdx, dest
		test rdx, 7
		jz aligned_store_i64_amd64
		call panicUnaligned
		jmp done_store_i64_amd64

	aligned_store_i64_amd64:
		mov rax, value
		xchg rax, [rdx]
		jmp done_store_i64_amd64

	done_store_i64_amd64:
		;
		; r(dest) as dest
		  r(value) as value
		; rax rdx
		  memory
	}
	// vfmt on
}

pub fn load_i64(num &i64) i64 {
	// vfmt off
	mut out := i64(0)
	asm volatile amd64 {
		mov rdx, num
		test rdx, 7
		jz aligned_load_i64_amd64
		call panicUnaligned
		jmp done_load_i64_amd64

	aligned_load_i64_amd64:
		mov rax, [rdx]
		mov out, rax

	done_load_i64_amd64:
		; =r(out)
		; r(num)
		; rax rdx
		  memory
	}
	// vfmt on
	return out
}

pub fn add_i64(dest &i64, delta i64) i64 {
	mut result := i64(0)
	// vfmt off
	asm volatile amd64 {
		mov rdx, dest
		test rdx, 7
		jz aligned_add_i64_amd64
		call panicUnaligned
		jmp done_add_i64_amd64

	aligned_add_i64_amd64:
		mov rax, delta
		lock xadd [rdx], rax
		add rax, delta
		mov result, rax

	done_add_i64_amd64:
		; =r(result) as result
		; r(delta) as delta
		  r(dest) as dest
		; rax rdx
		  memory
	}
	// vfmt on
	return result
}

pub fn swap_i64(dest &i64, value i64) i64 {
	mut old := i64(0)
	// vfmt off
	asm volatile amd64 {
		mov rdx, dest
		test rdx, 7
		jz aligned_swap_i64_amd64
		call panicUnaligned
		jmp done_swap_i64_amd64

	aligned_swap_i64_amd64:
		mov rax, value
		xchg rax, [rdx]
		mov old, rax

	done_swap_i64_amd64:
		; =r(old)
		; r(dest) r(value)
		; rax rdx
		  memory
	}
	// vfmt on
	return old
}

pub fn cas_i64(addr &i64, old i64, new i64) bool {
	mut swapped := false
	// vfmt off
	asm volatile amd64 {
		mov rdx, addr
		test rdx, 7
		jz aligned_cas_i64_amd64
		call panicUnaligned
		jmp done_cas_i64_amd64

	aligned_cas_i64_amd64:
		mov rax, old
		mov rcx, new
		lock cmpxchgq [rdx], rcx
		sete al
		mov swapped, al

	done_cas_i64_amd64:
		;=r(swapped)
		;r(addr) r(old) r(new)
		; rax rcx rdx al
		  memory
	}
	// vfmt on
	return swapped
}

pub fn add_u32(dest &u32, delta u32) u32 {
	mut result := u32(0)
	// vfmt off
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
	// vfmt on
	return result
}

pub fn swap_u32(dest &u32, new u32) u32 {
	mut old := u32(0)
	// vfmt off
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
	// vfmt on
	return old
}

pub fn store_u32(dest &u32, value u32) {
	// vfmt off
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
	// vfmt on
}

pub fn load_u32(num &u32) u32 {
	mut out := u32(0)
	// vfmt off
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
	// vfmt on
	return out
}

pub fn cas_u32(addr &u32, old u32, new u32) bool {
	mut swapped := false
	// vfmt off
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
	// vfmt on
	return swapped
}

pub fn load_u64(num &u64) u64 {
	mut out := u64(0)
	// vfmt off
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
	// vfmt on
	return out
}

pub fn store_u64(dest &u64, value u64) {
	// vfmt off
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
	// vfmt on
}

pub fn add_u64(dest &u64, delta u64) u64 {
	mut result := u64(0)
	// vfmt off
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
	// vfmt on
	return result
}

pub fn swap_u64(dest &u64, value u64) u64 {
	// vfmt off
	mut old := u64(0)
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
	// vfmt on
	return old
}

pub fn cas_u64(addr &u64, old u64, new u64) bool {
	mut swapped := false
	// vfmt off
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
	// vfmt on
	return swapped
}
