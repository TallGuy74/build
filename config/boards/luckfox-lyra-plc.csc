# Rockchip RK3506B triple core 512MB SoC 2x100MBe eMMC WIFI/BT USB2 CAN RS232 RS485 1.9" SPI LCD
BOARD_NAME="Lyra PLC"
BOARD_VENDOR="luckfox"
BOARDFAMILY="rockchip"
BOOTCONFIG="luckfox-lyra-plc-rk3506b_defconfig"
BOARD_MAINTAINER="TallGuy74"
INTRODUCED="2026"
KERNEL_TARGET="vendor,edge"
KERNEL_TEST_TARGET="vendor"
BOOT_FDT_FILE="rk3506b-luckfox-lyra-plc.dtb"
BOOT_SCENARIO="spl-blobs"
IMAGE_PARTITION_TABLE="gpt"
enable_extension "radxa-aic8800"
AIC8800_TYPE="usb"
BOOT_SOC="rk3506b"
SERIALCON="ttyFIQ0"
PACKAGE_LIST_BOARD="rfkill bluetooth bluez bluez-tools can-utils i2c-tools"

# The PLC's UART2 is the RS485/RS422 field port; the family's default boot environment would put a serial console on
# ttyS2 ("console=both"). Use a board environment that keeps the console on the FIQ debugger (debug header) and tty1.
function post_family_config__luckfox-lyra-plc_bootenv() {
	BOOTENV_FILE='rk3506-luckfox-lyra-plc.txt'
}

# edge = mainline 7.3 with the RK3506 patch series in patch/kernel/archive/rockchip-7.3 (rk3506-*.patch): the
# board boots from the mainline rk3506.dtsi + rk3506b-luckfox-lyra-plc.dts; CAN, PWM (backlight, cpufreq) and the
# AIC8800 Wi-Fi are not available on edge yet.
# Drivers the PLC needs that the shared rk35xx vendor config leaves out: the 1.9" ST7789V SPI panel (fbtft),
# Hynitron CST816S touch (backported from mainline), PCF8563 RTC, SHTC3 sensor, the rk3576-type CAN-FD block.
function custom_kernel_config__luckfox-lyra-plc_drivers() {
	[[ "${BRANCH}" == "edge" ]] && opts_y+=(MMC_DW MMC_DW_ROCKCHIP USB_DWC2 USB_DWC2_DUAL_ROLE PHY_ROCKCHIP_INNO_USB2 STMMAC_ETH DWMAC_ROCKCHIP SPI_ROCKCHIP I2C_RK3X KEYBOARD_ADC ROCKCHIP_SARADC ROCKCHIP_THERMAL DW_WATCHDOG NVMEM_ROCKCHIP_OTP PINCTRL_ROCKCHIP GPIO_ROCKCHIP CLK_RK3506 LEDS_GPIO)
	opts_y+=(VT VT_CONSOLE FB FB_TFT FB_TFT_ST7789V FRAMEBUFFER_CONSOLE LOGO LOGO_LINUX_CLUT224
		TOUCHSCREEN_HYNITRON_CST816X RTC_DRV_PCF8563 HWMON SENSORS_SHTC1
		GPIO_CDEV GPIO_CDEV_V1 OF_OVERLAY)
	opts_m+=(CAN CAN_RAW CAN_BCM CAN_DEV CAN_CALC_BITTIMING CAN_ROCKCHIP CAN_RK3576)
}
