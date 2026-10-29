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
	# edge: mainline UART0 is ttyS0; the vendor FIQ console does not exist there.
	if [[ "${BRANCH}" == "edge" ]]; then
		BOOTENV_FILE='rk3506-luckfox-lyra-plc-edge.txt'
		# mainline has no FIQ debugger: UART0 (debug header) is ttyS0 at 1.5 Mbaud
		SERIALCON='ttyS0'
	fi
	return 0
}

# edge = mainline 7.3 with the RK3506 patch series in patch/kernel/archive/rockchip-7.3 (rk3506-*.patch): the
# board boots from the mainline rk3506.dtsi + rk3506b-luckfox-lyra-plc.dts; PWM comes from the posted (unmerged) PWMv4
# series; cpufreq via the OPP table + PWM core supply; CAN0 via the ported rk3576_can driver.
# Drivers the PLC needs that the shared rk35xx vendor config leaves out: the 1.9" ST7789V SPI panel (fbtft),
# Hynitron CST816S touch (backported from mainline), PCF8563 RTC, SHTC3 sensor, the rk3576-type CAN-FD block.
function custom_kernel_config__luckfox-lyra-plc_drivers() {
	[[ "${BRANCH}" != "edge" ]] || opts_y+=(MMC_DW MMC_DW_ROCKCHIP USB_DWC2 USB_DWC2_DUAL_ROLE PHY_ROCKCHIP_INNO_USB2 STMMAC_ETH DWMAC_ROCKCHIP SPI_ROCKCHIP I2C_RK3X KEYBOARD_ADC ROCKCHIP_SARADC ROCKCHIP_THERMAL DW_WATCHDOG NVMEM_ROCKCHIP_OTP PINCTRL_ROCKCHIP GPIO_ROCKCHIP CLK_RK3506 LEDS_GPIO MFD_ROCKCHIP_MFPWM PWM PWM_ROCKCHIP_V4 BACKLIGHT_CLASS_DEVICE BACKLIGHT_PWM REGULATOR_PWM CPU_FREQ CPUFREQ_DT CPUFREQ_DT_PLATDEV CPU_FREQ_GOV_ONDEMAND CPU_FREQ_GOV_SCHEDUTIL CPU_THERMAL THERMAL ROCKCHIP_THERMAL RFKILL ROCKCHIP_DMAMUX USB_ONBOARD_DEV)
	opts_y+=(VT VT_CONSOLE FB FB_TFT FB_TFT_ST7789V FRAMEBUFFER_CONSOLE LOGO LOGO_LINUX_CLUT224
		TOUCHSCREEN_HYNITRON_CST816X RTC_DRV_PCF8563 HWMON SENSORS_SHTC1
		GPIO_CDEV GPIO_CDEV_V1 OF_OVERLAY)
	opts_m+=(CAN CAN_RAW CAN_BCM CAN_DEV CAN_CALC_BITTIMING CAN_ROCKCHIP CAN_RK3576 CAN_ROCKCHIP_RK3576)
}

# The radxa DKMS driver needs five fixes on this board (firmware path on re-probe, ARP offload off, Bluetooth reset on
# close, driver data on the interface instead of the onboard-usb-dev owned USB device, filp_open() from kernel threads
# on 7.x); see patch/misc/aic8800/aic8800-usb-dkms-lyra-plc-fixes.patch. The radxa-aic8800 extension installs and
# builds the package at sort id 500; patch its source in the chroot afterwards and build the modules once more.
function post_install_kernel_debs__600_patch_aic8800_dkms_for_lyra_plc() {
	declare src_dir
	src_dir="$(find "${SDCARD}/usr/src" -maxdepth 1 -type d -name 'aic8800-usb-*' | head -1)"
	if [[ -z "${src_dir}" ]]; then
		display_alert "aic8800 dkms source not in the chroot, skipping the Lyra PLC driver fixes" "${BOARD}" "warn"
		return 0
	fi
	declare ver="${src_dir##*/aic8800-usb-}"
	declare kver
	kver="$(find "${SDCARD}/lib/modules" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | head -1)"
	display_alert "Patching aic8800 dkms ${ver} for the Lyra PLC and rebuilding for ${kver}" "${BOARD}" "info"
	run_host_command_logged patch -p1 -d "${src_dir}" -i "${SRC}/patch/misc/aic8800/aic8800-usb-dkms-lyra-plc-fixes.patch"
	declare -ag if_error_find_files_sdcard=("/var/lib/dkms/aic8800*/*/build/*.log")
	use_clean_environment="yes" chroot_sdcard "dkms build -m aic8800-usb -v ${ver} -k ${kver} --force && dkms install -m aic8800-usb -v ${ver} -k ${kver} --force"
}
