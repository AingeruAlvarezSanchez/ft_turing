# ft_turing

## Table of Contents

1. [Overview](#1-overview)
2. [What Is a Turing Machine](#2-what-is-a-turing-machine)
3. [A Brief Look at OCaml](#3-a-brief-look-at-ocaml)
4. [Usage](#4-usage)
5. [Build System](#5-build-system)
6. [Machine Description Format](#6-machine-description-format)
7. [Output Format](#7-output-format)
8. [The Bundled Machines](#8-the-bundled-machines)
9. [Error Handling](#9-error-handling)
10. [References](#10-references)

## 1. Overview

`ft_turing` is a single-tape, single-head Turing machine simulator. You give it a JSON file describing a machine and an 
input string to write on the tape. The program runs the machine step by step, printing the tape and the rule applied to each step
and finally reports whether the machine halted in a final state or got stuck with no applicable transition.

The simulator is written in OCaml, using immutable data and a purely functional core. The tape, executor and rendering 
are separate modules. JSON parsing leans on the `yojson` library.

## 2. What Is a Turing Machine

A Turing machine is the simplest model of computation that can still compute anything a modern computer can. It has three parts:

- **A tape**: an infinite number of cells, each holding one symbol. Every cell that hasn't been written yet holds *blank* symbol.
- **A head**: a cursor sitting over one cell. It can read the symbol under it, overwrite it, and move one cell left or right.
- **A state**: the machine's current "mood", a label from a fixed finite set. One state is the starting state; some are *final* states that mean "stop here".

The machine runs by looking up a rule for its current `(state, symbol)` pair. A rule says: write this symbol, move and switch to that state. It applies the rule, then repeats. Three things can happen:

- It reaches a **final state**: the computation succeeded (`ACCEPTED`).
- It finds **no rule** for the current `(state, symbol)`: the machine is stuck (`BLOCKED`).
- It **never stops**: some machines loop forever. Since a simulator can't tell in general whether a machine will halt, `ft_turing` caps the run at a step budget and reports `TIMED_OUT` if it's exceeded.

Despite how little there is to it, this model is *Turing complete*: anything computable can be expressed as a machine of this kind. 
The bundled examples ([Section 8](#8-the-bundled-machines)) build up from simple arithmetic to a *universal* machine, one whose input encodes another machine that it then simulates.

## 3. A Brief Look at OCaml

OCaml is a functional programming language. "Functional" here means the default way to work with data is to *transform* 
it into new values rather than mutate existing ones.

A few traits that shape how the code reads:

- **Immutability by default**: values don't change once bound. State moves forward by creating new values, which makes the flow easier to reason about and to test.
- **Strong static typing with inference**: every value has a type, checked at compile time. Bugs are caught before the program runs.
- **Algebraic types and pattern matching**: types can be a fixed set of shapes (`Left | Right`), and `match` handles each shape. The compiler warns if a case is missed.
- **Interface files (`.mli`)**: a module can publish a contract, the types and functions visible from outside, while hiding its internals.

OCaml compiles two ways, and this project uses both (see [Section 5](#5-build-system)): `ocamlc` produces portable **bytecode** run by a small virtual machine, and `ocamlopt` produces a **native** machine-code executable. Same source, same result, different trade-off between build speed and run speed.

## 4. Usage

After building (see [Section 5](#5-build-system)), the program takes two positional arguments: the machine description and the input string.

```
./ft_turing [-h] jsonfile input
```

| Argument       | Meaning                                        |
|----------------|------------------------------------------------|
| `jsonfile`     | Path to the JSON description of the machine.   |
| `input`        | The string written on the tape before the run. |
| `-h`, `--help` | Print the usage message and exit.              |

A normal run:

```
$ ./ft_turing res/unary_sub.json "111-11="
```

This prints a header describing the machine, then one line per step showing the tape and the rule applied, and finally the outcome. 
The exact shape of that output is in [Section 7](#7-output-format).

The exit code reflects the outcome, not just success or failure of the program:

- **0**: the machine produced a verdict, either `ACCEPTED` or `BLOCKED`. A stuck machine is a legitimate result, so it exits cleanly.
- **1**: no verdict was reached, either the run timed out, or the arguments or the JSON were invalid ([Section 9](#9-error-handling)).

## 5. Build System

Built with `make`, using OCaml's `ocamlc` and `ocamlopt` through `ocamlfind`. The one external library is `yojson`, for JSON parsing.

The build is self-provisioning: the `deps` target checks for a working OCaml toolchain and installs what's missing via OPAM, 
so the user will never have to set anything up. Because the `-cmi-file` option is used to pair each `src/*.ml` with its interface in `inc/`, 
OCaml 5.0 or newer is required (as it can be seen on the Dockerfile).

Available targets:

| Target          | Description                                                                                                   |
|-----------------|---------------------------------------------------------------------------------------------------------------|
| `all` (default) | Ensures dependencies, then compiles all sources to **bytecode** with `ocamlc` and links `ft_turing`.          |
| `native`        | Same, but compiles to a **native** executable with `ocamlopt`.                                                |
| `debug`         | Rebuilds with debug info (`-g`) and produces a `ft_turing.bc` bytecode file for use under the debugger.       |
| `clean`         | Removes the `obj/` directory of intermediate object files.                                                    |
| `fclean`        | Runs `clean` and additionally removes the `ft_turing` and `ft_turing.bc` executables.                         |
| `re`            | `fclean` followed by `all`.                                                                                   |

Source order is resolved automatically: the Makefile runs `ocamldep` to sort `src/*.ml` by dependency before compiling.

### Docker

For a clean, reproducible toolchain, a docker container is provided. The image is based on 
`ocaml/opam:ubuntu-22.04-ocaml-5.5` with `ocamlfind` and `yojson` pre-installed.

```
docker compose up --build -d
docker compose exec -it ft_turing-dev bash
```

The project directory is mounted at `/workspace`, so you build and run inside the container against your live source.

## 6. Machine Description Format

A machine is a JSON object with the following fields:

| Field         | Meaning                                                                                       |
|---------------|-----------------------------------------------------------------------------------------------|
| `name`        | A label for the machine, shown in the output header.                                          |
| `alphabet`    | The symbols the tape can hold, each a string of length 1.                                     |
| `blank`       | The blank symbol. Must be in `alphabet`, and must **not** appear in the input.                |
| `states`      | The list of state names.                                                                      |
| `initial`     | The starting state. Must be one of `states`.                                                  |
| `finals`      | The final (halting) states. A subset of `states`.                                             |
| `transitions` | A dictionary indexed by state name; each entry is a list of rules for that state.             |

Each rule is an object:

```json
{ "read": "1", "to_state": "subone", "write": "=", "action": "LEFT" }
```

- `read`: the symbol under the head that this rule matches.
- `write`: the symbol to write in its place.
- `to_state`: the state to switch to.
- `action`: `LEFT` or `RIGHT`, which way the head moves.

For a given state, the read symbols must be distinct. Two rules for the same `(state, read)` pair would be ambiguous, 
and the parser rejects that.

## 7. Output Format

A run prints three parts. The shape below is illustrative; the exact numbers depend on the machine and input.

**Header**, a banner with the machine name, followed by its alphabet, states, initial and final states, and a dump of every rule:

```
********************************************************************************
*                                                                              *
*                                  unary_sub                                   *
*                                                                              *
********************************************************************************
Alphabet: [ 1, ., -, = ]
States : [ scanright, eraseone, subone, skip, HALT ]
Initial : scanright
Finals : [ HALT ]
(scanright, .) -> (scanright, ., RIGHT)
(scanright, 1) -> (scanright, 1, RIGHT)
...
********************************************************************************
```

**Trace**, one line per step: a fixed 20-cell window of the tape with the head marked as `<x>`, then the rule being applied.

```
[<1>11-11=.............] (scanright, 1) -> (scanright, 1, RIGHT)
[1<1>1-11=.............] (scanright, 1) -> (scanright, 1, RIGHT)
...
```

**Outcome**, the final status, the number of steps taken, and the full tape:

```
status: ACCEPTED
steps: 42
tape: 1.....................
```

A `BLOCKED` run adds the `(state, symbol)` pair that had no rule; a `TIMED_OUT` run says the machine didn't halt within its step budget.

## 8. The Bundled Machines

The `res/` directory holds machine descriptions. The five the assignment asks for, plus a couple of extras:

| File              | What it computes                                                                            |
|-------------------|---------------------------------------------------------------------------------------------|
| `unary_sum.json`  | Unary addition: adds two numbers written as runs of `1`.                                    |
| `palindrome.json` | Decides whether the input is a palindrome, writing `y`/`n` as the verdict.                  |
| `zeros_ones.json` | Decides the language `0ⁿ1ⁿ` (e.g. `000111`): the same count of `0`s then `1`s.              |
| `zeros_2n.json`   | Decides the language `0²ⁿ`: an even number of `0`s.                                         |
| `universal.json`  | A universal machine: its input encodes another machine and a tape, which it then simulates. |
| `unary_sub.json`  | Extra: unary subtraction.                                                                   |
| `unary.json`      | Extra: another unary machine.                                                               |

## 9. Error Handling

The program never crashes on bad input; every failure becomes a message on standard error and exit code 1.

- **Bad arguments**: too few, too many, or an unrecognized option, each with its own message.
- **Missing file / directory**: the path doesn't exist, or points to a directory instead of a JSON file.
- **Malformed JSON**: a syntax error in the file, reported with `yojson`'s position.
- **Invalid machine**: a symbol that isn't length 1, a `read`/`write` outside the alphabet, a `to_state` that isn't a
- declared state, an `action` that isn't `LEFT`/`RIGHT`, or duplicate rules for one `(state, read)` pair.

Parsing raises exceptions; the `cli` module is the single boundary that catches them and prints a clean line, never an OCaml backtrace.

## 10. References

- [Turing machine (Wikipedia)](https://en.wikipedia.org/wiki/Turing_machine)
- [Universal Turing machine (Wikipedia)](https://en.wikipedia.org/wiki/Universal_Turing_machine)
- [The OCaml Manual](https://ocaml.org/manual/)
- [yojson documentation](https://ocaml.org/p/yojson/latest)
- [Ocaml Programming from Michael Ryan Clarkson](https://www.youtube.com/playlist?list=PLre5AT9JnKShBOPeuiD9b-I4XROIJhkIU)
