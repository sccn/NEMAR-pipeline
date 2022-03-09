import re
import os
import numpy as np

directory = '/expanse/projects/nemar/openneuro/processed/ds002691/sub-001/eeg/eegplot-all'
files = [f for f in os.listdir(directory) if f.strip().endswith('.jpeg')]
print(files)
pattern = re.compile(r'lat-(\d+).jpeg')
nums = [int(re.search(pattern, f).group(1)) for f in files]
sort_indices = np.argsort(np.array(nums))
print(sort_indices)
sorted_files = []
for i in sort_indices:
    sorted_files.append(files[i])
print(sorted_files)
print('<div class="MagicScroll">')
i = 0
for f in sorted_files:
    print(f'<a href="#"><img src="eegplots/{f}" width="1000" height="1200"></a>')
    i = i + 1
print('</div>')
