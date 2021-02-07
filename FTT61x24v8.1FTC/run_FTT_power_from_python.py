import os
import matlab.engine

# os.chdir("/Users/alexanderkell/Documents/PhD/Projects/17-ftt-power-reinforcement/FTT61x24v8.1FTC")
os.chdir("/home/ps/ce-fs2/akell/PhD/ftt-power/reinforcement-learning-investment-ftt-power/FTT61x24v8.1FTC")
eng = matlab.engine.start_matlab()
# eng.Run_FTT_Power(port=9912)
eng.Run_FTT_Power(9912, 400, 400)
