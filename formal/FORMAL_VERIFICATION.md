# Formal Verification of Timer Module

## Overview

This directory contains formal verification assets for the timer module using SymbiYosys (sby) and PSL (Property Specification Language).

## What is Formal Verification?

Unlike simulation (which tests specific scenarios), formal verification **mathematically proves** that properties hold for **all possible inputs and states**. This provides much stronger guarantees about correctness.

## Tools Used

- **SymbiYosys (sby)**: Formal verification framework
- **Yosys**: Synthesis and formal verification engine
- **GHDL**: VHDL front-end for Yosys
- **Z3**: SMT solver for proving properties

## Properties Verified

### Safety Properties (Assertions)

1. **Reset Behavior** (`p_reset_done`)
   - After reset, `done_o` must be high
   - Ensures timer returns to idle state

2. **Idle Stability** (`p_idle_done`)
   - When idle and no start pulse, `done_o` stays high
   - Proves timer doesn't spontaneously start

3. **Start Response** (`p_start_causes_busy`)
   - Start pulse causes `done_o` to go low
   - Verifies timer begins counting

4. **Zero Delay Handling** (`p_zero_delay`)
   - For zero delay, `done_o` stays high always
   - Proves special case correctness

5. **Timing Accuracy** (`p_correct_timing`)
   - **KEY PROPERTY**: After start, `done_o` goes high after exactly `EXPECTED_CYCLES`
   - Mathematically proves timing correctness

6. **Signal Stability** (`p_done_stable`)
   - No glitches on `done_o` signal
   - Ensures clean signal transitions

7. **Completion Guarantee** (`p_counting_completes`)
   - Once counting starts, it completes (unless reset)
   - Proves no deadlock states

8. **Busy Ignore** (`p_ignore_start_when_busy`)
   - Start pulses during counting are ignored
   - Verifies specification compliance

### Liveness Properties (Cover)

Cover properties ensure the design can actually reach interesting states:

1. **Complete Cycle** (`c_complete_cycle`)
   - Timer can successfully complete a timing cycle

2. **Reset During Count** (`c_reset_while_counting`)
   - Reset can occur while counting

3. **Back-to-Back** (`c_back_to_back`)
   - Multiple consecutive start pulses are possible

## Verification Modes

### 1. Bounded Model Checking (BMC)

```bash
sby -f timer.sby bmc
```

- Checks properties up to depth 50
- Fast but not exhaustive
- Good for finding bugs quickly

### 2. Inductive Proof

```bash
sby -f timer.sby prove
```

- Attempts mathematical proof of properties
- Proves properties for ALL time (if successful)
- More comprehensive than BMC

### 3. Cover Check

```bash
sby -f timer.sby cover
```

- Verifies cover properties are reachable
- Ensures properties aren't vacuously true
- Validates design can reach interesting states

## Running Formal Verification

### Prerequisites

Install OSS CAD Suite:
```bash
# Download from GitHub releases
wget https://github.com/YosysHQ/oss-cad-suite-build/releases/download/...

# Extract
tar -xzf oss-cad-suite-linux-x64-*.tgz

# Add to PATH
export PATH="$PWD/oss-cad-suite/bin:$PATH"
```

### Run All Checks

```bash
cd formal
./run_formal.sh
```

### Run Individual Checks

```bash
# BMC only
sby -f timer.sby bmc

# Proof only
sby -f timer.sby prove

# Cover only
sby -f timer.sby cover
```

## Understanding Results

### Success

```
SBY [timer_bmc] engine_0: ##   0:00:00  Status: passed
SBY [timer_bmc] engine_0.basecase: Status "passed"
SBY [timer_bmc] engine_0.induction: Status "passed"
SBY [timer_bmc] summary: Elapsed clock time [H:MM:SS (secs)]: 0:00:05 (5)
SBY [timer_bmc] DONE (PASS)
```

All properties hold for the given depth.

### Failure

```
SBY [timer_bmc] engine_0: ##   0:00:03  Assert failed in timer_formal: p_correct_timing
SBY [timer_bmc] engine_0: ##   0:00:03  Writing trace to engine_0/trace.vcd
SBY [timer_bmc] DONE (FAIL)
```

Property violation found. Check `trace.vcd` for counterexample.

## Design Considerations

### State Space Reduction

To keep formal verification tractable, we use:
- Small clock frequencies (1 kHz vs 50 MHz)
- Short delays (10 cycles vs 5000 cycles)
- Limited verification depth (25-50 cycles)

This is sufficient to prove correctness because:
- The timer logic is cycle-accurate (doesn't depend on absolute frequency)
- Counter behavior is regular (no special cases after certain counts)
- Properties are inductive (if true for N cycles, true for N+1)

### Why PSL?

PSL (Property Specification Language) provides:
- Temporal operators (`next`, `always`, `eventually`, `until`)
- Sequence matching (`[*N]` for N repetitions)
- Implication (`->`) and consequence (`|=>`)
- Clear, declarative property specification

### Limitations

Formal verification proves properties **within the verification depth**. For unbounded properties:
- BMC: Proves up to depth limit
- Induction: Can prove for all time (if induction succeeds)

The key property `p_correct_timing` uses a bounded sequence (`not done[*EXPECTED_CYCLES]`), which is perfect for inductive proofs.

## Integration with CI/CD

The formal verification runs automatically in GitHub Actions:
1. Installs OSS CAD Suite
2. Runs BMC, Prove, and Cover checks
3. Uploads results as artifacts
4. Fails CI if any property fails

This ensures:
- Every commit is formally verified
- Regressions are caught immediately
- Proofs remain valid as code evolves

## Troubleshooting

### "property failed" error

A property violation was found. Steps to debug:
1. Check the generated trace: `timer_*/engine_*/trace.vcd`
2. View in GTKWave: `gtkwave timer_*/engine_*/trace.vcd`
3. Identify the failing assertion
4. Fix the design or adjust the property

### "timeout" error

Verification is taking too long:
1. Reduce verification depth in `timer.sby`
2. Simplify properties
3. Use smaller generic values in `timer_formal.vhd`

### "engine died" error

SMT solver crashed:
1. Try different solver (`boolector`, `cvc4` instead of `z3`)
2. Reduce problem complexity
3. Check for syntax errors in properties

## Further Reading

- [SymbiYosys Documentation](https://symbiyosys.readthedocs.io/)
- [PSL Quick Reference](https://www.doulos.com/knowhow/psl/)
- [Formal Verification Tutorial](https://zipcpu.com/tutorial/)
- [GHDL Yosys Plugin](https://github.com/ghdl/ghdl-yosys-plugin)

## Summary

Formal verification provides mathematical proof that the timer:
- Always returns to idle after reset
- Always asserts `done_o` after exactly the specified delay
- Never glitches or deadlocks
- Correctly handles edge cases (zero delay, busy state, etc.)

This level of assurance is impossible to achieve with simulation alone.