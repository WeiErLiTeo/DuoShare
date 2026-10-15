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


OVERDRIVE 特效扩展
=================
本次为原 README 做加法：保留现有段落、统计卡片、贡献蛇、既有樱花/烟花/彩虹特效及已有素材引用，并新增 effects/ 与 image/pixel-sprites/。
把压缩包内 README.md、effects/、image/pixel-sprites/ 合并复制到 DuoShare 仓库根目录，选择覆盖 README.md。不要只上传 README.md，否则新增的本地 GIF 会显示为裂图。
新增像素小人均为本地原创透明背景 GIF；没有嵌入 Live2D，不需要网页 JS，也不需要运行 Python 脚本来播放这些动画。
GitHub README 只会显示 GIF/SVG 等静态文件动画，不会执行 README 中的 JavaScript 或任意 CSS 特效；本包用预渲染 GIF 达到闪屏式视觉效果。


【超标特效增量包】
此次只增加内容，不删除旧 README 模块、原有动漫角色 GIF、统计卡片、访问计数器或贡献蛇。新增 image/ 素材包含 5 个原创透明像素二次元小人、3 个像素宠物，以及星雨、像素彩纸、霓虹波浪、电路流、彗星拖尾、故障扫描线、魔法符文、脉冲光圈、星爆、极光等 10 个原创循环 GIF。将 README.md 与 image/ 合并到仓库根目录即可显示；这些动效都是本地 GIF，不需要你额外运行 Python。


【像素 NPC 加量 / 特效超载】
这次的 README 只加不减：原有动漫放映厅、统计卡片、访问计数、贡献蛇蛇、原来的像素精灵和已有特效都保留。新增 5 个原创透明像素二次元小人、3 个透明像素宠物和 10 种本地循环特效；此外原包已有的 `effects/` 特效组也保留。把 `README.md`、`image/`、`effects/`、`.github/` 和 `scripts/` 合并到仓库根目录，不要只上传 README。新加入的 GIF 直接显示，无须运行 Python 或 JavaScript。
