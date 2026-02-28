;; Repeatedly yield execution to the scheduler.
(module
    (import "wasi_snapshot_preview1" "sched_yield"
        (func $__wasi_sched_yield (result i32)))
    (func (export "run") (param $iters i64) (result i64)
        (local $i i64)
        (local.set $i (i64.const 0))
        (loop $cont
            ;; Yield to exercise runtime scheduling overhead.
            (call $__wasi_sched_yield)
            (if (then unreachable))

            ;; Continue looping until $i reaches $iters.
            (local.set $i (i64.add (local.get $i) (i64.const 1)))
            (br_if $cont (i64.lt_u (local.get $i) (local.get $iters)))
        )
        (local.get $i)
    )
    (memory (export "memory") 1)
)
