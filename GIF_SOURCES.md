# DuoShare GIF 素材来源

README 使用下列原始 GIF，并让每张角色图链接回来源页面。请仅在符合来源平台条款与个人用途要求的情况下使用。

| 角色 / 素材 | 原始页面 |
|---|---|
| 薇尔莉特·伊芙加登 | https://tenor.com/view/violet-evergarden-gif-11403745 |
| 芙莉莲 | https://tenor.com/view/frieren-anime-frieren-beyond-the-journeys-end-beyond-the-journeys-end-sousou-no-frieren-gif-556694785732715598 |
| 菲伦 | https://tenor.com/view/fern-fern-frieren-fern-bread-eat-bread-eat-gif-6093318340447145323 |
| 蕾姆 | https://tenor.com/view/rem-gif-16729404297096831375 |
| 拉姆 | https://tenor.com/view/ram-rezero-ram-re-zero-rezero-ram-re-zero-ram-ram-choke-rezero-gif-11991381440316556254 |
| 蕾姆与拉姆 | https://tenor.com/view/rem-ram-gif-21695942 |
| 后藤一里 / 波奇酱 | https://tenor.com/view/bocchi-the-rock-gif-27391715 |
| 初音未来 | https://tenor.com/view/anime-hatsune-miku-dancing-gif-11885930 |
| 喜多川海梦 | https://tenor.com/view/marin-kitagawa-marin-kitagawa-kitagawa-marin-bisque-gif-24606173 |
| 阿尼亚·福杰 | https://tenor.com/view/anya-forger-anya-spy-x-family-anime-forgot-gif-26756419 |
| 藤原千花 | https://tenor.com/view/chika-fujiwara-gif-20063896 |
| 灶门祢豆子 | https://tenor.com/view/nezuko-gif-26048607 |

## 将动图固化到自己的仓库

放入仓库后，GitHub Actions 会尝试运行 `Mirror anime GIFs into this repository`，把能成功获取的 GIF 存到 `image/` 并把 README 的图片引用切换成本地文件。若首次上传后没有自动运行，也可以在 **Actions** 页面手动运行该工作流。

外部平台的链接没有谁能保证永久不变；本地镜像成功后，README 中对应的图片就不再依赖原图床。工作流只会替换已验证下载成功的 GIF，失败的仍保留源链接。
