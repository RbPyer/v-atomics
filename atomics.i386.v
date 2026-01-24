module atomics

pub fn add_i32(dest &i32, delta i32) i32 {
	mut result := i32(0)
	// vfmt off
	$if prod {
		asm volatile i386 {
			mov edx, dest
			test edx, 3
			jz '1f'
			ud2
			jmp '2f'

		1:
			mov eax, delta
			lock xadd [edx], eax
			add eax, delta
			mov result, eax

		2:
			; =r(result)
			;  r(dest) r(delta)
			;  eax edx
			   memory
		}
	} $else {
		asm volatile i386 {
			mov edx, dest
			test edx, 3
			jz '1f'
			call panicUnaligned
			jmp '2f'

		1:
			mov eax, delta
			lock xadd [edx], eax
			add eax, delta
			mov result, eax

		2:
			; =r(result)
			;  r(dest) r(delta)
			;  eax edx
			   memory
		}
	}
	// vfmt on
	return result
}

pub fn swap_i32(dest &i32, new i32) i32 {
	mut old := i32(0)
	// vfmt off
	$if prod {
		asm volatile i386 {
			mov edx, dest
			test edx, 3
			jz '1f'
			ud2
			jmp '2f'

		1:
			mov eax, new
			xchg [edx], eax
			mov old, eax

		2:
			; =m(old)
			;  r(dest) r(new)
			;  eax edx
			   memory
		}
	} $else {
		asm volatile i386 {
			mov edx, dest
			test edx, 3
			jz '1f'
			call panicUnaligned
			jmp '2f'

		1:
			mov eax, new
			xchg [edx], eax
			mov old, eax

		2:
			; =m(old)
			;  r(dest) r(new)
			;  eax edx
			   memory
		}
	}
	// vfmt on
	return old
}

pub fn store_i32(dest &i32, value i32) {
	// vfmt off
	$if prod {
		asm volatile i386 {
			mov edx, dest
			test edx, 3
			jz '1f'
			ud2
			jmp '2f'

		1:
			mov eax, value
			xchg eax, [edx]

		2:
			;
			; r(dest) as dest
			  r(value) as value
			; eax edx memory
		}
	} $else {
		asm volatile i386 {
			mov edx, dest
			test edx, 3
			jz '1f'
			call panicUnaligned
			jmp '2f'

		1:
			mov eax, value
			xchg eax, [edx]

		2:
			;
			; r(dest) as dest
			  r(value) as value
			; eax edx memory
		}
	}
	// vfmt on
}

pub fn load_i32(num &i32) i32 {
	mut out := i32(0)
	// vfmt off
	$if prod {
		asm volatile i386 {
			mov edx, num
			test edx, 3
			jz '1f'
			ud2
			jmp '2f'

		1:
			mov eax, [edx]
			mov out, eax

		2:
			; =r(out)
			; r(num)
			; eax edx
			  memory
		}
	} $else {
		asm volatile i386 {
			mov edx, num
			test edx, 3
			jz '1f'
			call panicUnaligned
			jmp '2f'

		1:
			mov eax, [edx]
			mov out, eax

		2:
			; =r(out)
			; r(num)
			; eax edx
			  memory
		}
	}
	// vfmt on
	return out
}

pub fn cas_i32(addr &i32, old i32, new i32) bool {
	mut swapped := false
	// vfmt off
	$if prod {
		asm volatile i386 {
			mov edx, addr
			test edx, 3
			jz '1f'
			ud2
			jmp '2f'

		1:
			mov eax, old
			mov ecx, new
			lock cmpxchg [edx], ecx
			sete al
			mov swapped, al

		2:
			;=m(swapped)
			;r(addr) r(old) r(new)
			; eax ecx edx
			  memory
		}
	} $else {
		asm volatile i386 {
			mov edx, addr
			test edx, 3
			jz '1f'
			call panicUnaligned
			jmp '2f'

		1:
			mov eax, old
			mov ecx, new
			lock cmpxchg [edx], ecx
			sete al
			mov swapped, al

		2:
			;=m(swapped)
			;r(addr) r(old) r(new)
			; eax ecx edx
			  memory
		}
	}
	// vfmt on
	return swapped
}

pub fn store_i64(dest &i64, value i64) {
	// vfmt off
	$if prod {
		asm volatile i386 {
			mov esi, dest
			test esi, 7
			jz '1f'
			ud2
			jmp '2f'

		1:
			movq mm0, value
			movq [esi], mm0
			emms
			xor eax, eax
			lock xaddl [esp], eax

		2:
			;
			; r(dest) as dest
			  m(value) as value
			; esi eax mm0
			  memory
		}
	} $else {
		asm volatile i386 {
			mov esi, dest
			test esi, 7
			jz '1f'
			call panicUnaligned
			jmp '2f'

		1:
			movq mm0, value
			movq [esi], mm0
			emms
			xor eax, eax
			lock xaddl [esp], eax

		2:
			;
			; r(dest) as dest
			  m(value) as value
			; esi eax mm0
			  memory
		}
	}
	// vfmt on
}

pub fn load_i64(num &i64) i64 {
	mut out := i64(0)
	// vfmt off
	$if prod {
		asm volatile i386 {
			mov esi, num
			test esi, 7
			jz '1f'
			ud2
			jmp '2f'

		1:
			movq mm0, [esi]
			movq out, mm0
			emms

		2:
			; =m(out)
			; r(num)
			; esi mm0
			  memory
		}
	} $else {
		asm volatile i386 {
			mov esi, num
			test esi, 7
			jz '1f'
			call panicUnaligned
			jmp '2f'

		1:
			movq mm0, [esi]
			movq out, mm0
			emms

		2:
			; =m(out)
			; r(num)
			; esi mm0
			  memory
		}
	}
	// vfmt on
	return out
}

pub fn add_i64(dest &i64, delta i64) i64 {
	mut delta_lo := u32(u64(delta) & 0xFFFF_FFFF)
	mut delta_hi := u32(u64(delta) >> 32)
	mut res_lo := u32(0)
	mut res_hi := u32(0)
	// vfmt off
	$if prod {
		asm volatile i386 {
			mov esi, dest
			test esi, 7
			jz '1f'
			ud2
			jmp '2f'

		1:
		3:
			mov eax, [esi]
			mov edx, [esi + 4]

			mov ebx, eax
			mov ecx, edx
			add ebx, delta_lo
			adc ecx, delta_hi

			lock cmpxchg8b [esi]
			jnz '3b'

			mov res_lo, ebx
			mov res_hi, ecx

		2:
			;
			; r(dest)      as dest
			  m(delta_lo)  as delta_lo
			  m(delta_hi)  as delta_hi
			  m(res_lo)    as res_lo
			  m(res_hi)    as res_hi
			; eax ebx ecx edx esi
			  memory
		}
	} $else {
		asm volatile i386 {
			mov esi, dest
			test esi, 7
			jz '1f'
			call panicUnaligned
			jmp '2f'

		1:
		3:
			mov eax, [esi]
			mov edx, [esi + 4]

			mov ebx, eax
			mov ecx, edx
			add ebx, delta_lo
			adc ecx, delta_hi

			lock cmpxchg8b [esi]
			jnz '3b'

			mov res_lo, ebx
			mov res_hi, ecx

		2:
			;
			; r(dest)      as dest
			  m(delta_lo)  as delta_lo
			  m(delta_hi)  as delta_hi
			  m(res_lo)    as res_lo
			  m(res_hi)    as res_hi
			; eax ebx ecx edx esi
			  memory
		}
	}
	// vfmt on
	return i64(u64(res_lo) | (u64(res_hi) << 32))
}


pub fn swap_i64(dest &i64, value i64) i64 {
	mut value_lo := u32(u64(value) & 0xFFFF_FFFF)
	mut value_hi := u32(u64(value) >> 32)
	// vfmt off
	$if prod {
		asm volatile i386 {
			mov esi, dest
			test esi, 7
			jz '1f'
			ud2
			jmp '2f'

		1:
		3:
			mov eax, [esi]
			mov edx, [esi + 4]

			mov ebx, value_lo
			mov ecx, value_hi

			lock cmpxchg8b [esi]
			jnz '3b'

			mov value_lo, eax
			mov value_hi, edx

		2:
			;
			; r(dest)     as dest
			  m(value_lo) as value_lo
			  m(value_hi) as value_hi
			; eax ebx ecx edx esi
			  memory
		}
	} $else {
		asm volatile i386 {
			mov esi, dest
			test esi, 7
			jz '1f'
			call panicUnaligned
			jmp '2f'

		1:
		3:
			mov eax, [esi]
			mov edx, [esi + 4]

			mov ebx, value_lo
			mov ecx, value_hi

			lock cmpxchg8b [esi]
			jnz '3b'

			mov value_lo, eax
			mov value_hi, edx

		2:
			;
			; r(dest)     as dest
			  m(value_lo) as value_lo
			  m(value_hi) as value_hi
			; eax ebx ecx edx esi
			  memory
		}
	}
	// vfmt on
	return i64(u64(value_lo) | (u64(value_hi) << 32))
}


pub fn cas_i64(addr &i64, old i64, new i64) bool {
	mut swapped := false
	mut old_lo := u32(u64(old) & 0xFFFF_FFFF)
	mut old_hi := u32(u64(old) >> 32)
	mut new_lo := u32(u64(new) & 0xFFFF_FFFF)
	mut new_hi := u32(u64(new) >> 32)
	// vfmt off
	$if prod {
		asm volatile i386 {
			mov esi, addr
			test esi, 7
			jz '1f'
			ud2
			jmp '2f'

		1:
			mov eax, old_lo
			mov edx, old_hi

			mov ebx, new_lo
			mov ecx, new_hi

			lock cmpxchg8b [esi]

			sete al
			mov swapped, al

		2:
			; =m(swapped) as swapped
			; r(addr)     as addr
			  m(old_lo)   as old_lo
			  m(old_hi)   as old_hi
			  m(new_lo)   as new_lo
			  m(new_hi)   as new_hi
			; eax ebx ecx edx esi
			  memory
		}
	} $else {
		asm volatile i386 {
			mov esi, addr
			test esi, 7
			jz '1f'
			call panicUnaligned
			jmp '2f'

		1:
			mov eax, old_lo
			mov edx, old_hi

			mov ebx, new_lo
			mov ecx, new_hi

			lock cmpxchg8b [esi]

			sete al
			mov swapped, al

		2:
			; =m(swapped) as swapped
			; r(addr)     as addr
			  m(old_lo)   as old_lo
			  m(old_hi)   as old_hi
			  m(new_lo)   as new_lo
			  m(new_hi)   as new_hi
			; eax ebx ecx edx esi
			  memory
		}
	}
	// vfmt on
	return swapped
}

pub fn add_u32(dest &u32, delta u32) u32 {
	mut result := u32(0)
	// vfmt off
	$if prod {
		asm volatile i386 {
			mov edx, dest
			test edx, 3
			jz '1f'
			ud2
			jmp '2f'

		1:
			mov eax, delta
			lock xadd [edx], eax
			add eax, delta
			mov result, eax

		2:
			; =r(result)
			;  r(dest) r(delta)
			;  eax edx
			   memory
		}
	} $else {
		asm volatile i386 {
			mov edx, dest
			test edx, 3
			jz '1f'
			call panicUnaligned
			jmp '2f'

		1:
			mov eax, delta
			lock xadd [edx], eax
			add eax, delta
			mov result, eax

		2:
			; =r(result)
			;  r(dest) r(delta)
			;  eax edx
			   memory
		}
	}
	// vfmt on
	return result
}

pub fn swap_u32(dest &u32, new u32) u32 {
	mut old := u32(0)
	// vfmt off
	$if prod {
		asm volatile i386 {
			mov edx, dest
			test edx, 3
			jz '1f'
			ud2
			jmp '2f'

		1:
			mov eax, new
			xchg [edx], eax
			mov old, eax

		2:
			; =m(old)
			;  r(dest) r(new)
			;  eax edx
			   memory
		}
	} $else {
		asm volatile i386 {
			mov edx, dest
			test edx, 3
			jz '1f'
			call panicUnaligned
			jmp '2f'

		1:
			mov eax, new
			xchg [edx], eax
			mov old, eax

		2:
			; =m(old)
			;  r(dest) r(new)
			;  eax edx
			   memory
		}
	}
	// vfmt on
	return old
}

pub fn store_u32(dest &u32, value u32) {
	// vfmt off
	$if prod {
		asm volatile i386 {
			mov edx, dest
			test edx, 3
			jz '1f'
			ud2
			jmp '2f'

		1:
			mov eax, value
			xchg eax, [edx]

		2:
			;
			;r(dest) as dest
			 r(value) as value
			; eax edx
			  memory
		}
	} $else {
		asm volatile i386 {
			mov edx, dest
			test edx, 3
			jz '1f'
			call panicUnaligned
			jmp '2f'

		1:
			mov eax, value
			xchg eax, [edx]

		2:
			;
			;r(dest) as dest
			 r(value) as value
			; eax edx
			  memory
		}
	}
	// vfmt on
}

pub fn load_u32(num &u32) u32 {
	mut out := u32(0)
	// vfmt off
	$if prod {
		asm volatile i386 {
			mov edx, num
			test edx, 3
			jz '1f'
			ud2
			jmp '2f'

		1:
			mov eax, [edx]
			mov out, eax

		2:
			; =r(out)
			; r(num)
			; eax edx
			  memory
		}
	} $else {
		asm volatile i386 {
			mov edx, num
			test edx, 3
			jz '1f'
			call panicUnaligned
			jmp '2f'

		1:
			mov eax, [edx]
			mov out, eax

		2:
			; =r(out)
			; r(num)
			; eax edx
			  memory
		}
	}
	// vfmt on
	return out
}

pub fn cas_u32(addr &u32, old u32, new u32) bool {
	mut swapped := false
	// vfmt off
	$if prod {
		asm volatile i386 {
			mov edx, addr
			test edx, 3
			jz '1f'
			ud2
			jmp '2f'

		1:
			mov eax, old
			mov ecx, new
			lock cmpxchg [edx], ecx
			sete al
			mov swapped, al

		2:
			;=m(swapped)
			;r(addr) r(old) r(new)
			; eax ecx edx
			  memory
		}
	} $else {
		asm volatile i386 {
			mov edx, addr
			test edx, 3
			jz '1f'
			call panicUnaligned
			jmp '2f'

		1:
			mov eax, old
			mov ecx, new
			lock cmpxchg [edx], ecx
			sete al
			mov swapped, al

		2:
			;=m(swapped)
			;r(addr) r(old) r(new)
			; eax ecx edx
			  memory
		}
	}
	// vfmt on
	return swapped
}

pub fn load_u64(num &u64) u64 {
	mut out := u64(0)
	// vfmt off
	$if prod {
		asm volatile i386 {
			mov esi, num
			test esi, 7
			jz '1f'
			ud2
			jmp '2f'

		1:
			movq mm0, [esi]
			movq out, mm0
			emms

		2:
			; =m(out)
			; r(num)
			; esi mm0
			  memory
		}
	} $else {
		asm volatile i386 {
			mov esi, num
			test esi, 7
			jz '1f'
			call panicUnaligned
			jmp '2f'

		1:
			movq mm0, [esi]
			movq out, mm0
			emms

		2:
			; =m(out)
			; r(num)
			; esi mm0
			  memory
		}
	}
	// vfmt on
	return out
}

pub fn store_u64(dest &u64, value u64) {
	// vfmt off
	$if prod {
		asm volatile i386 {
			mov esi, dest
			test esi, 7
			jz '1f'
			ud2
			jmp '2f'

		1:
			movq mm0, value
			movq [esi], mm0
			emms
			xor eax, eax
			lock xaddl [esp], eax

		2:
			;
			; r(dest) as dest
			  m(value) as value
			; eax mm0
			  memory
		}
	} $else {
		asm volatile i386 {
			mov esi, dest
			test esi, 7
			jz '1f'
			call panicUnaligned
			jmp '2f'

		1:
			movq mm0, value
			movq [esi], mm0
			emms
			xor eax, eax
			lock xaddl [esp], eax

		2:
			;
			; r(dest) as dest
			  m(value) as value
			; eax mm0
			  memory
		}
	}
	// vfmt on
}

pub fn add_u64(dest &u64, delta u64) u64 {
	mut delta_lo := u32(delta & 0xFFFF_FFFF)
	mut delta_hi := u32(delta >> 32)
	mut res_lo := u32(0)
	mut res_hi := u32(0)
	// vfmt off
	$if prod {
		asm volatile i386 {
			mov esi, dest
			test esi, 7
			jz '1f'
			ud2
			jmp '2f'

		1:
		3:
			mov eax, [esi]
			mov edx, [esi + 4]

			mov ebx, eax
			mov ecx, edx
			add ebx, delta_lo
			adc ecx, delta_hi

			lock cmpxchg8b [esi]
			jnz '3b'

			mov res_lo, ebx
			mov res_hi, ecx

		2:
			;
			; r(dest)      as dest
			  m(delta_lo)  as delta_lo
			  m(delta_hi)  as delta_hi
			  m(res_lo)    as res_lo
			  m(res_hi)    as res_hi
			; eax ebx ecx edx esi
			  memory
		}
	} $else {
		asm volatile i386 {
			mov esi, dest
			test esi, 7
			jz '1f'
			call panicUnaligned
			jmp '2f'

		1:
		3:
			mov eax, [esi]
			mov edx, [esi + 4]

			mov ebx, eax
			mov ecx, edx
			add ebx, delta_lo
			adc ecx, delta_hi

			lock cmpxchg8b [esi]
			jnz '3b'

			mov res_lo, ebx
			mov res_hi, ecx

		2:
			;
			; r(dest)      as dest
			  m(delta_lo)  as delta_lo
			  m(delta_hi)  as delta_hi
			  m(res_lo)    as res_lo
			  m(res_hi)    as res_hi
			; eax ebx ecx edx esi
			  memory
		}
	}
	// vfmt on
	return u64(res_lo) | (u64(res_hi) << 32)
}


pub fn swap_u64(dest &u64, value u64) u64 {
	mut old := u64(0)
	mut value_lo := u32(value & 0xFFFF_FFFF)
	mut value_hi := u32(value >> 32)
	// vfmt off
	$if prod {
		asm volatile i386 {
			mov esi, dest
			test esi, 7
			jz '1f'
			ud2
			jmp '2f'

		1:
		3:
			mov eax, [esi]
			mov edx, [esi + 4]

			mov ebx, value_lo
			mov ecx, value_hi

			lock cmpxchg8b [esi]
			jnz '3b'

			mov value_lo, eax
			mov value_hi, edx

		2:
			;
			; r(dest)     as dest
			  m(value_lo) as value_lo
			  m(value_hi) as value_hi
			; eax ebx ecx edx esi
			  memory
		}
	} $else {
		asm volatile i386 {
			mov esi, dest
			test esi, 7
			jz '1f'
			call panicUnaligned
			jmp '2f'

		1:
		3:
			mov eax, [esi]
			mov edx, [esi + 4]

			mov ebx, value_lo
			mov ecx, value_hi

			lock cmpxchg8b [esi]
			jnz '3b'

			mov value_lo, eax
			mov value_hi, edx

		2:
			;
			; r(dest)     as dest
			  m(value_lo) as value_lo
			  m(value_hi) as value_hi
			; eax ebx ecx edx esi
			  memory
		}
	}
	// vfmt on
	old = u64(value_lo) | (u64(value_hi) << 32)
	return old
}


pub fn cas_u64(addr &u64, old u64, new u64) bool {
	mut swapped := false
	mut old_lo := u32(old & 0xFFFF_FFFF)
	mut old_hi := u32(old >> 32)
	mut new_lo := u32(new & 0xFFFF_FFFF)
	mut new_hi := u32(new >> 32)
	// vfmt off
	$if prod {
		asm volatile i386 {
			mov esi, addr
			test esi, 7
			jz '1f'
			ud2
			jmp '2f'

		1:
			mov eax, old_lo
			mov edx, old_hi

			mov ebx, new_lo
			mov ecx, new_hi

			lock cmpxchg8b [esi]

			sete al
			mov swapped, al

		2:
			; =m(swapped) as swapped
			; r(addr)     as addr
			  m(old_lo)   as old_lo
			  m(old_hi)   as old_hi
			  m(new_lo)   as new_lo
			  m(new_hi)   as new_hi
			; eax ebx ecx edx esi
			  memory
		}
	} $else {
		asm volatile i386 {
			mov esi, addr
			test esi, 7
			jz '1f'
			call panicUnaligned
			jmp '2f'

		1:
			mov eax, old_lo
			mov edx, old_hi

			mov ebx, new_lo
			mov ecx, new_hi

			lock cmpxchg8b [esi]

			sete al
			mov swapped, al

		2:
			; =m(swapped) as swapped
			; r(addr)     as addr
			  m(old_lo)   as old_lo
			  m(old_hi)   as old_hi
			  m(new_lo)   as new_lo
			  m(new_hi)   as new_hi
			; eax ebx ecx edx esi
			  memory
		}
	}
	// vfmt on
	return swapped
}
