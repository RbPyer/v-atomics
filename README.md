# v-atomics

![Tests](https://github.com/RbPyer/v-atomics/actions/workflows/check.yml/badge.svg)
![Arch](https://img.shields.io/badge/arch-amd64%20%7C%20i386-blue)
![License](https://img.shields.io/github/license/rbpyer/v-atomics)

Low-level atomic operations for V with explicit i386 support (MMX required on i386).


Native atomic primitives for V implemented with inline assembly, without relying on C FFI.

This repository is an experiment in providing low-level atomic operations directly in V, using V’s inline assembly support.  
At the moment, all operations provide sequentially consistent semantics.

## Installation

You need a working V toolchain. See the official documentation if you do not have it installed yet.

### Install via VPM (from Git)

You can install this repository directly using V’s package management:

```bash
v install --git https://github.com/RbPyer/v-atomics
```

## Motivation

In the current V ecosystem, atomic operations are implemented via calls into C.
While this approach works, it introduces an additional dependency on the C toolchain and headers and limits control over the exact machine instructions being emitted.

`v-atomics` explores an alternative: **native atomic operations implemented directly in V**, using architecture-specific inline assembly and explicit semantics.

The current focus of this project is:

- correctness of basic atomic primitives;
- predictable and inspectable code generation;
- sequentially consistent behavior for all operations.

In future versions, the set of supported atomic operations will be expanded, and additional memory orderings will be introduced.

---

## Scope and Guarantees

- atomic operations on integer types implemented in V with inline assembly;
- architecture-specific implementations (per-platform `atomics.<arch>.v` files);
- **sequential consistency** for all exposed operations.

---

## Memory Model

All operations in this library are intended to be **sequentially consistent**:

- operations appear to be globally ordered;
- no weaker semantics (relaxed, acquire, release) are currently implemented;
- when weaker variants are added in the future, they will be explicitly named and documented.
