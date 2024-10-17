---
title: 'ChatHouseDiffusion: Prompt-Guided Generation and Editing of Floor Plans'
collection: publications
permalink: /zh/publication/2024-10-17-ChatHouseDiffusion
excerpt: '开发了一种新方法，利用大语言模型、Graphormer和扩散模型来交互式生成和编辑房间平面布局图。'
date: 2024-10-17
venue: 'arXiv'
paperurl: 'https://doi.org/10.48550/arXiv.2410.11908'
citation: 'QIN S Z, HE C Y, CHEN Q Y, et al. ChatHouseDiffusion: Prompt-Guided Generation and Editing of Floor Plans[A/OL]. arXiv, 2024[2024-10-17]. http://arxiv.org/abs/2410.11908. DOI:10.48550/arXiv.2410.11908.'
locale: zh
header:
    teaser: "2024-10-17-ChatHouseDiffusion.png"
tags: 
    - firstauthor
    - english
---

生成和编辑房间平面布局图在建筑设计中至关重要，需要高度的灵活性和效率。现有方法需要大量的输入信息，且缺乏对用户修改的交互适应能力。本文介绍了ChatHouseDiffusion，该方法利用大语言模型（LLMs）来解释自然语言输入，采用Graphormer对拓扑关系进行编码，并使用扩散模型灵活地生成和编辑平面图。此方法允许用户根据自己的想法进行迭代设计调整，大大提高了设计效率。与现有模型相比，ChatHouseDiffusion获得了更高的交并比（IoU）得分，能够进行精确的局部调整而无需完全重新设计，因此具有更高的实用性。实验表明，我们的模型不仅严格遵循用户的要求，还通过其交互能力实现了更简洁的设计过程。