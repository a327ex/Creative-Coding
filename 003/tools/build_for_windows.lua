string.split = function(self) local out = {}; for match in self:gmatch('[^\\]+') do table.insert(out, match) end; return out end
cd = io.popen('cd'):read() -- current directory
cd_t = cd:split() -- current directory as table
project_name = cd_t[#cd_t-1]

os.execute([[call "C:\Program Files\7-Zip\7z.exe" a -r "]] .. project_name .. [[.zip" -w ..\* -xr!bin -xr!exe -xr!steam -xr!.git -xr!.yue]])
os.execute([[rename "]] .. project_name .. [[.zip" "]] .. project_name .. [[.love"]])
os.execute([[copy /b "love.exe"+"]] .. project_name .. [[.love" "]] .. project_name .. [[.exe"]])
os.execute([[del "]] .. project_name .. [[.love"]])
os.execute([[mkdir "]] .. project_name .. [["]])
os.execute([[robocopy *.dll . "]] .. cd .. [[/]] .. project_name .. [[/"]])
os.execute([[robocopy *.txt . "]] .. cd .. [[/]] .. project_name .. [[/"]])
os.execute([[copy "]] .. project_name .. [[.exe" "]] .. project_name .. [[\"]])
os.execute([[del "]] .. project_name .. [[.exe"]])
os.execute([[call "C:\Program Files\7-Zip\7z.exe" a "]] .. project_name .. [[.zip" "]] .. project_name .. [[\"]])
os.execute([[del /q "]] .. project_name .. [[\"]])
os.execute([[rmdir /q "]] .. project_name .. [[\"]])
os.execute([[copy "]] .. project_name .. [[.zip" ..\builds\windows]])
os.execute([[del "]] .. project_name .. [[.zip"]])
