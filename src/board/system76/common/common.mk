# SPDX-License-Identifier: GPL-3.0-only

# Set log level
# 0 - NONE
# 1 - ERROR
# 2 - WARN
# 3 - INFO
# 4 - DEBUG
# 5 - TRACE
CFLAGS+=-DLEVEL=4

# Uncomment to enable debug logging over keyboard parallel port
#CFLAGS+=-DPARALLEL_DEBUG

# Uncomment to enable I2C debug on 0x76
#CFLAGS+=-DI2C_DEBUGGER=0x76

# Set external programmer
PROGRAMMER=$(wildcard /dev/serial/by-id/usb-Arduino*)

# Include system76 common source
SYSTEM76_COMMON_DIR=src/board/system76/common
SRC+=$(wildcard $(SYSTEM76_COMMON_DIR)/*.c)
INCLUDE+=$(wildcard $(SYSTEM76_COMMON_DIR)/include/board/*.h) $(SYSTEM76_COMMON_DIR)/common.mk
CFLAGS+=-I$(SYSTEM76_COMMON_DIR)/include

# Set battery charging thresholds
BATTERY_START_THRESHOLD?=0
BATTERY_END_THRESHOLD?=100

CFLAGS+=\
	-DBATTERY_START_THRESHOLD=$(BATTERY_START_THRESHOLD) \
	-DBATTERY_END_THRESHOLD=$(BATTERY_END_THRESHOLD)

# Add charger
CHARGER?=bq24780s
SRC+=$(SYSTEM76_COMMON_DIR)/charger/$(CHARGER).c

# Add keyboard
ifndef KEYBOARD
$(error KEYBOARD is not set by the board)
endif
KEYBOARD_DIR=src/keyboard/system76/$(KEYBOARD)
include $(KEYBOARD_DIR)/keyboard.mk

# Add kbled
KBLED?=none
SRC+=$(SYSTEM76_COMMON_DIR)/kbled/$(KBLED).c

# Add scratch ROM
include $(SYSTEM76_COMMON_DIR)/scratch/scratch.mk

# Add scratch ROM for flash access
include $(SYSTEM76_COMMON_DIR)/flash/flash.mk

console_internal:
	cargo build --manifest-path tool/Cargo.toml --release
	sudo tool/target/release/system76_ectool console

console_external:
	sudo test -c "$(PROGRAMMER)"
	sleep 1 && echo C | sudo tee "$(PROGRAMMER)" &
	sudo tio -b 1000000 -m INLCRNL -t "$(PROGRAMMER)"

console_external_forced:
	sudo test -c "$(PROGRAMMER)"
	sleep 1 && echo F | sudo tee "$(PROGRAMMER)" &
	sudo tio -b 1000000 -m INLCRNL -t "$(PROGRAMMER)"

flash_internal: $(BUILD)/ec.rom
	cargo build --manifest-path tool/Cargo.toml --release
	sudo tool/target/release/system76_ectool flash $<

flash_external: $(BUILD)/ec.rom
	cargo build --manifest-path ecflash/Cargo.toml --example isp --release
	sudo ecflash/target/release/examples/isp $<
