#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM
for testbench in traffic_tb traffic_settings_tb traffic_invalid_tb traffic_emergency_tb; do
    if [ "$testbench" = traffic_tb ]; then
        iverilog -g2012 -s "$testbench" -o "$tmpdir/sim" "$root"/traffic_controller/*.v "$root/simulation/$testbench.v"
    else
        cat > "$tmpdir/monitor.v" <<MONITOR
\`timescale 1ns/1ps
module monitor;
  initial begin wait ($testbench.done === 1'b1); #1; \$finish; end
  initial begin #5000000; \$display("FAIL: timeout"); \$finish; end
endmodule
MONITOR
        iverilog -g2012 -s "$testbench" -s monitor -o "$tmpdir/sim" "$root"/traffic_controller/*.v "$root/simulation/$testbench.v" "$tmpdir/monitor.v"
    fi
    (cd "$tmpdir" && vvp ./sim) > "$tmpdir/output.log"
    cat "$tmpdir/output.log"
    if grep -Eq 'FAIL|FAILED' "$tmpdir/output.log" || ! grep -q '^PASS:' "$tmpdir/output.log"; then
        echo "$testbench did not pass" >&2
        exit 1
    fi
done
