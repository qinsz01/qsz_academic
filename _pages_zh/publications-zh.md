---
layout: archive
title: "论文"
permalink: /zh/publications/
author_profile: true
locale: zh
---

{% if site.author.googlescholar %}
  <div class="wordwrap">你也可以直接进入我的<a href="{{site.author.googlescholar}}">Google学术主页</a>.</div>
{% endif %}

{% include base_path %}

{% for post in site.publications reversed %}
  {% include archive-single.html %}
{% endfor %}
