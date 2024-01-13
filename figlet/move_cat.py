import sys
import os

def move_text(file, x, y):
    with open(file, 'r') as f:
        lines = [line.rstrip('\n') for line in f.readlines()]  # Remove only newline characters
    width = max(len(line) for line in lines)
    height = len(lines)
    layout = [[' ' for _ in range(x + width)] for _ in range(y + height)]
    for i, line in enumerate(lines):
        for j, c in enumerate(line):
            layout[y + i][x + j] = c
    return '\n'.join(''.join(line) for line in layout)

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: move_text.py file x y")
    else:
        file, x, y = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
        moved_text = move_text(file, x, y)
        print(moved_text)
        
        # Extract the original file name from sys.argv[1]
        original_file_name = os.path.basename(file)
        
        # Save the moved text with the original file name
        with open(f'./result/moved_{original_file_name}', 'w') as f:
            f.write(moved_text)

