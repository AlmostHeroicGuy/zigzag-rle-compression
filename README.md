# Zigzag RLE Compression & Decompression System

A hardware implementation of a **Run-Length Encoding (RLE) compression and decompression system** using **zigzag traversal**, built in **VHDL** and deployed on an **Intel MAX 10 FPGA**.  
This repository includes the full design (encoder + decoder), simulation, hardware assets, and documentation. :contentReference[oaicite:1]{index=1}

---

## 🔍 Overview

This project performs lossless compression and decompression of data using:

- **Zigzag ordering** of input blocks  
- **Run-Length Encoding** to group repeating symbols  
- FSM-based VHDL modules for both encoder and decoder  

The design was verified in simulation and synthesized for hardware deployment. :contentReference[oaicite:2]{index=2}

---

## 🗂 Project Contents

📁 Integrated_system/ — Top-level integrated encoder & decoder
📁 RLE_encoder/ — Encoder module files
📁 RLE_decoder/ — Decoder module files
📄 Final_Report.pdf — Full lab report
📷 board_implementation.jpg — FPGA board setup photo
📷 sim_result.jpg — Simulation waveform example
📷 pin_planning.jpg — Pin assignments
📷 rtl_netlist.jpg — RTL netlist screenshot
📷 successful_compilation.jpg — Quartus compile summary

---

## 🧠 About the Design

💡 **Run-Length Encoding (RLE)** is a form of lossless compression where repeat values are stored as a count plus value pair instead of repeating the symbol itself. :contentReference[oaicite:4]{index=4}

🔹 **Zigzag traversal** is applied to reorganize 2-D data into a 1-D sequence that tends to cluster similar values, improving compression effectiveness.

This implementation uses state machines in VHDL to build both:

- The **encoder** (produces compressed output)  
- The **decoder** (reconstructs original data)  
and integrates them into a synthesizable FPGA design. :contentReference[oaicite:5]{index=5}

---

## 🛠️ Tools Used

- **Quartus Prime Lite** – for synthesis & compilation  
- **ModelSim** – for RTL simulation  
- **VHDL** – hardware description language  
- **Intel MAX 10 FPGA** – target hardware board :contentReference[oaicite:6]{index=6}

---

## 📌 How to Use

1. Clone the repo:

   ```bash
   git clone https://github.com/AlmostHeroicGuy/zigzag-rle-compression
2. Open the relevant module folder (RLE_encoder, RLE_decoder, or Integrated_system) in Quartus Prime.
3. Run synthesis and compilation.
4. For simulation, use the testbenches included in the module folders with ModelSim.
5. Program the compiled design onto the MAX 10 FPGA using JTAG.
