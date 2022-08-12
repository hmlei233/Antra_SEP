import json
import math

# split 9995 movies into 8 json files
# first 7 files each contain 1250 movies
# last file contains 1245 movies
with open('movie.json', 'r', encoding='utf8') as f:
    data = json.load(f)
    total_size = len(data['movie']) # total size: 9995
    size_of_the_split = math.ceil(total_size / 8) # size of the split: 1250 
    for i in range(8):
        data2 = data.copy()
        start = size_of_the_split * i
        end = min(size_of_the_split * i + size_of_the_split, total_size)
        data2['movie'] = data['movie'][start:end]
        json_object = json.dumps(data2, indent = 4) 
        
        with open("movie_" + str(i + 1) + ".json", "w") as outfile:
            json.dump(data2, outfile) 