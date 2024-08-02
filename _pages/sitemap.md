---
layout: archive
title: "Sitemap"
permalink: /sitemap/
author_profile: true
locale: en
---

{% include base_path %}

A list of all the posts and pages found on the site.

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