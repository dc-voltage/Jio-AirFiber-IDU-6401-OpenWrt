#!/bin/sh
# ==============================================================================
# Jio AirFiber IDU-6401 (Sercomm JIDU6401) - Critical Factory MTD Backup Script
# Created by Boss DC VOLTAGE (https://github.com/dc-voltage)
# ==============================================================================

set -e

BACKUP_DIR="/tmp/idu6401_backups"
mkdir -p "$BACKUP_DIR"

echo "=== [1/6] Backing up Factory / EEPROM (Wi-Fi Calibration) ==="
nanddump -f "$BACKUP_DIR/Factory.bin" /dev/mtd4

echo "=== [2/6] Backing up BL2 (Bootloader Stage 2) ==="
nanddump -f "$BACKUP_DIR/BL2.bin" /dev/mtd1

echo "=== [3/6] Backing up FIP (ATF + U-Boot) ==="
nanddump -f "$BACKUP_DIR/FIP.bin" /dev/mtd5

echo "=== [4/6] Backing up U-Boot Environment ==="
nanddump -f "$BACKUP_DIR/uboot-env.bin" /dev/mtd2

echo "=== [5/6] Backing up Sercomm Manufacturing Data (MFG) ==="
nanddump -f "$BACKUP_DIR/MFG.bin" /dev/mtd3

echo "=== [6/6] Backing up Jio Reserved / Factory Keys ==="
nanddump -f "$BACKUP_DIR/Jio-Reserved.bin" /dev/mtd10

echo ""
echo "All critical factory partitions successfully dumped to $BACKUP_DIR:"
ls -lh "$BACKUP_DIR"
echo ""
echo "IMPORTANT: Copy these files to your PC immediately via SCP or SSH!"
