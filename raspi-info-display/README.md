# Info Display

A Rust application that displays system information on an SSD1306 OLED display connected to a Raspberry Pi via I2C.

## Features

- Displays hostname, IP address, CPU temperature, memory usage, disk usage, and uptime
- Uses I2C communication for display control
- Supports 128x64 pixel resolution
- Automatically detects the first available non-loopback network interface
- **NEW**: Support for TCA9548A I2C multiplexer (connect up to 8 displays)
- Daemon mode for running as a background service
- Configurable update interval

## Hardware Requirements

- Raspberry Pi (any model with I2C support)
- SSD1306 OLED display (128x64)
- I2C connection between Raspberry Pi and display
- (Optional) TCA9548A I2C multiplexer for multiple displays

## Software Requirements

- Rust (latest stable version)
- I2C enabled on Raspberry Pi
- Required system packages for I2C support

## Installation

1. Enable I2C on your Raspberry Pi:
   ```bash
   sudo raspi-config
   # Navigate to Interface Options -> I2C -> Enable
   ```

2. Install required system packages:
   ```bash
   sudo apt-get update
   sudo apt-get install -y i2c-tools
   ```

3. Clone the repository:
   ```bash
   git clone [your-repository-url]
   cd info_display
   ```

4. Build the project:
   ```bash
   cargo build --release
   ```

## Usage

### Basic Usage

1. Connect your SSD1306 display to the Raspberry Pi:
   - VCC to 3.3V
   - GND to GND
   - SCL to SCL (GPIO 3)
   - SDA to SDA (GPIO 2)

2. Run the application:
   ```bash
   sudo ./target/release/info_display
   ```

### Command Line Options

```bash
Usage: info_display [OPTIONS]

Options:
  --clear               Clear the display and exit
  --daemon, -d          Run in daemon mode
  --interval=<seconds>  Set update interval (default: 5)
  --mux                 Use TCA9548A I2C multiplexer
  --mux-channel=<0-7>   Select multiplexer channel (default: 0)
  --mux-address=<addr>  Set multiplexer I2C address (default: 0x70)
  --help, -h            Show help message
```

### Using with TCA9548A Multiplexer

If you have a TCA9548A I2C multiplexer connected:

1. Connect the TCA9548A to your Raspberry Pi:
   - VCC to 3.3V
   - GND to GND
   - SCL to SCL (GPIO 3)
   - SDA to SDA (GPIO 2)
   - A0, A1, A2 to GND (for address 0x70)

2. Connect your OLED display to one of the multiplexer channels (SC0/SD0 through SC7/SD7)

3. Run with multiplexer support:
   ```bash
   # Display on channel 0
   sudo ./target/release/info_display --mux --mux-channel=0
   
   # Display on channel 3 with custom update interval
   sudo ./target/release/info_display --mux --mux-channel=3 --interval=10
   
   # Use multiplexer at different address
   sudo ./target/release/info_display --mux --mux-address=0x71 --mux-channel=0
   ```

4. Test your multiplexer setup:
   ```bash
   # Run the test script to scan all channels
   sudo ./scripts/test-tca9548a.sh
   ```

### Running as a Service

```bash
# Run in daemon mode
sudo ./target/release/info_display --daemon

# Run on multiplexer channel 0 as daemon
sudo ./target/release/info_display --daemon --mux --mux-channel=0
```

Note: The application requires root privileges to access the I2C bus.

## Configuration

The default I2C bus is set to `/dev/i2c-1`. If your display is connected to a different bus, modify the bus path in `src/main.rs`.

### TCA9548A Multiplexer Configuration

The TCA9548A allows you to connect up to 8 I2C devices with the same address on a single I2C bus. This is useful when you want to use multiple OLED displays.

- Default multiplexer address: 0x70 (all address pins connected to GND)
- Address can be changed by connecting A0, A1, A2 pins to VCC
- Each channel (0-7) can have one I2C device connected

## Dependencies

- rppal: Raspberry Pi peripheral access library
- embedded-hal: Hardware abstraction layer for embedded systems
- linux-embedded-hal: Linux implementation of embedded-hal
- ssd1306: Driver for SSD1306 OLED displays
- embedded-graphics: Graphics library for embedded systems
- anyhow: Error handling
- get_if_addrs: Network interface information
- hostname: Hostname retrieval


## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
