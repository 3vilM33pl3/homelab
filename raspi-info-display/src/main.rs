mod tca9548a;

use embedded_graphics::{
    mono_font::{ascii::FONT_6X10, iso_8859_9::FONT_7X14_BOLD, MonoTextStyle},
    pixelcolor::BinaryColor,
    prelude::*,
    text::Text,
};
use linux_embedded_hal::I2cdev;
use ssd1306::{prelude::*, I2CDisplayInterface, Ssd1306};
use anyhow::Result;
use get_if_addrs::get_if_addrs;
use sysinfo::{System, Disks};
use std::fs;
use std::env;
use std::thread;
use std::time::Duration;
use std::sync::{Arc, Mutex};
use daemonize::Daemonize;
use tca9548a::Tca9548a;

fn get_ip_address() -> Result<String> {
    // Get all network interfaces
    let interfaces = get_if_addrs()?;
    
    // Look for the first non-loopback interface with an IPv4 address
    for interface in interfaces {
        if !interface.is_loopback() {
            if let std::net::IpAddr::V4(ipv4) = interface.addr.ip() {
                return Ok(ipv4.to_string());
            }
        }
    }
    
    // If no suitable interface is found, return localhost
    Ok("127.0.0.1".to_string())
}

fn get_domain() -> String {
    // Try to get domain from /etc/resolv.conf
    if let Ok(contents) = fs::read_to_string("/etc/resolv.conf") {
        for line in contents.lines() {
            if line.starts_with("search ") {
                return line[7..].trim().to_string();
            }
        }
    }
    
    // Fallback: try to get from hostname -d command
    if let Ok(output) = std::process::Command::new("hostname")
        .arg("-d")
        .output() {
        if output.status.success() {
            let domain = String::from_utf8_lossy(&output.stdout).trim().to_string();
            if !domain.is_empty() {
                return domain;
            }
        }
    }
    
    // Default fallback
    "local".to_string()
}

fn get_cpu_temp() -> Result<String> {
    let temp = fs::read_to_string("/sys/class/thermal/thermal_zone0/temp")?;
    let temp_c = temp.trim().parse::<f32>()? / 1000.0;
    Ok(format!("{:.1}C", temp_c))
}

fn get_memory_info(sys: &System) -> String {
    let total_mem = sys.total_memory() / 1024 / 1024; // Convert to MB
    let used_mem = (sys.total_memory() - sys.free_memory()) / 1024 / 1024;
    format!("{}/{}MB", used_mem, total_mem)
}

fn get_disk_usage() -> String {
    let disks = Disks::new_with_refreshed_list();
    let mut total_size = 0;
    let mut total_used = 0;
    
    for disk in disks.list() {
        total_size += disk.total_space();
        total_used += disk.total_space() - disk.available_space();
    }
    
    let total_gb = total_size / 1024 / 1024 / 1024;
    let used_gb = total_used / 1024 / 1024 / 1024;
    format!("{}/{}GB", used_gb, total_gb)
}

fn get_uptime() -> String {
    let uptime = fs::read_to_string("/proc/uptime")
        .unwrap_or_else(|_| "0".to_string());
    let seconds = uptime.split_whitespace()
        .next()
        .and_then(|s| s.parse::<f64>().ok())
        .unwrap_or(0.0);
    
    let days = (seconds / 86400.0) as u64;
    let hours = ((seconds % 86400.0) / 3600.0) as u64;
    let minutes = ((seconds % 3600.0) / 60.0) as u64;
    
    format!("{}d {}h {}m", days, hours, minutes)
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args: Vec<String> = env::args().collect();
    
    // Parse command line arguments
    let mut interval_seconds = 5; // Default to 5 seconds
    let mut clear_only = false;
    let mut daemon_mode = false;
    let mut use_multiplexer = false;
    let mut mux_channel = 0u8;
    let mut mux_address = 0x70u8;
    
    for i in 1..args.len() {
        match args[i].as_str() {
            "--clear" => clear_only = true,
            "--daemon" | "-d" => daemon_mode = true,
            "--mux" => use_multiplexer = true,
            "--mux-channel" => {
                if i + 1 < args.len() {
                    if let Ok(channel) = args[i + 1].parse::<u8>() {
                        if channel <= 7 {
                            mux_channel = channel;
                            use_multiplexer = true;
                        }
                    }
                }
            }
            "--mux-address" => {
                if i + 1 < args.len() {
                    if let Ok(addr) = u8::from_str_radix(args[i + 1].trim_start_matches("0x"), 16) {
                        mux_address = addr;
                    }
                }
            }
            "--interval" | "-i" => {
                if i + 1 < args.len() {
                    if let Ok(seconds) = args[i + 1].parse::<u64>() {
                        interval_seconds = seconds;
                    }
                }
            }
            arg if arg.starts_with("--interval=") => {
                if let Some(value) = arg.strip_prefix("--interval=") {
                    if let Ok(seconds) = value.parse::<u64>() {
                        interval_seconds = seconds;
                    }
                }
            }
            arg if arg.starts_with("--mux-channel=") => {
                if let Some(value) = arg.strip_prefix("--mux-channel=") {
                    if let Ok(channel) = value.parse::<u8>() {
                        if channel <= 7 {
                            mux_channel = channel;
                            use_multiplexer = true;
                        }
                    }
                }
            }
            "--help" | "-h" => {
                println!("Usage: {} [OPTIONS]", args[0]);
                println!("\nOptions:");
                println!("  --clear               Clear the display and exit");
                println!("  --daemon, -d          Run in daemon mode");
                println!("  --interval=<seconds>  Set update interval (default: 5)");
                println!("  --mux                 Use TCA9548A I2C multiplexer");
                println!("  --mux-channel=<0-7>   Select multiplexer channel (default: 0)");
                println!("  --mux-address=<addr>  Set multiplexer I2C address (default: 0x70)");
                println!("  --help, -h            Show this help message");
                return Ok(());
            }
            _ => {}
        }
    }
    
    // Handle daemon mode
    if daemon_mode {
        let daemonize = Daemonize::new()
            .pid_file("/tmp/info_display.pid")
            .chown_pid_file(true)
            .working_directory("/tmp");

        match daemonize.start() {
            Ok(_) => {}, // Successfully daemonized, continue with normal execution
            Err(e) => {
                eprintln!("Error starting daemon: {}", e);
                std::process::exit(1);
            }
        }
    }
    
    // Handle clear-only mode
    if clear_only {
        if use_multiplexer {
            // Setup multiplexer and select channel
            let i2c = Arc::new(Mutex::new(I2cdev::new("/dev/i2c-1")?));
            let mut mux = Tca9548a::with_address(Arc::clone(&i2c), mux_address);
            mux.select_channel(mux_channel)?;
            drop(mux);
            
            // Now use regular I2C (the channel is already selected)
            let i2c = I2cdev::new("/dev/i2c-1")?;
            let interface = I2CDisplayInterface::new(i2c);
            let mut display = Ssd1306::new(
                interface,
                DisplaySize128x64,
                DisplayRotation::Rotate0,
            )
            .into_buffered_graphics_mode();
            display.init().unwrap();
            display.clear(BinaryColor::Off).unwrap();
            display.flush().unwrap();
        } else {
            let i2c = I2cdev::new("/dev/i2c-1")?;
            let interface = I2CDisplayInterface::new(i2c);
            let mut display = Ssd1306::new(
                interface,
                DisplaySize128x64,
                DisplayRotation::Rotate0,
            )
            .into_buffered_graphics_mode();
            display.init().unwrap();
            display.clear(BinaryColor::Off).unwrap();
            display.flush().unwrap();
        }
        return Ok(());
    }

    // Initialize display based on multiplexer usage
    let (mut display, _mux_handle) = if use_multiplexer {
        println!("Using TCA9548A multiplexer on address 0x{:02X}, channel {}", mux_address, mux_channel);
        
        // Create shared I2C bus and multiplexer
        let i2c_shared = Arc::new(Mutex::new(I2cdev::new("/dev/i2c-1")?));
        let mut mux = Tca9548a::with_address(Arc::clone(&i2c_shared), mux_address);
        mux.select_channel(mux_channel)?;
        
        // Store mux in Arc<Mutex> to keep it alive
        let mux_handle = Arc::new(Mutex::new(mux));
        
        // Create a new I2C connection for the display
        // (the channel is already selected on the multiplexer)
        let i2c = I2cdev::new("/dev/i2c-1")?;
        let interface = I2CDisplayInterface::new(i2c);
        
        let mut display = Ssd1306::new(
            interface,
            DisplaySize128x64,
            DisplayRotation::Rotate0,
        )
        .into_buffered_graphics_mode();
        
        display.init().unwrap();
        (display, Some(mux_handle))
    } else {
        // Standard I2C connection
        let i2c = I2cdev::new("/dev/i2c-1")?;
        let interface = I2CDisplayInterface::new(i2c);
        
        let mut display = Ssd1306::new(
            interface,
            DisplaySize128x64,
            DisplayRotation::Rotate0,
        )
        .into_buffered_graphics_mode();
        
        display.init().unwrap();
        (display, None)
    };

    loop {
        // Clear display
        display.clear(BinaryColor::Off).unwrap();

        // Initialize system info
        let mut sys = System::new_all();
        sys.refresh_all();

        // Get system information
        let hostname = hostname::get()
            .unwrap()
            .to_string_lossy()
            .into_owned();
        let domain = get_domain();
        let ip_address = get_ip_address().unwrap();
        let cpu_temp = get_cpu_temp().unwrap_or_else(|_| "N/A".to_string());
        let memory_info = get_memory_info(&sys);
        let disk_usage = get_disk_usage();
        let uptime = get_uptime();

        let yellow_text = format!(
            "{}.{}",
            hostname, domain
        );

        let blue_text = format!(
            "{}\ncpu: {}\nuptime: {}\nmemory: {}\ndisk: {}",
            ip_address, cpu_temp, uptime, memory_info, disk_usage
        );

        let style = MonoTextStyle::new(&FONT_7X14_BOLD, BinaryColor::On);
        Text::new(&yellow_text, Point::new(0, 8), style).draw(&mut display).unwrap();

        let style = MonoTextStyle::new(&FONT_6X10, BinaryColor::On);
        Text::new(&blue_text, Point::new(0, 22), style).draw(&mut display).unwrap();

        // Flush to the display
        display.flush().unwrap();

        // Sleep for the specified interval
        thread::sleep(Duration::from_secs(interval_seconds));
    }
}
