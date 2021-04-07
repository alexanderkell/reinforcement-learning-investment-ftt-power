#!/bin/bash

exec python3.7 FTTPowerServer2.py &
exec matlab -nodisplay -nosplash -nodesktop -r "run('/app/Run_FTT_Power(9912,500,500)');exit;"