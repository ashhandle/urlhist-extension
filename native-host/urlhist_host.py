#!/Library/Frameworks/Python.framework/Versions/3.9/bin/python3
"""
Native messaging host for the URL History Tracker extension.
Reads URL messages from Chrome and appends them to URLHIST.txt in the OS temp directory.
"""
import json
import os
import struct
import sys
import tempfile

URLHIST_PATH = os.path.join(tempfile.gettempdir(), "URLHIST.txt")


def read_message():
    raw_length = sys.stdin.buffer.read(4)
    if len(raw_length) < 4:
        return None
    length = struct.unpack("<I", raw_length)[0]
    data = sys.stdin.buffer.read(length)
    return json.loads(data.decode("utf-8"))


def send_message(payload):
    encoded = json.dumps(payload).encode("utf-8")
    sys.stdout.buffer.write(struct.pack("<I", len(encoded)))
    sys.stdout.buffer.write(encoded)
    sys.stdout.buffer.flush()


def main():
    while True:
        message = read_message()
        if message is None:
            break

        url = message.get("url", "")
        timestamp = message.get("timestamp", "")
        title = message.get("title", "").strip()
        name = message.get("name", "").strip()

        if url:
            fields = [url]
            if title or name:
                fields.append(title)
            if name:
                fields.append(name)
            line = f"{timestamp}  " + ", ".join(fields)
            with open(URLHIST_PATH, "a", encoding="utf-8") as f:
                f.write(line + "\n")

        send_message({"status": "ok"})


if __name__ == "__main__":
    main()
