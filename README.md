FPGA-Based Prime & Divisor Explorer System

This project is a comprehensive digital system designed for the Digilent Basys 3 FPGA board. It provides deep insights into any input number N, including primality checks, divisor counting, and dynamic scrolling features.

🚀 Features

Prime Number Checker:
Instantly identifies if the given input N is a prime number.

Total Divisor Counter:
Calculates and displays the total number of divisors for N.

Automatic Divisor Scrolling:
Every 1 second, the system automatically scrolls through each divisor of N on the 7-segment display.

Prime Range Counter:
Computes the total count of prime numbers within the range [1, N].

Toggleable Prime Scrolling:
Scrolls through all primes in the 1...N range every 1 second.
Includes a toggleable direction feature, allowing the user to switch between forward and backward scrolling.

🛠️ Hardware & Environment

Board: Xilinx Basys 3 (Artix-7)
Language: Verilog HDL
Tool: Xilinx Vivado

📂 File Structure

main.v: Contains all design modules, including the top-level module, button debouncing, and prime/divisor logic.
bysisis.xdc: Constraint file for Basys 3 pin mapping.
project_1.xpr: Vivado project file.

⚙️ How to Setup
Follow these steps to run the project on your local machine:
Open Vivado: Launch the Xilinx Vivado software on your PC.
Open Project: Navigate to File -> Open Project and select the project_1.xpr file from the repository folder.
Verify Source Files: Ensure that main.v is listed under Design Sources and bysisis.xdc is correctly loaded under Constraints.
Generate Bitstream: Click on Generate Bitstream in the Flow Navigator panel on the left.
Program the Board: Connect your Basys 3 board to your PC, open the Hardware Manager, and program the board using the generated .bit file.
