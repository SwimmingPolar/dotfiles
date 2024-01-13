# overlap_texts.py
import sys
import argparse

def read_file(file):
    with open(file, 'r', encoding='utf-8') as f:
        return [list(line.rstrip('\n')) for line in f.readlines()]

def overlap_files(files):
    # Read all files into 2D lists
    texts = [read_file(file) for file in files]
    
    # Calculate the size of the resulting layout
    max_width = max(max(len(line) for line in text) for text in texts)
    max_height = max(len(text) for text in texts)
    
    # Create an empty layout
    layout = [[' ' for _ in range(max_width)] for _ in range(max_height)]
    
    # Overlap the texts onto the layout
    for text in texts:
        for i, line in enumerate(text):
            for j, c in enumerate(line):
                if c != ' ':  # Only overwrite non-space characters
                    layout[i][j] = c  # Place the new character

    return '\n'.join(''.join(line) for line in layout)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="This script overlaps text files.")
    parser.add_argument('-p', action='store_true', help='Do not print the overlapped text')
    parser.add_argument('files', nargs='+', help='The text files to overlap')
    
    # Check if no arguments were provided
    if len(sys.argv) == 1:
        parser.print_help(sys.stderr)
        sys.exit(1)
    
    args = parser.parse_args()

    overlapped_text = overlap_files(args.files)

    if args.p:
        with open('./result/overlapped_text.txt', 'w') as f:
            f.write(overlapped_text)
    else:
        print(overlapped_text)
