from abc import ABC, abstractmethod
import util
import logging
import sys
import subprocess
import re
import shutil

logger = logging.getLogger()
handler = logging.StreamHandler()
formatter = logging.Formatter('%(asctime)s %(name)-12s %(levelname)-8s %(message)s')
handler.setFormatter(formatter)
logger.addHandler(handler)
#logger.setLevel(logging.DEBUG)

# Mostly taken from pywal

class SchemeGenerator(ABC):
    @abstractmethod
    def gen_colors(self):
        pass

    @abstractmethod
    def adjust(self, cols, light):
        pass

    @abstractmethod
    def get(self, light=False):
        pass


class Haishoku(SchemeGenerator):
    def __init__(self, img):
        self.img = img
        haishoku_ = __import__('haishoku.haishoku', globals(), locals(), ['Haishoku'], 0)
        self.haishoku = haishoku_.Haishoku

    def gen_colors(self):
        palette = self.haishoku.getPalette(self.img)
        return [util.rgb_to_hex(col[1]) for col in palette]

    def adjust(self, cols, light):
        cols.sort(key=util.rgb_to_yiq)
        raw_colors = [*cols, *cols]
        raw_colors[0] = util.lighten_color(cols[0], 0.40)

        return util.generic_adjust(raw_colors, light)

    def get(self, light=False):
        cols = self.gen_colors()
        return self.adjust(cols, light)


class ColorThief(SchemeGenerator):
    def __init__(self, img):
        self.img = img
        colorthief_ = __import__('colorthief', globals(), locals(), ['ColorThief'], 0)
        self.colorthief = colorthief_.ColorThief

    def gen_colors(self):
        """Loop until 16 colors are generated."""
        color_cmd = self.colorthief(self.img).get_palette

        for i in range(0, 30, 1):
            raw_colors = color_cmd(color_count=8 + i)

            if len(raw_colors) >= 8:
                break

            if i == 30:
                logging.error("ColorThief couldn't generate a suitable palette.")
                sys.exit(1)
            else:
                logging.warning("ColorThief couldn't generate a palette.")
                logging.warning("Trying a larger palette size %s", 8 + i)

        return [util.rgb_to_hex(color) for color in raw_colors]

    def adjust(self, cols, light):
        """Create palette."""
        cols.sort(key=util.rgb_to_yiq)
        raw_colors = [*cols, *cols]

        if light:
            raw_colors[0] = util.lighten_color(cols[0], 0.90)
            raw_colors[7] = util.darken_color(cols[0], 0.75)

        else:
            for color in raw_colors:
                color = util.lighten_color(color, 0.40)

            raw_colors[0] = util.darken_color(cols[0], 0.80)
            raw_colors[7] = util.lighten_color(cols[0], 0.60)

        raw_colors[8] = util.lighten_color(cols[0], 0.20)
        raw_colors[15] = raw_colors[7]

        return raw_colors

    def get(self, light=False):
        """Get colorscheme."""
        cols = self.gen_colors()
        return self.adjust(cols, light)


class Colorz(SchemeGenerator):
    def __init__(self, img):
        self.img = img
        self.colorz = __import__('colorz')

    def gen_colors(self):
        """Generate a colorscheme using Colorz."""
        # pylint: disable=not-callable
        raw_colors = self.colorz.colorz(self.img, n=6, bold_add=0)
        return [util.rgb_to_hex([*color[0]]) for color in raw_colors]

    def adjust(self, cols, light):
        """Create palette."""
        raw_colors = [cols[0], *cols, "#FFFFFF",
                      "#000000", *cols, "#FFFFFF"]

        return util.generic_adjust(raw_colors, light)

    def get(self, light=False):
        """Get colorscheme."""
        cols = self.gen_colors()

        if len(cols) < 6:
            logging.error("colorz failed to generate enough colors.")
            logging.error("Try another backend or another image. (wal --backend)")
            sys.exit(1)

        return self.adjust(cols, light)


class Magick(SchemeGenerator):
    def __init__(self, img):
        self.img = img

        if shutil.which("magick"):
            self.magick_cmd = ["magick", "convert"]
        else:
            logging.error("Imagemagick wasn't found on your system.")
            sys.exit(1)
        #if shutil.which("convert"):
        #    return ["convert"]

    def imagemagick(self, color_count):
        """Call Imagemagick to generate a scheme."""
        flags = ["-resize", "25%", "-colors", str(color_count),
                 "-unique-colors", "txt:-"]
        self.img += "[0]"

        return subprocess.check_output([*self.magick_cmd, self.img, *flags]).splitlines()

    def gen_colors(self):
        """Format the output from imagemagick into a list
           of hex colors."""
        for i in range(0, 20, 1):
            raw_colors = self.imagemagick(16 + i)

            if len(raw_colors) > 16:
                break

            if i == 19:
                logging.error("Imagemagick couldn't generate a suitable palette.")
                sys.exit(1)

            else:
                logging.warning("Imagemagick couldn't generate a palette.")
                logging.warning("Trying a larger palette size %s", 16 + i)

        return [re.search("#.{6}", str(col)).group(0) for col in raw_colors[1:]]

    def adjust(self, colors, light):
        """Adjust the generated colors and store them in a dict that
           we will later save in json format."""
        raw_colors = colors[:1] + colors[8:16] + colors[8:-1]

        # Manually adjust colors.
        if light:
            for color in raw_colors:
                color = util.saturate_color(color, 0.5)

            raw_colors[0] = util.lighten_color(colors[-1], 0.85)
            raw_colors[7] = colors[0]
            raw_colors[8] = util.darken_color(colors[-1], 0.4)
            raw_colors[15] = colors[0]

        else:
            # Darken the background color slightly.
            if raw_colors[0][1] != "0":
                raw_colors[0] = util.darken_color(raw_colors[0], 0.40)

            raw_colors[7] = util.blend_color(raw_colors[7], "#EEEEEE")
            raw_colors[8] = util.darken_color(raw_colors[7], 0.30)
            raw_colors[15] = util.blend_color(raw_colors[15], "#EEEEEE")

        return raw_colors

    def get(self, light=False):
        """Get colorscheme."""
        colors = self.gen_colors()
        return self.adjust(colors, light)
