;; Repeatedly request random bytes from WASI.
(module
    (import "wasi_snapshot_preview1" "random_get"
        (func $__wasi_random_get (param i32 i32) (result i32)))
    (func (export "run") (param $iters i64) (result i64)
        (local $i i64)
        (local.set $i (i64.const 0))
        (loop $cont
            ;; Fill the first 256 bytes with random data.
            (call $__wasi_random_get (i32.const 0) (i32.const 256))
            (if (then unreachable))

            ;; Continue looping until $i reaches $iters.
            (local.set $i (i64.add (local.get $i) (i64.const 1)))
            (br_if $cont (i64.lt_u (local.get $i) (local.get $iters)))
        )
        (local.get $i)
    )
    (memory (export "memory") 1)
)
