import argparse
import numpy as np
import sys
import schemes

import matplotlib.pyplot as plt
import matplotlib.patches as mpatch


def plot_scheme(colors):
    fig = plt.figure(figsize=[4.8, 16])
    ax = fig.add_axes([0,0,1,1])
    for i, color in enumerate(colors):
        r1 = mpatch.Rectangle((0, i), 1, 1, color=color)
        ax.add_patch(r1)
        ax.axhline(i, color='k')

    plt.show()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Process some integers.')
    parser.add_argument('path', type=str, help='path to image')
    parser.add_argument('--backend', type=str, default='Colorz',
                        help='backend for color scheme generation (default: wal)')

    args = parser.parse_args()

    generator_ = getattr(schemes, args.backend)
    generator = generator_(args.path)
    colors = generator.get()

    with open('color_scheme.txt', 'w') as f:
        # write colors0-15
        for i, color in enumerate(colors):
            f.write("*.color%d: %s\n" % (i, color.upper()))

        # write special
        f.write("*.background: %s\n" % (colors[0].upper()))
        f.write("*.foreground: %s\n" % (colors[15].upper()))
        f.write("*.cursorColor: %s\n" % (colors[15].upper()))
