git add .
git commit -m "%1"
git push
hugo -D
scp -r public/* root@101.35.228.140:/public/jimyag.cn/