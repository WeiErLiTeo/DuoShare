DuoShare 超标级二次元 README 安装说明

1. 解压 ZIP。
2. 将解压目录中的 README.md、image/、scripts/、GIF_SOURCES.md 和 .github/ 合并到 WeiErLiTeo/DuoShare 仓库根目录。
3. 确认 GitHub 仓库 Settings > Actions > General > Workflow permissions 允许工作流写入仓库内容（Read and write permissions）。
4. 在 Actions 页面手动运行：
   - Generate colorful contribution snake
   - Mirror anime GIFs into this repository
5. 蛇形动画首次生成后，README 的 output/github-snake.gif 才会出现。
6. GIF 镜像工作流只会固化实际下载成功的图片；如果 Tenor 链接失效或限制请求，README 会保留原始链接，不会凭空生成角色图。

特效说明：
- image/sakura-fall.gif：本地循环樱花飘落与闪光。
- image/fireworks.gif：本地循环烟花粒子。
- image/rainbow-divider.gif：本地彩虹粒子分隔线。
- image/pixel-magic.gif：本地像素魔法动画。

重要限制：GitHub README 会播放 GIF；不会执行 <script>、普通网页 JavaScript 或 CSS 页面动画。因此樱花、烟花和粒子被预先渲染为 GIF。统计卡片、打字 SVG 和计数器来自外部服务，服务维护状态与可用性可能变化。
