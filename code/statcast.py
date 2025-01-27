import os
from pybaseball import cache, statcast

cache.enable()
data = statcast("2024-03-20", "2024-09-30")

save_path = os.path.join("..", "raw-data", "statcast2024.csv")
data.to_csv(save_path, index=False)
