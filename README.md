# 8-Bit Successive Approximation Register (SAR) ADC 

This project implements a digital controller for an 8-bit SAR Analog-to-Digital Converter in Verilog. It uses a binary search algorithm to convert an analog voltage input into an 8-bit digital output in exactly 8 conversion cycles.

## 1. Architecture Overview

The system is divided into three main components:
1.  **SAR FSM**: The "Brain" that coordinates the guessing and shifting logic.
2.  **SAR Datapath**: The "Registers" that hold the current digital guess ($q$) and the bit index ($idx$).
3.  **Comparator (Testbench)**: Provides feedback ($vcomp$) to the SAR to indicate if the current guess is higher or lower than the input.



---

## 2. The Conversion Process (Binary Search)

Instead of counting linearly from 0 to 255 (which would take up to 256 cycles), the SAR ADC performs a **Binary Search**. For an 8-bit ADC, this takes a fixed number of cycles regardless of the input voltage.

### State Machine Logic
* **S_IDLE**: Waiting for the `clk_sample` rising edge.
* **S_INIT**: Clears the output register ($q=0$) and sets the pointer to the Most Significant Bit ($idx=7$).
* **S_TRIAL**: Sets the current bit ($q[idx]$) to `1`. This is the "Guess."
* **S_COMMIT**: Evaluates the `vcomp` signal. 
    * If `vcomp == 1` (Vin > Guess), the bit remains `1`.
    * If `vcomp == 0` (Vin < Guess), the bit is cleared to `0`.
* **S_SHIFT**: Moves the pointer to the next lower bit ($idx = idx - 1$).
* **S_DONE**: Signals that the conversion is complete via the `eoc` flag.



---

## 3. Mathematical Model

The comparator logic in the testbench simulates the analog comparison. The digital-to-analog representation of our guess ($V_{dac}$) is calculated as:

$$V_{dac} = V_{ref} \times \frac{q}{2^N}$$

Where:
* $V_{ref}$ = Reference Voltage (typically 1.0V)
* $q$ = Current 8-bit digital value (0-255)
* $N$ = Resolution (8 bits, so $2^8 = 256$)

The comparator output is defined as:
$$vcomp = (V_{in} \ge V_{dac}) ? 1 : 0$$

---

## 4. Signal Descriptions

| Signal | Direction | Description |
| :--- | :--- | :--- |
| `clk_sar` | Input | High-speed clock for the internal logic. |
| `clk_sample` | Input | Triggers the start of a new conversion cycle. |
| `rst` | Input | Global synchronous reset (Active High). |
| `vcomp` | Input | Feedback from the comparator (High if Vin > Vdac). |
| `q[7:0]` | Output | The final 8-bit digital result. |
| `busy` | Output | High while a conversion is currently in progress. |
| `eoc` | Output | End of Conversion; pulses high when the result is valid. |



---

## 5. Simulation & Verification

To verify the design, the testbench provides a constant `vin` (e.g., 0.45V). You should observe `q` narrowing down to the value **115** (which is $0.45 \times 256$).

### Execution Steps:
1.  Ensure `design.sv` and `testbench.sv` are in the same directory.
2.  Compile using **iverilog**:
    ```bash
    iverilog -g2012 design.sv testbench.sv
    ```
3.  Run the simulation:
    ```bash
    vvp a.out
    ```
4.  Analyze the waveform:
    ```bash
    gtkwave dump.vcd
    ```
