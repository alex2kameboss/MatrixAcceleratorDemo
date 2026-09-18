#!/usr/bin/env python3
"""
Simple UART Image Processing GUI
=================================

Workflow
--------
1. Click "Select Image" -> choose an image from disk. It is shown in the
   left ("Original") viewer. If it isn't RGBA it is converted.
2. Click "Start" -> the app:
     - clears the right viewer and the metrics table
     - sends (width, height, rgba_bytes) to the board over UART
     - status bar shows "Send image", then "Wait for response"
3. A background thread listens on UART for the board's reply, following
   this text/binary protocol:

       $IMG\n
       <raw RGBA bytes, width * height * 4 bytes, row-major RGBA8888>
       $METRICS\n
       <csv line 1>\n
       <csv line 2>\n
       $END\n

   The returned image is assumed to have the same width/height as the
   image that was sent (the board processes but does not resize it).
   If your board sends the result dimensions back explicitly, adjust
   SerialWorker._listen_for_response() accordingly.

4. When the image + metrics fully arrive, the right viewer shows the
   result, the table shows the two CSV lines (line 1 = column headers,
   line 2 = values), and the status bar says "Done".

Dependencies
------------
    pip install pyserial pillow

Configuration
-------------
Edit SERIAL_PORT / BAUD_RATE below to match your board. Edit
SerialWorker._send_image() if your firmware expects a different header
than "uint32 width, uint32 height" before the raw RGBA bytes.
"""

import queue
import struct
import threading
import tkinter as tk
import time
from tkinter import ttk, filedialog, messagebox

from PIL import Image, ImageTk

try:
    import serial
except ImportError:
    serial = None


# ---------------------------------------------------------------------------
# Configuration - adjust to match your hardware
# ---------------------------------------------------------------------------
SERIAL_PORT = "/dev/ttyUSB1"        # e.g. "/dev/ttyUSB0" on Linux/Mac
BAUD_RATE = 115200
SERIAL_TIMEOUT = 1000000    # seconds; used for each line/byte read attempt

CMD_IMG = "$RESULT_IMAGE"
CMD_METRICS = "$RESULT_METRICS"
CMD_END = "$END"

PREVIEW_MAX_SIDE = 400      # scale previews down to fit the window


# ---------------------------------------------------------------------------
# Background UART worker
# ---------------------------------------------------------------------------
class SerialWorker(threading.Thread):
    """Owns the serial port. Runs on its own thread so the GUI never blocks.
    Talks to the GUI only through `event_queue` (thread-safe)."""

    def __init__(self, port, baud, event_queue):
        super().__init__(daemon=True)
        self.port_name = port
        self.baud = baud
        self.event_queue = event_queue
        self.ser = None
        self.send_queue = queue.Queue()
        self.last_size = (0, 0)
        self._stop_flag = threading.Event()

    # -- lifecycle -----------------------------------------------------
    def stop(self):
        self._stop_flag.set()

    def run(self):
        try:
            self.ser = serial.Serial(self.port_name, self.baud, timeout=SERIAL_TIMEOUT)
        except Exception as exc:
            self.event_queue.put(("error", f"Could not open {self.port_name}: {exc}"))
            return

        while not self._stop_flag.is_set():
            try:
                width, height, rgba_bytes = self.send_queue.get(timeout=0.2)
            except queue.Empty:
                continue

            try:
                self.last_size = (width, height)
                self._send_image(width, height, rgba_bytes)
                self.event_queue.put(("status", "Wait for response"))
                self._listen_for_response()
            except Exception as exc:
                self.event_queue.put(("error", str(exc)))

        if self.ser and self.ser.is_open:
            self.ser.close()

    # -- called from the GUI thread -------------------------------------
    def request_send(self, width, height, rgba_bytes):
        self.send_queue.put((width, height, rgba_bytes))

    # -- sending -------------------------------------------------------
    def _send_image(self, width, height, rgba_bytes):
        """Sends width, height, then the raw RGBA byte array.

        Wire format (change this to match the firmware you already wrote):
            uint32 width  (little endian)
            uint32 height (little endian)
            raw bytes: width * height * 4  (R,G,B,A per pixel)
        """
        self.ser.write(f"$START\r".encode('utf-8'))
        time.sleep(0.1)
        self.ser.write(f"$WIDTH{width}\r".encode('utf-8'))
        time.sleep(0.1)
        self.ser.write(f"$HEIGHT{height}\r".encode('utf-8'))
        time.sleep(0.1)
        self.ser.write(f"$DATA_START\r".encode('utf-8'))
        time.sleep(0.1)
        print("Send image")
        self.ser.write(rgba_bytes)
        self.ser.write(f"$DATA_END\r".encode('utf-8'))
        self.ser.flush()
        

    # -- receiving -------------------------------------------------------
    def _read_line(self):
        """Reads one newline-terminated ASCII line (blocking up to the
        serial timeout per read attempt; returns "" on a timed-out read)."""
        raw = self.ser.readline()
        return raw.decode(errors="replace").rstrip()

    def _read_exact(self, n):
        buf = bytearray()
        while len(buf) < n and not self._stop_flag.is_set():
            print(n - len(buf))
            chunk = self.ser.read(n - len(buf))
            if chunk:
                buf.extend(chunk)
        return bytes(buf)

    def _wait_for_token(self, token):
        while not self._stop_flag.is_set():
            line = self._read_line()
            print(line)
            if line == token:
                return
            # ignore blank/timeout lines and anything else until we see it

    def _listen_for_response(self):
        width, height = self.last_size
        n_bytes = width * height * 4
        print("Wait result")
        self._wait_for_token(CMD_IMG)
        if self._stop_flag.is_set():
            return

        print("Get result")
        rgba = self._read_exact(n_bytes)

        print("Wait metrics")
        self._wait_for_token(CMD_METRICS)
        print("Get metrics")
        csv_line1 = self._read_line()
        csv_line2 = self._read_line()
        print(csv_line1)
        print(csv_line2)

        print("Wait end")
        line = self._read_line()
        print(line)
        #self._wait_for_token(CMD_END)
        print("Done")

        self.event_queue.put(("result", (width, height, rgba, csv_line1, csv_line2)))
        self.event_queue.put(("status", "Done"))


# ---------------------------------------------------------------------------
# GUI
# ---------------------------------------------------------------------------
class App(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("UART Image Processor")
        self.geometry("950x650")

        self.source_image = None    # PIL Image, RGBA, full size
        self.source_photo = None    # ImageTk.PhotoImage kept alive
        self.result_photo = None

        self.event_queue = queue.Queue()
        self.worker = None

        self._build_ui()
        self._start_worker()
        self.after(100, self._poll_events)

    # -- UI construction -----------------------------------------------
    def _build_ui(self):
        top = ttk.Frame(self, padding=8)
        top.pack(side=tk.TOP, fill=tk.X)

        self.select_btn = ttk.Button(top, text="Select Image", command=self.on_select_image)
        self.select_btn.pack(side=tk.LEFT, padx=4)

        self.start_btn = ttk.Button(top, text="Start", command=self.on_start, state=tk.DISABLED)
        self.start_btn.pack(side=tk.LEFT, padx=4)

        images_frame = ttk.Frame(self, padding=8)
        images_frame.pack(side=tk.TOP, fill=tk.BOTH, expand=True)

        left = ttk.LabelFrame(images_frame, text="Original")
        left.pack(side=tk.LEFT, fill=tk.BOTH, expand=True, padx=4)
        self.original_label = ttk.Label(left)
        self.original_label.pack(fill=tk.BOTH, expand=True, padx=4, pady=4)

        right = ttk.LabelFrame(images_frame, text="Result")
        right.pack(side=tk.LEFT, fill=tk.BOTH, expand=True, padx=4)
        self.result_label = ttk.Label(right)
        self.result_label.pack(fill=tk.BOTH, expand=True, padx=4, pady=4)

        table_frame = ttk.LabelFrame(self, text="Metrics", padding=4)
        table_frame.pack(side=tk.TOP, fill=tk.X, padx=8, pady=(0, 4))
        self.table = ttk.Treeview(table_frame, show="headings", height=2)
        self.table.pack(fill=tk.X)

        self.status_var = tk.StringVar(value="Idle")
        status_bar = ttk.Label(self, textvariable=self.status_var, relief=tk.SUNKEN, anchor=tk.W, padding=4)
        status_bar.pack(side=tk.BOTTOM, fill=tk.X)

    def _start_worker(self):
        if serial is None:
            messagebox.showerror("Missing dependency", "pyserial is not installed.\nRun: pip install pyserial")
            return
        self.worker = SerialWorker(SERIAL_PORT, BAUD_RATE, self.event_queue)
        self.worker.start()

    # -- button handlers -----------------------------------------------
    def on_select_image(self):
        path = filedialog.askopenfilename(
            title="Select an image",
            filetypes=[("Images", "*.png *.jpg *.jpeg *.bmp *.gif *.tiff")],
        )
        if not path:
            return
        try:
            img = Image.open(path)
            if img.mode != "RGBA":
                img = img.convert("RGBA")
        except Exception as exc:
            messagebox.showerror("Could not open image", str(exc))
            return

        self.source_image = img
        self._show_image(img, self.original_label, is_source=True)
        self.start_btn.config(state=tk.NORMAL)
        self.status_var.set("Image loaded")

    def on_start(self):
        if self.source_image is None:
            return

        # clear result viewer + table
        self.result_label.config(image="")
        self.result_photo = None
        self._clear_table()

        width, height = self.source_image.size
        rgba_bytes = self.source_image.tobytes()  # RGBA RGBA RGBA ...

        self.status_var.set("Send image")
        self.start_btn.config(state=tk.DISABLED)
        self.select_btn.config(state=tk.DISABLED)

        if self.worker is None:
            messagebox.showerror("Not connected", "Serial worker is not running.")
            self.start_btn.config(state=tk.NORMAL)
            self.select_btn.config(state=tk.NORMAL)
            return

        self.worker.request_send(width, height, rgba_bytes)

    # -- helpers -----------------------------------------------
    def _show_image(self, pil_img, label_widget, is_source):
        preview = pil_img.copy()
        preview.thumbnail((PREVIEW_MAX_SIDE, PREVIEW_MAX_SIDE))
        photo = ImageTk.PhotoImage(preview)
        label_widget.config(image=photo)
        if is_source:
            self.source_photo = photo
        else:
            self.result_photo = photo

    def _clear_table(self):
        self.table.delete(*self.table.get_children())
        self.table["columns"] = ()

    def _populate_table(self, header_line, value_line):
        headers = [h.strip() for h in header_line.split(",")]
        values = [v.strip() for v in value_line.split(",")]

        self.table["columns"] = headers
        for h in headers:
            self.table.heading(h, text=h)
            self.table.column(h, width=100, anchor=tk.CENTER)

        # pad/truncate values to match header length so it never raises
        if len(values) < len(headers):
            values += [""] * (len(headers) - len(values))
        self.table.insert("", tk.END, values=values[: len(headers)])

    # -- event queue polling (runs on the GUI thread) --------------------
    def _poll_events(self):
        try:
            while True:
                kind, payload = self.event_queue.get_nowait()
                if kind == "status":
                    self.status_var.set(payload)
                elif kind == "error":
                    messagebox.showerror("Error", payload)
                    self.status_var.set("Error")
                    self.start_btn.config(state=tk.NORMAL)
                    self.select_btn.config(state=tk.NORMAL)
                elif kind == "result":
                    width, height, rgba, csv1, csv2 = payload
                    try:
                        img = Image.frombytes("RGBA", (width, height), rgba)
                        self._show_image(img, self.result_label, is_source=False)
                    except Exception as exc:
                        messagebox.showerror("Could not decode result image", str(exc))
                    self._populate_table(csv1, csv2)
                    self.start_btn.config(state=tk.NORMAL)
                    self.select_btn.config(state=tk.NORMAL)
        except queue.Empty:
            pass
        self.after(100, self._poll_events)

    def destroy(self):
        if self.worker:
            self.worker.stop()
        super().destroy()


if __name__ == "__main__":
    app = App()
    app.mainloop()