module atomics

fn test_cas_i32_basic() {
	mut x := i32(10)
	ok := cas_i32(&x, 10, 20)
	assert ok == true
	assert x == 20
}

fn test_add_i32_basic() {
	mut x := i32(0)
	for _ in 0 .. 1000 {
		add_i32(&x, 1)
	}
	assert x == 1000
}

fn test_add_i32_negative() {
	mut x := i32(10)
	add_i32(&x, -3)
	assert x == 7
}

fn test_swap_i32_basic() {
	mut x := i32(5)
	old := swap_i32(&x, 99)
	assert old == 5
	assert x == 99
}

fn test_swap_i32_twice() {
	mut x := i32(1)
	assert swap_i32(&x, 2) == 1
	assert swap_i32(&x, 3) == 2
	assert x == 3
}

fn test_swap_i32_with_cas() {
	mut x := i32(10)
	assert cas_i32(&x, 10, 20)
	old := swap_i32(&x, 30)
	assert old == 20
	assert x == 30
}

fn test_swap_i32_concurrent() {
	mut x := i32(0)
	mut threads := []thread{}

	for _ in 0 .. 8 {
		threads << spawn fn (ptr &i32) {
			for _ in 0 .. 50_000 {
				swap_i32(ptr, 123)
			}
		}(&x)
	}

	for t in threads {
		t.wait()
	}

	// x должен стабилизироваться на "123", независимо от гонок,
	// т.к. swap атомарен
	assert x == 123
}

fn test_cas_i32_concurrent() {
	mut x := i32(0)
	mut threads := []thread{}

	for _ in 0 .. 8 {
		threads << spawn fn (ptr &i32) {
			for _ in 0 .. 100_000 {
				for {
					old := load_i32(ptr)
					if cas_i32(ptr, old, old + 1) {
						break
					}
				}
			}
		}(&x)
	}

	for t in threads {
		t.wait()
	}

	assert x == 800_000
}

fn test_cas_add_mix_concurrent() {
	mut x := i32(0)
	mut threads := []thread{}

	for _ in 0 .. 8 {
		threads << spawn fn (ptr &i32) {
			for _ in 0 .. 50_000 {
				if (*ptr & 1) == 0 {
					add_i32(ptr, 1)
				} else {
					for {
						old := load_i32(ptr)
						if cas_i32(ptr, old, old + 1) {
							break
						}
					}
				}
			}
		}(&x)
	}

	for t in threads {
		t.wait()
	}

	assert x > 0
}

fn test_swap_add_mix_concurrent() {
	mut x := i32(0)
	mut threads := []thread{}

	for _ in 0 .. 4 {
		threads << spawn fn (ptr &i32) {
			for _ in 0 .. 30_000 {
				swap_i32(ptr, 10)
				add_i32(ptr, 1)
			}
		}(&x)
	}

	for t in threads {
		t.wait()
	}

	assert x >= 10
}

fn test_atomic_fuzz() {
	mut x := i32(0)
	for i in 0 .. 200_000 {
		match i % 3 {
			0 {
				add_i32(&x, 1)
			}
			1 {
				old := x
				cas_i32(&x, old, old + 1)
			}
			2 {
				swap_i32(&x, x + 1)
			}
			else {}
		}
	}
	assert x != 0
}

fn test_cas_fail() {
	mut x := i32(5)
	assert !cas_i32(&x, 10, 42)
	assert x == 5
}

fn test_cas_fail_memory_unchanged() {
	mut x := i32(7)
	cas_i32(&x, 1, 2)
	assert x == 7
}

fn test_cas_exact_match() {
	mut x := i32(-1)
	assert !cas_i32(&x, 0, 999)
	assert x == -1
}

fn test_cas_twice() {
	mut x := i32(1)
	assert cas_i32(&x, 1, 2)
	assert cas_i32(&x, 2, 3)
	assert x == 3
}

fn test_cas_with_negative() {
	mut x := i32(-123)
	assert cas_i32(&x, -123, 8)
	assert x == 8
}

fn test_add_i32_concurrent() {
	mut x := i32(0)
	mut threads := []thread{}

	for _ in 0 .. 9 {
		threads << spawn fn (ptr &i32) {
			for _ in 0 .. 100_000 {
				add_i32(ptr, 1)
			}
		}(&x)
	}

	for t in threads {
		t.wait()
	}

	assert x == 900_000
}

fn test_add_i32_return_value() {
	mut x := i32(5)
	r := add_i32(&x, 7)
	assert r == 12
	assert x == 12
}

fn test_add_i32_overflow_wraps() {
	mut x := i32(2147483647) // max i32
	add_i32(&x, 1)
	assert x == -2147483648
}

fn test_load_i32_basic() {
	mut x := i32(123456)
	assert load_i32(&x) == 123456
}

fn test_store_i32_basic() {
	mut x := i32(5)
	store_i32(&x, 777)
	assert x == 777
}

fn test_load_store_i32_concurrent() {
	mut x := i32(0)
	mut threads := []thread{}

	for _ in 0 .. 4 { // 4 writer threads
		threads << spawn fn (px &i32) {
			for _ in 0 .. 50_000 {
				add_i32(px, 1) // атомарное инкрементирование
			}
		}(&x)
	}
	for _ in 0 .. 4 { // 4 reader threads
		threads << spawn fn (px &i32) {
			for _ in 0 .. 50_000 {
				_ := load_i32(px) // просто читают
			}
		}(&x)
	}

	for t in threads {
		t.wait()
	}

	assert x == 4 * 50_000 // точное ожидаемое значение
}

fn test_cas_swap_i32_race() {
	mut x := i32(0)
	mut threads := []thread{}

	for i in 0 .. 8 {
		threads << spawn fn (px &i32, id int) {
			for _ in 0 .. 40_000 {
				if id % 2 == 0 {
					for {
						old := *px
						if cas_i32(px, old, old + 1) {
							break
						}
					}
				} else {
					swap_i32(px, 0)
				}
			}
		}(&x, i)
	}

	for t in threads {
		t.wait()
	}

	assert x > 0
}

fn test_cas_i32_contended_flip() {
	mut x := i32(0)
	mut threads := []thread{}

	for _ in 0 .. 4 {
		threads << spawn fn (px &i32) {
			for _ in 0 .. 150_000 {
				cas_i32(px, 0, 1)
				cas_i32(px, 1, 0)
			}
		}(&x)
	}

	for t in threads {
		t.wait()
	}

	assert x == 0 || x == 1
}

fn test_i32_full_fuzz() {
	mut x := i32(0)
	for i in 0 .. 200_000 {
		match i % 5 {
			0 {
				add_i32(&x, 1)
			}
			1 {
				old := x
				cas_i32(&x, old, old + 1)
			}
			2 {
				swap_i32(&x, x + 3)
			}
			3 {
				store_i32(&x, i32(i & 0xffff))
			}
			4 {
				_ = load_i32(&x)
			}
			else {}
		}
	}
	assert true
}
