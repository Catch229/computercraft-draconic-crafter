url = "https://raw.githubusercontent.com/Catch229/computercraft-draconic-crafter/refs/heads/main/fusion.lua"
programName = "CC Auto Fusion Crafter"
fileLoc = "fusion.lua"

term.clear()
term.setCursorPos(1,1)

print("          ___  ___          _    _ _____  ")
print("         |__ \\|__ \\    /\\  | |  | |  __ \\ ")
print("            ) |  ) |  /  \\ | |  | | |  | |")
print("           / /  / /  / /\\ \\| |  | | |  | |")
print("          / /_ / /_ / ____ \\ |__| | |__| |")
print("         |____|____/_/    \\_\\____/|_____/ \n")
print("              *The 22 Auto Updater*       \n")
print("               "..programName.."\n")

if fs.exists(fileLoc) then
	file = fs.open(fileLoc, "r")
	contents = file.readAll()
	file.close()
	git = http.get(url)
	gitFile = git.readAll()
	git.close()
	if gitFile ~= contents then
		print("       Out of date. Updating and starting...")
		file = fs.open(fileLoc, "w")
		file.write(gitFile)
		file.close()
		sleep(1)
	else
		print("             Up to date! Starting...")
	end
else
	print("            Installing and starting...")
	git = http.get(url)
	gitFile = git.readAll()
	git.close()
	file = fs.open(fileLoc, "w")
	file.write(gitFile)
	file.close()
	sleep(1)
end
shell.run(fileLoc)
