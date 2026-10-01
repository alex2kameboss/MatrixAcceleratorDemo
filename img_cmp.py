#!/usr/bin/env python3
"""
Image Diff Heatmap
===================

Pick two images from disk, compare them pixel by pixel, and view a heat
map of where (and how much) they differ.

Workflow
--------
1. "Select Image A" / "Select Image B" -> choose two files, each is shown
   in its own preview panel.
2. "Compare" -> for every pixel, computes the mean absolute difference
   across the R, G, B channels (alpha is ignored), normalizes it to
   0-255, and renders it through a heat colormap (blue = identical,
   red = maximally different). The heat map is shown in the third panel.
3. A stats line reports mean / max difference and the percentage of
   pixels that differ by more than a threshold.

Notes
-----
- If the two images differ in size, Image B is resized to match Image A
  before comparing (nearest-neighbour would distort a diff, so this uses
  a standard resample -- if you need an exact pixel-for-pixel comparison,
  make sure both files are already the same resolution).
- Images are compared as RGB (any alpha channel is dropped for the diff).

Dependencies
------------
    pip install pillow numpy
"""

import tkinter as tk
from tkinter import ttk, filedialog, messagebox

import numpy as np
from PIL import Image, ImageTk

PREVIEW_MAX_SIDE = 320
DIFF_THRESHOLD = 10  # per-pixel diff (0-255) above which a pixel counts as "different"


def apply_heat_colormap(norm):
    """norm: 2D float array in [0, 1]. Returns a HxWx3 uint8 RGB array
    using a jet-like colormap (blue -> green -> yellow -> red)."""
    r = np.clip(1.5 - np.abs(4 * norm - 3), 0, 1)
    g = np.clip(1.5 - np.abs(4 * norm - 2), 0, 1)
    b = np.clip(1.5 - np.abs(4 * norm - 1), 0, 1)
    rgb = np.stack([r, g, b], axis=-1)
    return (rgb * 255).astype(np.uint8)


class App(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("Image Diff Heatmap")
        self.geometry("1050x520")

        self.image_a = None  # PIL Image, RGB, full size
        self.image_b = None
        self.photo_a = None  # kept alive
        self.photo_b = None
        self.photo_heat = None

        self._build_ui()

    # -- UI construction -----------------------------------------------
    def _build_ui(self):
        top = ttk.Frame(self, padding=8)
        top.pack(side=tk.TOP, fill=tk.X)

        ttk.Button(top, text="Select Image A", command=lambda: self.on_select("A")).pack(side=tk.LEFT, padx=4)
        ttk.Button(top, text="Select Image B", command=lambda: self.on_select("B")).pack(side=tk.LEFT, padx=4)

        self.compare_btn = ttk.Button(top, text="Compare", command=self.on_compare, state=tk.DISABLED)
        self.compare_btn.pack(side=tk.LEFT, padx=4)

        panels = ttk.Frame(self, padding=8)
        panels.pack(side=tk.TOP, fill=tk.BOTH, expand=True)

        frame_a = ttk.LabelFrame(panels, text="Image A")
        frame_a.pack(side=tk.LEFT, fill=tk.BOTH, expand=True, padx=4)
        self.label_a = ttk.Label(frame_a)
        self.label_a.pack(fill=tk.BOTH, expand=True, padx=4, pady=4)

        frame_b = ttk.LabelFrame(panels, text="Image B")
        frame_b.pack(side=tk.LEFT, fill=tk.BOTH, expand=True, padx=4)
        self.label_b = ttk.Label(frame_b)
        self.label_b.pack(fill=tk.BOTH, expand=True, padx=4, pady=4)

        frame_heat = ttk.LabelFrame(panels, text="Heat Map")
        frame_heat.pack(side=tk.LEFT, fill=tk.BOTH, expand=True, padx=4)
        self.label_heat = ttk.Label(frame_heat)
        self.label_heat.pack(fill=tk.BOTH, expand=True, padx=4, pady=4)

        self.status_var = tk.StringVar(value="Select two images to compare")
        status_bar = ttk.Label(self, textvariable=self.status_var, relief=tk.SUNKEN, anchor=tk.W, padding=4)
        status_bar.pack(side=tk.BOTTOM, fill=tk.X)

    # -- button handlers -----------------------------------------------
    def on_select(self, which):
        path = filedialog.askopenfilename(
            title=f"Select Image {which}",
            filetypes=[("Images", "*.png *.jpg *.jpeg *.bmp *.gif *.tiff")],
        )
        if not path:
            return
        try:
            img = Image.open(path).convert("RGB")
        except Exception as exc:
            messagebox.showerror("Could not open image", str(exc))
            return

        if which == "A":
            self.image_a = img
            self._show_image(img, self.label_a, "a")
        else:
            self.image_b = img
            self._show_image(img, self.label_b, "b")

        if self.image_a is not None and self.image_b is not None:
            self.compare_btn.config(state=tk.NORMAL)
        self.status_var.set(f"Image {which} loaded")

    def on_compare(self):
        img_a = self.image_a
        img_b = self.image_b

        if img_a.size != img_b.size:
            img_b = img_b.resize(img_a.size)
            self.status_var.set(f"Resized Image B to {img_a.size[0]}x{img_a.size[1]} to match Image A")

        arr_a = np.asarray(img_a, dtype=np.float32)
        arr_b = np.asarray(img_b, dtype=np.float32)

        diff = np.abs(arr_a - arr_b).mean(axis=-1)  # HxW, 0-255 scale

        max_diff = float(diff.max())
        mean_diff = float(diff.mean())
        pct_different = float((diff > DIFF_THRESHOLD).mean() * 100)

        norm = diff / 255.0
        heat_rgb = apply_heat_colormap(norm)
        heat_img = Image.fromarray(heat_rgb, mode="RGB")

        self._show_image(heat_img, self.label_heat, "heat")

        self.status_var.set(
            f"Mean diff: {mean_diff:.2f} | Max diff: {max_diff:.2f} | "
            f"Pixels differing (> {DIFF_THRESHOLD}): {pct_different:.2f}%"
        )

    # -- helpers -----------------------------------------------
    def _show_image(self, pil_img, label_widget, slot):
        preview = pil_img.copy()
        preview.thumbnail((PREVIEW_MAX_SIDE, PREVIEW_MAX_SIDE))
        photo = ImageTk.PhotoImage(preview)
        label_widget.config(image=photo)
        if slot == "a":
            self.photo_a = photo
        elif slot == "b":
            self.photo_b = photo
        else:
            self.photo_heat = photo


if __name__ == "__main__":
    app = App()
    app.mainloop()