#!/bin/bash
sudo dd iflag=dsync oflag=dsync if=spl/tiny210-spl.bin of=/dev/sdb seek=1
sync
sudo umount /dev/sdb
