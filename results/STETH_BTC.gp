# STETH_BTC Oracle Price History
set datafile separator ","
set terminal svg enhanced size 600 600 background rgb "gray90"
# set output "STETH_BTC.svg"

set title "stETH/BTC Oracle History"

# X-axis: Unix timestamp to human-readable date
set xdata time
set timefmt "%s"
set format x "%d-%b,%l%p"
set xlabel "Date"
set xtics rotate by 90 right

# Y-axes: scale to sensible units
set ylabel "Price (1e-3)"
set y2label "Rate"
set ytics
set y2tics
set format y "%.0f"
set format y2 "%.3f"
set yrange [*:*] extend
set y2range [*:*] extend

set grid
set key autotitle columnheader noenhanced below title " "

# Scale: price divided by 1e15 (milli), rate divided by 1e18
plot "STETH_BTC.csv" skip 1 using 2:($3/1e15) with lines lc rgb "blue", \
     "" skip 1 using 2:($4/1e15) with lines lc rgb "cyan", \
     "" skip 1 using 2:($5/1e18) with lines axes x1y2 lc rgb "red", \
     "" skip 1 using 2:($6/1e18) with lines axes x1y2 lc rgb "orange"
