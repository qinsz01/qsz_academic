---
layout: archive
title: "网站导航"
permalink: /zh/sitemap/
author_profile: true
locale: zh
---

{% include base_path %}

本网站展示了页面和文章的列表。

<h2>{{site.data.ui-text[page.locale].page}}</h2>
{% for post in site.pages %}
  {% if post.locale == page.locale %}
    {% include archive-single.html %}
  {% endif %}
{% endfor %}

<h2>{{site.data.ui-text[page.locale].post}}</h2>
{% for post in site.posts %}
  {% if post.locale == page.locale %}
    {% include archive-single.html %}
  {% endif %}
{% endfor %}

{% capture written_label %}'None'{% endcapture %}

{% for collection in site.collections %}
{% unless collection.output == false or collection.label == "posts"%}
  {% capture label %}{{ site.data.ui-text[page.locale][collection.label] }}{% endcapture %}
  {% if label != written_label %}
  <h2>{{ label }}</h2>
  {% capture written_label %}{{ label }}{% endcapture %}
  {% endif %}
{% endunless %}
{% for post in collection.docs %}
  {% unless collection.output == false or collection.label == "posts"%}
  {% include archive-single.html %}
  {% endunless %}
{% endfor %}
{% endfor %}
