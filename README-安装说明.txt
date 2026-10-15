DuoShare 二次元 GIF README 配置包

1. 解压 ZIP。
2. 将其中的 README.md、.github/、scripts/、GIF_SOURCES.md 合并到 https://github.com/WeiErLiTeo/DuoShare 仓库根目录。
3. 提交并推送后，README 会立即尝试显示在线 GIF。GitHub Actions 若启用，会尝试将 GIF 下载到 image/ 并将成功的图片引用改为仓库本地路径。
4. 如果镜像工作流未自动执行，打开 GitHub 仓库的 Actions → Mirror anime GIFs into this repository → Run workflow。
5. 首次运行前，请在 Settings → Actions → General 的 Workflow permissions 中确认允许工作流写入仓库内容（Read and write permissions）。
6. 蛇形贡献动画由另一个工作流生成，成功后会写入 output 分支。

已填入用户名：WeiErLiTeo
仓库名按截图设为：DuoShare
说明：README 保留 npm start 示例；请按实际 package.json 脚本调整。
