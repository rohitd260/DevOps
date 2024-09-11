files1 = open("/home/rohitd/subfolder/file.txt",'r')
content = files1.readlines()
print(content)

files1 = open("/home/rohitd/subfolder/file.txt",'w')
content = files1.write("Old content is replaced because of the write option.\nBut this new content aslo get written in file")
more_content = files1.writelines(["New content","old is replaced by this writelines","this is what it has become"])