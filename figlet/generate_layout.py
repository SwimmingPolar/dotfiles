# generate_layout.py
import random
import sys

DENSITY=0.015

def generate_layout(width, height, density=DENSITY):
    layout = []
    for _ in range(height):
        line = ''.join('*' if random.random() < density else ' ' for _ in range(width))
        layout.append(line)
    return '\n'.join(layout)

if __name__ == "__main__":
    if len(sys.argv) < 3 or len(sys.argv) > 4:
        print("Usage: generate_layout.py width height [density]")
    else:
        width, height = int(sys.argv[1]), int(sys.argv[2])
        density = float(sys.argv[3]) if len(sys.argv) == 4 else DENSITY
        layout = generate_layout(width, height, density)
        print(layout)
        with open('./result/layout.txt', 'w') as f:
            f.write(layout)

