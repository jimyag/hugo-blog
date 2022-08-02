git push
hugo -D
mv ~/.qshell.json ~/.qshell.json.back
qshell user cu jimyag_online
qshell qupload upload.conf
qshell cdnrefresh -i refreshFile.txt
