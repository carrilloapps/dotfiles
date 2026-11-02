#!/bin/sh
# RedRog panel: graphics and memory details as key=value lines, read every few
# seconds while the panel is open. No root needed, and nothing here wakes the
# NVIDIA card (its figures come from nvidia-smi, only while it is awake).

# Intel GPU: actual and top frequency (i915; xe keeps them per GT)
for c in /sys/class/drm/card[0-9]*; do
  [ -e "$c/device/driver" ] || continue
  case "$(basename "$(readlink -f "$c/device/driver")")" in
    i915)
      echo "igpu_mhz=$(cat "$c/gt_act_freq_mhz" 2>/dev/null || cat "$c/gt_cur_freq_mhz" 2>/dev/null)"
      echo "igpu_max=$(cat "$c/gt_RP0_freq_mhz" 2>/dev/null)" ;;
    xe)
      f="$c/device/tile0/gt0/freq0"
      [ -d "$f" ] && echo "igpu_mhz=$(cat "$f/act_freq")" && echo "igpu_max=$(cat "$f/rp0_freq")" ;;
  esac
done
# the uncore RAPL counter is, on these laptops, essentially the Intel GPU
echo "uncore_uj=$(cat /sys/class/powercap/intel-rapl:0:1/energy_uj 2>/dev/null || echo -1)"

# Memory (kB): what apps can still take, the disk cache, shared and dirty pages
awk '/^MemAvailable:/{print "mem_avail="$2} /^Cached:/{print "mem_cached="$2}
     /^Buffers:/{print "mem_buffers="$2} /^Shmem:/{print "mem_shmem="$2}
     /^Dirty:/{print "mem_dirty="$2}' /proc/meminfo
# zram: data stored and its compressed size (bytes), and the algorithm in use
if [ -r /sys/block/zram0/mm_stat ]; then
  set -- $(cat /sys/block/zram0/mm_stat)
  echo "zram_orig=$1"
  echo "zram_compr=$2"
  echo "zram_alg=$(sed -n 's/.*\[\([^]]*\)\].*/\1/p' /sys/block/zram0/comp_algorithm)"
fi
# share of the last 10 s some task waited for memory
echo "psi=$(awk '/^some/{sub("avg10=", "", $2); print $2}' /proc/pressure/memory 2>/dev/null)"
# the three apps using the most memory (kB)
ps -eo rss=,comm= --sort=-rss | head -3 | awk '{print "top="$1":"$2}'
