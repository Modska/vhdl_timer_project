# VHDL Timer Module

## Overview
Parametric timer module with configurable clock frequency and delay duration. Designed for synthesis and verified with VUnit framework.

## Features
- ✅ Configurable clock frequency (Hz)
- ✅ Configurable delay duration (time type)
- ✅ Asynchronous reset
- ✅ Synthesis-ready RTL code
- ✅ Comprehensive test coverage
- ✅ CI/CD with GitHub Actions

## Architecture

### Timer Module (`src/timer.vhd`)
The timer calculates the required number of clock cycles based on:
- `clk_freq_hz_g`: Input clock frequency in Hertz
- `delay_g`: Desired delay duration (VHDL time type)

**Calculation:**
```
CYCLES_TO_COUNT = round(clk_freq_hz_g × delay_g)
```

### Design Decisions & Limitations

#### 1. Sub-Clock Period Delays
**Behavior:** Delays shorter than one clock period are rounded up to 1 cycle.

**Rationale:** A synchronous counter cannot measure time shorter than one clock period.

**Example:**
- Clock: 50 MHz (period = 20 ns)
- Requested delay: 10 ns
- Actual delay: 20 ns (1 cycle)

#### 2. Zero Delay
**Behavior:** `delay_g = 0 ns` keeps the timer in idle state (`done_o = '1'` always).

#### 3. Maximum Delay
**Limitation:** Maximum delay is limited by the `natural` type range (typically 2^31-1 cycles).

**Example maximum delays:**
- 50 MHz: ~43 seconds
- 100 MHz: ~21 seconds

#### 4. Rounding
**Behavior:** Cycle count is rounded to nearest integer.

**Example:**
- 100.4 cycles → 100 cycles
- 100.6 cycles → 101 cycles

## Usage

### Entity Interface
```vhdl
entity timer is
    generic (
        clk_freq_hz_g : natural;  -- Clock frequency in Hz
        delay_g       : time      -- Delay duration
    );
    port (
        clk_i   : in  std_ulogic;  -- Clock input
        arst_i  : in  std_ulogic;  -- Asynchronous reset (active high)
        start_i : in  std_ulogic;  -- Start pulse (ignored if busy)
        done_o  : out std_ulogic   -- '1' when idle, '0' when counting
    );
end entity timer;
```

### Example Instantiation
```vhdl
timer_inst: entity work.timer
    generic map (
        clk_freq_hz_g => 50_000_000,  -- 50 MHz
        delay_g       => 100 us        -- 100 microseconds
    )
    port map (
        clk_i   => clk,
        arst_i  => reset,
        start_i => start_pulse,
        done_o  => timer_done
    );
```

### Timing Diagram
```
         _   _   _   _   _   _   _   _   _   _
clk    _| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_

start  _____|‾‾‾|_______________________________

done   ‾‾‾‾‾‾‾‾‾|_______________|‾‾‾‾‾‾‾‾‾‾‾‾‾‾
                 ← delay_g →
```

## Testing

### Running Tests Locally

**Prerequisites:**
```bash
# Install GHDL
sudo apt-get install ghdl

# Install VUnit
pip install vunit_hdl
```

**Run all tests:**
```bash
python run.py
```

**Run specific test:**
```bash
python run.py "*Test_Timer_Accuracy*"
```

**Run with GUI (if GTKWave installed):**
```bash
python run.py --gui
```

### Test Coverage

The test suite covers:
- ✅ **Timing accuracy** - Verifies delay matches specification (within clock granularity)
- ✅ **Reset during counting** - Tests asynchronous reset behavior
- ✅ **Zero delay handling** - Special case validation
- ✅ **Sub-clock delays** - Verifies rounding to 1 cycle minimum
- ✅ **Multiple start pulses** - Ensures only first pulse triggers count
- ✅ **Start while busy** - Verifies ignored when counting
- ✅ **Back-to-back operation** - Tests consecutive timer runs

### Test Configurations

| Configuration | Frequency | Delay | Purpose |
|--------------|-----------|-------|---------|
| F50000000_D100us | 50 MHz | 100 µs | Standard case |
| F50000000_D50us | 50 MHz | 50 µs | Standard case |
| F100000000_D100us | 100 MHz | 100 µs | High frequency |
| F100000000_D50us | 100 MHz | 50 µs | High frequency |
| Special_Zero | 50 MHz | 0 ns | Zero delay edge case |
| Edge_SubClock_10ns | 50 MHz | 10 ns | Sub-clock period |
| Edge_OneClock_20ns | 50 MHz | 20 ns | Exactly 1 period |
| Edge_LongDelay_10ms | 50 MHz | 10 ms | Long delay |

## CI/CD

GitHub Actions automatically runs all tests on every push:
- Installs GHDL and VUnit
- Executes complete test suite
- Reports pass/fail status

See `.github/workflows/main.yml` for pipeline configuration.

## Files Structure

```
.
├── src/
│   └── timer.vhd           # Timer RTL implementation
├── tb/
│   └── tb_timer.vhd        # VUnit testbench
├── run.py                  # VUnit test runner
├── .github/
│   └── workflows/
│       └── main.yml        # CI pipeline
└── README.md               # This file
```

## Design Assumptions

1. **Clock frequency is constant** during operation
2. **Reset is asynchronous** and can occur at any time
3. **Start pulse can be multi-cycle** - only the first cycle triggers counting
4. **Start pulses during counting are ignored** (timer is busy)
5. **Time calculations use nanosecond resolution** (1 ns precision)
6. **Sub-clock delays round up to 1 cycle minimum**

## Known Limitations

1. Cannot achieve delays shorter than one clock period
2. Maximum delay limited by natural type range
3. Delay accuracy limited by clock period granularity
4. No support for fractional clock cycles

## License

Educational/demonstration project for VHDL design and verification practices.