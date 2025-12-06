module atomics


fn test_load_i64_basic() {
    mut x := i64(1234567890123)
    assert load_i64(&x) == 1234567890123
}


fn test_store_i64_basic() {
    mut x := i64(1)
    store_i64(&x, 9999999)
    assert x == 9999999
}


fn test_swap_i64_basic() {
    mut x := i64(50)
    old := swap_i64(&x, 777)
    assert old == 50
    assert x == 777
}


fn test_swap_i64_same_value() {
    mut x := i64(-123)
    old := swap_i64(&x, -123)
    assert old == -123
    assert x == -123
}


fn test_add_i64_basic() {
    mut x := i64(0)
    for _ in 0 .. 1000 {
        add_i64(&x, 3)
    }
    assert x == 3000
}


fn test_add_i64_negative_delta() {
    mut x := i64(100)
    add_i64(&x, -7)
    assert x == 93
}


fn test_add_i64_wraparound_behavior() {
    mut x := i64(0x7fffffffffffffff)
    add_i64(&x, 1)
    assert x == -0x8000000000000000
}


fn test_add_i64_return_value() {
    mut x := i64(10)
    r := add_i64(&x, 100)
    assert r == 110
    assert x == 110
}


fn test_cas_i64_basic() {
    mut x := i64(111)
    assert cas_i64(&x, 111, 222)
    assert x == 222
}


fn test_cas_i64_fail() {
    mut x := i64(555)
    assert !cas_i64(&x, 123, 999)
    assert x == 555
}


fn test_cas_i64_nochange_on_fail() {
    mut x := i64(-999)
    cas_i64(&x, 1, 5)
    assert x == -999
}


fn test_cas_i64_negative_values() {
    mut x := i64(-123456)
    assert cas_i64(&x, -123456, 777)
    assert x == 777
}


fn test_add_i64_concurrent() {
    mut x := i64(0)
    mut threads := []thread{}

    for _ in 0 .. 8 {
        threads << spawn fn (px &i64) {
            for _ in 0 .. 100_000 {
                add_i64(px, 1)
            }
        }(&x)
    }

    for t in threads { t.wait() }

    assert x == 800_000
}


fn test_swap_i64_concurrent() {
    mut x := i64(0)
    mut threads := []thread{}

    for _ in 0 .. 8 {
        threads << spawn fn (px &i64) {
            for _ in 0 .. 50_000 {
                swap_i64(px, 12345)
            }
        }(&x)
    }

    for t in threads { t.wait() }

    assert x == 12345
}


fn test_cas_i64_concurrent_inc() {
    mut x := i64(0)
    mut threads := []thread{}

    for _ in 0 .. 8 {
        threads << spawn fn (px &i64) {
            for _ in 0 .. 50_000 {
                for {
                    old := load_i64(px)
                    if cas_i64(px, old, old + 1) { break }
                }
            }
        }(&x)
    }

    for t in threads { t.wait() }

    assert x == 400_000
}


fn test_cas_add_i64_mixed() {
    mut x := i64(0)
    mut threads := []thread{}

    for _ in 0 .. 8 {
        threads << spawn fn (px &i64) {
            for _ in 0 .. 50_000 {
                val := load_i64(px)
                if (val & 1) == 0 {
                    add_i64(px, 1)
                } else {
                    for {
                        old := load_i64(px)
                        if cas_i64(px, old, old + 1) { break }
                    }
                }
            }
        }(&x)
    }

    for t in threads { t.wait() }

    assert x > 0
}


fn test_swap_add_i64_mixed() {
    mut x := i64(0)
    mut threads := []thread{}

    for _ in 0 .. 6 {
        threads << spawn fn (px &i64) {
            for _ in 0 .. 30_000 {
                swap_i64(px, 10)
                add_i64(px, 1)
            }
        }(&x)
    }

    for t in threads { t.wait() }

    assert x >= 10
}

fn test_cas_swap_i64_race() {
    mut x := i64(0)
    mut threads := []thread{}

    for i in 0 .. 8 {
        threads << spawn fn (px &i64, id int) {
            for _ in 0 .. 40_000 {
                if id % 2 == 0 {
                    for {
                        old := load_i64(px)
                        if cas_i64(px, old, old + 1) { break }
                    }
                } else {
                    swap_i64(px, 0)
                }
            }
        }(&x, i)
    }

    for t in threads { t.wait() }

    assert x >= 0
}


fn test_cas_i64_aba_style_race() {
    mut x := i64(1)
    mut threads := []thread{}

    for i in 0 .. 6 {
        threads << spawn fn (px &i64, id int) {
            for _ in 0 .. 40_000 {
                if id % 2 == 0 {
                    for {
                        old := load_i64(px)
                        if cas_i64(px, old, old + 1) { break }
                    }
                } else {
                    swap_i64(px, 1)
                }
            }
        }(&x, i)
    }

    for t in threads { t.wait() }

    assert x >= 1
}


fn test_cas_i64_contended_flip() {
    mut x := i64(0)
    mut threads := []thread{}

    for _ in 0 .. 4 {
        threads << spawn fn (px &i64) {
            for _ in 0 .. 200_000 {
                cas_i64(px, 0, 1)
                cas_i64(px, 1, 0)
            }
        }(&x)
    }

    for t in threads { t.wait() }

    assert x == 0 || x == 1
}


fn test_i64_atomic_fuzz() {
    mut x := i64(0)
    for i in 0 .. 200_000 {
        match i % 3 {
            0 { add_i64(&x, 1) }
            1 {
                old := load_i64(&x)
                cas_i64(&x, old, old + 1)
            }
            2 { swap_i64(&x, load_i64(&x) + 1) }
            else {}
        }
    }
    assert x != 0
}
