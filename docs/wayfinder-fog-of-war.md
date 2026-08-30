---
title: "雾中寻路：AI 怎么对付写不出 PRD 的大任务"
source: "知乎"
url: "https://zhuanlan.zhihu.com/p/2057862407343625873"
source_url: "https://zhuanlan.zhihu.com/p/2057862407343625873"
author: "葡萄边 前端开发"
created: ""
updated: ""
fetched_at: "2026-07-08T13:02:22.650135+00:00"
---

# 雾中寻路：AI 怎么对付写不出 PRD 的大任务
![雾中寻路：AI 怎么对付写不出 PRD 的大任务](https://picx.zhimg.com/70/v2-71c50c946eadca3fe901215421e68693_1440w.image?source=172ae18b&biz_tag=Post)

# 雾中寻路：AI 怎么对付写不出 PRD 的大任务

[![葡萄边](https://picx.zhimg.com/v2-0c9f0f021e9a54975939299de94c79e6_l.jpg?source=32738c0c&needBackground=1)](//www.zhihu.com/people/grapes-56)

[葡萄边](//www.zhihu.com/people/grapes-56)

前端开发

[收录于 · Grapes的AI Agent学习笔记](https://www.zhihu.com/column/c_2056181870610665923)

8 人赞同了该文章

你让 AI 帮你做个功能。

描述写得挺清楚，AI 也干劲十足，哗啦啦写了一大堆代码。跑起来一看——不是你要的。

换个方式再来。这次 AI 谨慎多了，每一步都问你。但问着问着，你发现自己也答不上来：用什么方案？做到哪步算完？这些选择取决于一些你还没验证过的假设。

你硬着头皮给了个方向，AI 跑完，发现方向是错的。退回来重做，又撞上新的未知。几个来回，AI 的上下文塞满了前后矛盾的尝试，开始重复劳动、忘记之前的决定、产出一堆语法对但架构全错的代码。

这些痛苦的共同点，不是“需求没写清楚”，也不是“AI 不够聪明”。

而是：**有些任务，你在动手之前就是想不清楚。**

用什么方案，取决于还没研究过的技术；做到什么程度，取决于没验证过的假设；甚至“到底要不要做这件事”，都取决于几个你现在还回答不了的问题。这些信息不存在于你的脑子里，也不存在于 AI 的训练数据里——它们得在你动手试探之后，才会浮现。

Matt Pocock——TypeScript 圈大神，开了个 [GitHub](https://zhida.zhihu.com/search?content_id=278506782&content_type=Article&match_order=1&q=GitHub&zhida_source=entity) 仓库 [mattpocock/skills](https://link.zhihu.com/?target=https%3A//github.com/mattpocock/skills)，把他日常 AI 编程用到的技能放出来，直接冲到 150k star——给这种情况起了个名字：**终点在雾里。** 隐约知道大概方向，但看不清路，更看不清终点。

他刚发布的 [wayfinder](https://zhida.zhihu.com/search?content_id=278506782&content_type=Article&match_order=1&q=wayfinder&zhida_source=entity) 技能，就是专门为这种任务做的。

### 想不清楚的需求

先把两种难任务分开。

一种是“大但明确”。你想做登录系统，细节很多，但终点是清楚的：用户能注册、登录、登出，密码错了有提示。这种任务哪怕代码量大，也写得出来 PRD。给它足够上下文，AI 能按部就班拆成模块，逐块实现。

另一种是“大且看不清”。你脑海里只有一个模糊的方向，比如“让我们的 CLI 工具支持插件生态”，或者“把这套内部数据流重构成可扩展的架构”。具体要支持哪些插件？扩展点在哪？现有代码能不能撑住？这些答案不在你脑子里，得先去翻源码、去试原型、去问人。

![](https://pic1.zhimg.com/v2-0b691736e50531e68101e94fdb256b8c_r.jpg)

两种任务的区别

Matt Pocock 在推特上把"大且看不清"拆成两个概念：Frontier（前沿）和 [Fog of war](https://zhida.zhihu.com/search?content_id=278506782&content_type=Article&match_order=1&q=Fog+of+war&zhida_source=entity)（战争迷雾）。前沿是已知的边界——你能做的决定，手里有的信息；迷雾是边界之外——你还看不清的部分。规则只有一条：只在前沿做决定，别在迷雾里做计划。

> Two new leading words for planning work with AI: Frontier, Fog of war. "Don't plan past the fog of war. Let's resolve just the decisions at the frontier first."
>
> 用 AI 规划工作时，有两个关键概念：Frontier（前沿）和 Fog of war（战争迷雾）。不要规划迷雾之外的部分，先解决前沿的决策。

我以前做重构，最喜欢先写一份"完整"的改造方案，越详细越好。结果常常写到一半发现：某个依赖的行为和文档不一致；某个看起来简单的改动会波及三个业务线；自以为能复用的抽象其实只覆盖了一半场景。方案越详细，推翻的时候越狼狈。而 O'Reilly 那篇文章说的更直接：

> 你往往是在往对话里塞了最多信息的时候，触发了上下文限制——这时丢失的信息，代价最大。

所以问题不是任务大，而是信息压根不存在。你没法在聊天框里一次性把它说清楚，因为连你自己都还不知道你需要什么。那些信息，要等你动手试探之后才会浮现。

### 一张会生长的地图

wayfinder 的解决办法，是别把整段探索塞进一个对话。它把任务变成 [issue tracker](https://zhida.zhihu.com/search?content_id=278506782&content_type=Article&match_order=1&q=issue+tracker&zhida_source=entity) 上的一张“地图”，每个未知拆成一个 ticket，一次只解决一个。

> Issue tracker 是像 [Linear](https://link.zhihu.com/?target=https%3A//linear.app/) 或 GitHub Issues 这样的产品。你可以把 issue/ticket 理解成中文项目管理工具里的“工作项”（需求、缺陷、任务等）。后文会交替使用 issue/ticket 英文术语和“工作项”来辅助理解。

Matt Pocock 给 wayfinder 的定位是：

> Plan a huge chunk of work — more than one agent session can hold — as a shared map of investigation tickets on your issue tracker, and resolve them one at a time until the way to the destination is clear.
>
> 如果工作大到一次会话塞不下，在 issue tracker 上创建一个探索型 issue，这个 issue 的内容是一张地图，里面贴着所有待探索的 ticket，一个一个解决，直到通往目的地的路清晰起来。

关键词是地图和探索型 issue。地图不是任务清单，而是索引；ticket 不是待办项，而是待解的问题。

wayfinder 的用法大概是：

1. 先创建一个 issue，标题写上目的地，比如“重构数据流以支持插件化扩展”。这个 issue 打上 `wayfinder:map` 标签，就是地图本身。
2. 然后和 wayfinder 一起“画地图”：把已知的未知拆成几个 ticket，每个 ticket 是一种具体动作，也打上对应的标签。

![](https://pic2.zhimg.com/v2-8ee07c1ce574f67205f3463b763a0bdf_r.jpg)

course-video-manager 的实际例子

![](https://picx.zhimg.com/v2-93d703902744e36991a21f80ed7e9273_r.jpg)

Wayfinder 怎么工作

这四种 ticket 分别是：

- **Research**：去读外部文档、源码、API，产出一份摘要。这种 ticket 可以 AFK（Away From Keyboard，挂机），让 AI 自己跑。
- **Prototype**：做一个粗糙原型，把模糊想法变成能讨论的东西。需要 HITL（Human In The Loop），你得过来看一眼、给反馈。
- **Grilling**：这其实就是著名的 grill-me 技能。跟 AI 一问一答，把一个模糊的问题问清楚。这是最常用的类型，默认 HITL。
- **Task**：纯体力活，比如批量重命名、跑测试、整理数据。HITL 或 AFK 都可以。
  这四种 ticket，每个都是这个探索型地图的 child issue（子工作项）。

![](https://pic2.zhimg.com/v2-3bb9931c297b342566cd8235df33d141_r.jpg)

四种探索 Ticket

地图 issue 大概长这样：

![](https://pic1.zhimg.com/v2-ef4f911f71f218c1ab64d74de2c0d062_r.jpg)

地图长什么样

注意那个 **Not yet specified** 区。它很关键：不是“还没分配的任务”，而是“我还不知道怎么描述的问题”。这就是刻意保留的战争迷雾。判断标准很简单：你现在的这个问题，能不能用一句话精确地问出来？如果不能，它就在雾里，不要硬拆成 ticket。
Pocock 的推特把这件事说得特别形象：

> I'm planning an entire course with it every minute of the last four days. Closing in on 100 separate grilling/prototyping/research sessions. All contributing back to a central map that: Grows as I learn more about the problem, Shrinks as I find answers to questions.
> 过去四天，我几乎每一分钟都在用它规划一门完整课程。已经接近 100 个独立的 grilling / prototyping / research session，全部汇总到一张中央地图里：问题越挖越多，答案越找越清晰。

地图会生长，也会收缩。你每找到一个答案，迷雾就退一点；每发现一个新未知，地图就长出新的边界。它不是一次画完的执行计划，而是一张随探索更新的认知地图。
它还有一条原则：一次只解一个 ticket。意思很简单——每个 session 只解决掉一个 wayfinder ticket。听起来很慢，其实是在保护 AI 的 context。一个 ticket 解完，决策和结果写进地图，下一个 ticket 从新的稳定起点开始。这样就不会出现一个 session 里前后矛盾、最后全烂掉的情况。

### 探索和执行的分界线

wayfinder 不是孤立存在的。它补的是 mattpocock 技能体系里长期缺的一块：探索。
整个技能体系可以分成两层。一层是“找路”，一层是“走路”。

**找路层：wayfinder**
任务终点不清楚，先用 wayfinder 拆 ticket、探索、更新地图。你不需要知道最终方案是什么，只需要知道“下一步该问什么问题”。

**走路层：to-spec + to-tickets**
等到路看清了——你知道要做什么、做成什么样——就该换技能。to-spec 把对话沉淀成一份 spec，to-tickets 把 spec 拆成可执行的 ticket。
spec 是跨多个 session 的计划，ticket 是单个 session 里的计划。spec 描述整体路径；ticket 描述单个 session 里要解决的具体任务。

![](https://pic3.zhimg.com/v2-69826c5373f54c9601229099c23d6f58_r.jpg)

找路层 vs 走路层

所以一个完整的工作流可能是这样：

1. 有个大任务，但终点不清楚。
2. 用 wayfinder 画地图，拆 Research / Prototype / Grilling ticket。
3. 一张张解，记录决策，迷雾退去。
4. 终点清晰了，切到 to-spec 写一份规格文档。
5. 用 to-tickets 把规格文档拆成 tickets.md 或真实 issue。
6. 逐个实现、review、合并。

![](https://pic2.zhimg.com/v2-901d0fcd73112fd267e7f35d57925ad7_r.jpg)

完整工作流

当然，如果一开局的 grilling 会话就很清晰，那根本不需要 wayfinder。终点明确就别绕路，直接 to-spec。wayfinder 不是银弹，它是雾天开雾灯。晴天还开雾灯，反而碍事。

### wayfinder 实质在做软件工程

写到这里，我想坦诚地说一句：wayfinder 不是 Matt Pocock 凭空想出来的概念。它背后有几条很扎实的工程思想渊源。

第一条渊源来自《程序员修炼之道：从小工到专家》里的 Tracer Bullets。军事上，每隔几发普通子弹混一发发光弹，用来观察弹道。软件开发中，它指端到端的薄片实现：先打通一条最小可行路径，获得反馈，再扩展。wayfinder 的 Prototype ticket 和 to-tickets 的 tracer-bullet 切片都直接继承了这个思路——反对“跑在前灯前面”，即计划速度超过反馈速度。

这个坑我踩过。有次做一个新功能的接入层，我先把配置模块、缓存模块、错误处理模块都写得漂漂亮亮，觉得每个局部都经得起 review。结果最后联调时发现：第一个端到端请求根本走不通，因为中间有一层数据格式没有对齐。局部都对，但链路死了。如果我当时先用 Tracer Bullet 打一个能从请求入口到响应出口的薄片，哪怕丑一点，也能在第一天就知道格式不对，而不是在最后一天才返工。

![](https://pic3.zhimg.com/v2-5fe139b840d36894e3028a867915a0d4_r.jpg)

Tracer Bullets 是什么

这种“先打通再打磨”的思路，在 wayfinder 里对应 Prototype ticket：不追求完美，先让未知变具体。

一条来自《领域驱动设计：软件核心复杂性应对之道》的 Ubiquitous Language（通用语言）。Grilling ticket 的核心价值，就是把“我觉得这里应该这样”变成“我们共同认可的词汇和规则”。

这个痛点我特别熟悉。我们项目里曾有两个完全不同的东西，但团队都叫“HTML 应用”。名称一样，指向不同，讨论时经常各说各话。AI 来探索分析时更惨：它看到“HTML 应用”这个词，根本没法判断当前语境是哪一个，推断自然出错。

通用语言的作用，就是把这些词一个一个钉死。Grilling ticket 很适合做这件事：跟 AI 反复确认，“你说的运行时是不是指渲染器执行阶段？”“发布态和预览态的区别是不是在于是否读取已保存的 schema？”直到形成一份通用语言文档。AI 后续读这份通用语言文档，大家交流也统一使用通用语言，当然也就不用猜了。

![](https://pic4.zhimg.com/v2-4676cc25a79943c0bd75347180374bef_r.jpg)

通用语言文档长什么样

一条来自《软件设计的哲学》的 Deep Module 概念。wayfinder 把一张大地图拆成很多小 ticket，但每个 ticket 本身有明确边界和产出。地图 issue 是浅接口（标题、几个区、依赖关系），内部却封装了几十上百个 session 的探索。

![](https://pic4.zhimg.com/v2-c038b90acab864f9d3b21aa486da3cb3_r.jpg)

什么是 Deep Module

这也说明，在 AI 时代，软件工程的很多思想变得更有用了，wayfinder 的每个设计选择都有软件工程根基。

### Matt Pocock 自己怎么用它

这些理论底色，在 Matt Pocock 自己的实践里看得最清楚。

> My new skill /wayfinder is letting me do stuff I've never considered trying. I'm planning an entire course with it every minute of the last four days. Closing in on 100 separate grilling/prototyping/research sessions. All contributing back to a central map that: Grows as I learn more about the problem, Shrinks as I find answers to questions. **It's the next evolution of /grill-me.** 我的新技能 /wayfinder 让我敢尝试以前从没想过的事。过去四天，我几乎每一分钟都在用它规划一门完整课程。已经接近 100 个独立的 grilling / prototyping / research session，全部汇总到一张中央地图里：我对问题了解越多，它就越生长；我找到的答案越多，它就越收缩。**这是 /grill-me 的下一阶段。**

一门课程的规划，不是“列出 20 节课的标题”就能做的。你得先想清楚：受众是谁、前置知识是什么、哪些概念必须放在一起、哪些案例能真正讲清楚、哪些内容看起来重要其实可以砍掉。这些问题的答案，你在第一版大纲里不可能全知道。

他用 wayfinder 的方式，不是一次把课程规划完，而是每次只解决一个“未知”：研究一个概念、做一个原型讲义、grilling 一轮确认边界。解完的 ticket 关闭归档，结论写回地图，新的 frontier 浮现出来。四天近 100 个 session，地图一直在长，也一直在缩。

这和我之前写大功能时的痛苦形成鲜明对比。我过去常常是：打开一个 session，让 AI 给我一份“完整”方案，然后试图照着执行。方案看起来专业，但执行到一半就碎。因为那份方案是在“迷雾”里画的，而迷雾中的路，根本还没被探出来。

在 Matt Pocock 的课程视频管理软件中，我们也可以看到他的使用方法：[#1181: Wayfinder map: Title-driven paths — derive Lesson & Section local paths from their titles](https://link.zhihu.com/?target=https%3A//github.com/mattpocock/course-video-manager/issues/1181)。

![](https://pic3.zhimg.com/v2-e244a5fae38c90b2c0382fed3c4e5d24_r.jpg)

真实项目里长什么样

wayfinder 不是让 AI 更聪明，而是让“探索”这件事变得可管理。它承认有些事你就是一开始想不清楚，然后给你一套方法：把未知切成小 ticket，一次解一个，每片都有记录，记录汇聚成地图，地图最终拨开迷雾，找到通往终点的道路。

说了这么多，不妨找个现在还看不清的任务试试：

```
npx skills@latest add mattpocock/skills
```

### 结尾：在雾中找路

写到这里，我想起自己曾在另一篇博客的评论区看过一个真实故事。那位开发者说，他曾经偷懒让 AI 直接重构一个巨大的后端文件，结果 AI 把逻辑改得面目全非，还删掉了 40% 的逻辑。当时他正在 vibe coding，连 Git 都还没设置好，最后花了 9 个小时手动重建自己都没完全理解的东西。

这种事的根源不是 AI 不会重构，而是他让 AI 在一个“看不清”的任务上直接执行。他不知道那 40% 的逻辑为什么存在，AI 也不知道。双方都在雾里开车，撞墙是迟早的事。

wayfinder 给这类任务提供了一个出口：不要硬写 PRD，不要硬拆执行计划，先承认终点在雾里，然后一张 ticket 一张 ticket 地探路。

它最后把“路”交给 to-spec 和 to-tickets，让你回到熟悉的执行轨道。但它真正的价值，是填补了 mattpocock 技能体系里最关键的空缺：从“我知道我要什么”到“我终于知道我要什么”之间的那段路。

雾不会散，但你可以学会在雾中寻路。

[所属专栏 · 昨天 17:01 更新](https://zhuanlan.zhihu.com/c_2056181870610665923)

[![](https://pica.zhimg.com/v2-c2675d4a550f002c2838883bda6ec5bc_720w.jpg?source=172ae18b)

Grapes的AI Agent学习笔记

![](https://pic1.zhimg.com/v2-0c9f0f021e9a54975939299de94c79e6_l.jpg?source=172ae18b)

葡萄边

2 篇内容 · 12 赞同](https://zhuanlan.zhihu.com/c_2056181870610665923)

[最热内容 ·

没有魔法，只有循环：从 LLM API 到第一个 Agent](https://zhuanlan.zhihu.com/c_2056181870610665923)

编辑于 2026-07-07 17:58・浙江

[Agent-skill](//www.zhihu.com/topic/2032132972548184041)

[AI-Agent](//www.zhihu.com/topic/30639237)

[软件工程](//www.zhihu.com/topic/19557552)

![](https://picx.zhimg.com/v2-abed1a8c04700ba7d72b45195223e0ff_l.jpg?source=32738c0c&needBackground=1)

理性发言，友善互动

3 条评论

默认

最新

[![KouPou](https://picx.zhimg.com/v2-3e483098353a74079ce4cd5389ee621f_l.jpg?source=06d4cd63)](https://www.zhihu.com/people/900b8f5d1039c483a56cad98b8355d2c)

[KouPou](https://www.zhihu.com/people/900b8f5d1039c483a56cad98b8355d2c)

让apaas那群人来拜读下吧

8 小时前 · 北京

[![王小木工](https://picx.zhimg.com/v2-3a107e46f8398e05b80ef9a734c9c088_l.jpg?source=06d4cd63)](https://www.zhihu.com/people/b1525b38cfaf596dcaa050bd9ecef93c)

[王小木工](https://www.zhihu.com/people/b1525b38cfaf596dcaa050bd9ecef93c)

催更～

8 小时前 · 浙江

[![碧海青天](https://picx.zhimg.com/v2-2a7ca5fe4b145d9f3d8315f15a9e7815_l.jpg?source=06d4cd63)](https://www.zhihu.com/people/65c5b2515fe3c2fe98cec6572babfee4)

[碧海青天](https://www.zhihu.com/people/65c5b2515fe3c2fe98cec6572babfee4)

读完收获极大。现在市面上讲 AI coding 的文章大多停留在‘怎么写 prompt’的术语层面，能像你这样把 AI 协作的痛点，拉回到《程序员修炼之道》的 Tracer Bullets 和 DDD 的通用语言（Ubiquitous Language）里去拆解的，真的极少见到。
“不要在迷雾里做计划，只在前沿做决定”，这个对 Frontier 和 Fog of war 的界定太透彻了。这其实不仅是 AI 编程的技巧，更是极其高级的工程哲学。好文章，已经转发给组里其他小伙伴了！

8 小时前 · 浙江

关于作者

[![葡萄边](https://picx.zhimg.com/v2-0c9f0f021e9a54975939299de94c79e6_l.jpg?source=32738c0c&needBackground=1)](//www.zhihu.com/people/grapes-56)

[葡萄边](//www.zhihu.com/people/grapes-56)

前端开发

[回答

**16**](//www.zhihu.com/people/grapes-56/answers)[文章

**15**](//www.zhihu.com/people/grapes-56/posts)[关注者

**217**](//www.zhihu.com/people/grapes-56/followers)

大家都在搜

换一换

[广西南宁一水库坝体出现缺口325 万](https://www.zhihu.com/search?q=%E5%B9%BF%E8%A5%BF%E5%8D%97%E5%AE%81%E4%B8%80%E6%B0%B4%E5%BA%93%E5%9D%9D%E4%BD%93%E5%87%BA%E7%8E%B0%E7%BC%BA%E5%8F%A3&search_source=Trending&utm_content=search_hot&utm_medium=organic&utm_source=zhihu&type=content)热

[中公教育因股民荒诞赌约涨停310 万](https://www.zhihu.com/search?q=%E4%B8%AD%E5%85%AC%E6%95%99%E8%82%B2%E5%9B%A0%E8%82%A1%E6%B0%91%E8%8D%92%E8%AF%9E%E8%B5%8C%E7%BA%A6%E6%B6%A8%E5%81%9C&search_source=Trending&utm_content=search_hot&utm_medium=organic&utm_source=zhihu&type=content)热

[阿根廷逆转绝杀埃及301 万](https://www.zhihu.com/search?q=%E9%98%BF%E6%A0%B9%E5%BB%B7%E9%80%86%E8%BD%AC%E7%BB%9D%E6%9D%80%E5%9F%83%E5%8F%8A&search_source=Trending&utm_content=search_hot&utm_medium=organic&utm_source=zhihu&type=content)热

[动物园灾前将猛兽锁死致多只溺亡297 万](https://www.zhihu.com/search?q=%E5%8A%A8%E7%89%A9%E5%9B%AD%E7%81%BE%E5%89%8D%E5%B0%86%E7%8C%9B%E5%85%BD%E9%94%81%E6%AD%BB%E8%87%B4%E5%A4%9A%E5%8F%AA%E6%BA%BA%E4%BA%A1&search_source=Trending&utm_content=search_hot&utm_medium=organic&utm_source=zhihu&type=content)热

[台风巴威登陆地基本锁定闽浙295 万](https://www.zhihu.com/search?q=%E5%8F%B0%E9%A3%8E%E5%B7%B4%E5%A8%81%E7%99%BB%E9%99%86%E5%9C%B0%E5%9F%BA%E6%9C%AC%E9%94%81%E5%AE%9A%E9%97%BD%E6%B5%99&search_source=Trending&utm_content=search_hot&utm_medium=organic&utm_source=zhihu&type=content)新

[广西横州一名被蛇咬伤女子离世293 万](https://www.zhihu.com/search?q=%E5%B9%BF%E8%A5%BF%E6%A8%AA%E5%B7%9E%E4%B8%80%E5%90%8D%E8%A2%AB%E8%9B%87%E5%92%AC%E4%BC%A4%E5%A5%B3%E5%AD%90%E7%A6%BB%E4%B8%96&search_source=Trending&utm_content=search_hot&utm_medium=organic&utm_source=zhihu&type=content)热

[司晓迪疑曝与鹿晗暧昧照292 万](https://www.zhihu.com/search?q=%E5%8F%B8%E6%99%93%E8%BF%AA%E7%96%91%E6%9B%9D%E4%B8%8E%E9%B9%BF%E6%99%97%E6%9A%A7%E6%98%A7%E7%85%A7&search_source=Trending&utm_content=search_hot&utm_medium=organic&utm_source=zhihu&type=content)热

[多益网络徐波称女儿被诱拐走291 万](https://www.zhihu.com/search?q=%E5%A4%9A%E7%9B%8A%E7%BD%91%E7%BB%9C%E5%BE%90%E6%B3%A2%E7%A7%B0%E5%A5%B3%E5%84%BF%E8%A2%AB%E8%AF%B1%E6%8B%90%E8%B5%B0&search_source=Trending&utm_content=search_hot&utm_medium=organic&utm_source=zhihu&type=content)热

[湖北黄冈鄂州出现龙卷风291 万](https://www.zhihu.com/search?q=%E6%B9%96%E5%8C%97%E9%BB%84%E5%86%88%E9%84%82%E5%B7%9E%E5%87%BA%E7%8E%B0%E9%BE%99%E5%8D%B7%E9%A3%8E&search_source=Trending&utm_content=search_hot&utm_medium=organic&utm_source=zhihu&type=content)

[埃及球员怒喷裁判不公285 万](https://www.zhihu.com/search?q=%E5%9F%83%E5%8F%8A%E7%90%83%E5%91%98%E6%80%92%E5%96%B7%E8%A3%81%E5%88%A4%E4%B8%8D%E5%85%AC&search_source=Trending&utm_content=search_hot&utm_medium=organic&utm_source=zhihu&type=content)新

### 推荐阅读

[# Graceful AI - 如何让AI模型无缝更新

CVPR即将召开之际，亚马逊science网站发表一篇专栏，总结了过去俩年我们在AI部署模型一致性和兼容性这个全新方向的三篇论文，分别从特征兼容性-Backward Representation Learning，分类器预…

夏威Wei...发表于AI浅谈](https://zhuanlan.zhihu.com/p/372254570)[# 如何衡量AI到底创造了多少价值？meta公司做了个排行榜

Betterworks今年做了一项调查，问了两拨人同一个问题：AI有没有改变你们公司的绩效评估方式？88%的HR说改了，只有8%的员工说清楚公司到底打算怎么改。 同一栋楼里的两个群体，看到的完全是…

梯度更新专家](https://zhuanlan.zhihu.com/p/2028786033097994254)[![生成式 AI 应用落地小结：高估的模型能力，低估的工程实施](https://pic1.zhimg.com/v2-ae948dee243e3ce62947d9f6fbd6d825_250x0.jpg?source=172ae18b)

# 生成式 AI 应用落地小结：高估的模型能力，低估的工程实施

phoda...发表于Phoda...](https://zhuanlan.zhihu.com/p/670598821)[![以 AI Coding 之管窥探世界之变](https://pica.zhimg.com/v2-48e79c2ffa7c65ca5e9aef3dfcfe1d2d_250x0.jpg?source=172ae18b)

# 以 AI Coding 之管窥探世界之变

长琴](https://zhuanlan.zhihu.com/p/1990014688579297285)
