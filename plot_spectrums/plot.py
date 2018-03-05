import os
import csv
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker

magnitudes = ['0.05', '0.25', '0.5', '0.75', '1.0', '1.25', '2.0', '3.0']
y_limits = [0.06, 0.3, 0.5, 0.7, 0.8, 0.9, 1.4, 2.5]

for i, mag_str in enumerate(magnitudes):
    data = []
    with open(os.path.join('spec_data', mag_str + '.csv')) as f:
        csv_reader = csv.reader(f)
        label = next(csv_reader)
        header = next(csv_reader)
        for line in csv_reader:
            time, sa = map(float, line)
            data.append((time, sa))

    width_in = 4
    height_in = width_in * (250/350) # To match iOS view
    tight_layout_data = {
        'rect': [0, 0, 1, 0.95]
    }
    fig, ax = plt.subplots(1, 1, figsize=(width_in, height_in), dpi=300)
    fig.subplots_adjust(bottom=0.16, top=0.9, left=0.18, right=0.95)
    # plt.tight_layout()
    ax.set_xmargin(0.4)
    ax.yaxis.set_major_formatter(ticker.StrMethodFormatter("{x: >5.2f}"))
    ax.set_ylim(0, y_limits[i])
    ax.set_xlim(0)
    x, y = zip(*data)
    ax.plot(x, y)
    ax.set_xlabel("T (sec)")
    ax.set_ylabel("$\\mathrm{S_a (g)}$")
    # ax.set_title("$\\mathrm{S_s=" + mag_str + "}$")
    ax.grid()
    plt.savefig(os.path.join('plots', mag_str + '.png'))
