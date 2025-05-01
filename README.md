# Practica 2: Conic Sections Visualizer

A VGA-based interactive conic sections visualization system implemented on the DE2-115 FPGA board.

## Overview

This project creates a dynamic visualization system for conic sections on a VGA monitor (1280x1024@60Hz). The system allows users to switch between different conic sections and modify their parameters in real-time using keyboard inputs.

## Features
Interactive Visualization: Display and manipulate various conic sections on a VGA display
Real-time Parameter Control: Adjust conic section parameters using keyboard inputs
Multiple Conic Types:
- Circle
- Ellipse
- Parabola
- Hyperbola
- Straight Line

Visual Feedback: LCD display shows the current conic type 7-segment display shows keyboard scan codes Cartesian coordinate system with axes markings

## Hardware Requirements
Altera DE2-115 FPGA Development Board
VGA Monitor (supporting 1280x1024@60Hz)
PS/2 Keyboard
16x2 LCD Display

## Usage Instructions
Connect the hardware:

Connect a VGA monitor to the VGA port
Connect a PS/2 keyboard to the PS/2 port
Ensure the LCD display is properly connected
Load the design onto the DE2-115 board

## Usage

Control the visualization:

Press keys to change conic types:
1. (scan code 0x0016): Circle
2. (scan code 0x001E): Ellipse
3. (scan code 0x0026): Parabola
4. (scan code 0x0025): Hyperbola
5. (scan code 0x002E): Straight Line
Adjust conic parameters with arrow keys:

For Circle:
- Up/Down: Increase/decrease radius
For Ellipse/Hyperbola:
- Up/Down: Adjust semi-major axis (a)
- Left/Right: Adjust semi-minor axis (b)
For Parabola:
- Up/Down: Adjust the p parameter
For Straight Line:
- Up/Down: Adjust slope (m)
- Left/Right: Adjust y-intercept (br)

## View information

The LCD display shows the current selected conic section
7-segment displays show keyboard scan codes

## Module Descriptions
`Practica2.v`: Top-level module connecting all components
`Sync.v`: Core module handling VGA timing and conic section rendering
`Keyboard.v`: PS/2 keyboard controller with debouncing
`LCD.v`: Controller for the LCD display showing conic type
`Debounce.v`: Input signal debouncer for reliable button operations
`Hex.v`: Hex to 7-segment display converter
`PLL.v` (implicit): Phase-Locked Loop for clock generation (108MHz for VGA)

## Implementation Details
### Coordinate System
The system implements a Cartesian coordinate plane centered at (640, 512) on the display with:

- X-axis and Y-axis drawn in white
- Tick marks every 50 pixels
- Conics drawn in red against a black background
- Conic Section Equations
    - Circle: `x² + y² = r²`
    - Ellipse: `x²/a² + y²/b² = 1`
    - Parabola: `x² = 4py`
    - Hyperbola: `x²/a² - y²/b² = 1`
    - Straight Line: `y = (200/m)x + br`

## Authors
Garcia Garcia Aram Jesua
Hernandez Diaz Roberto Angel
Hernandez Jimenez Irmin
Trejo Flores Johann Daniel
Toral Hernandez Leonardo Javier

## Additional Notes
The system uses error margins when drawing conic sections to ensure continuous curves
VGA timing parameters are configured for 1280x1024@60Hz resolution
The keyboard controller handles both make and break codes for proper key detection
The LCD controller provides visual feedback about the currently selected conic section