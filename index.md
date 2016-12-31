---
layout: default
title: {{ site.name }}
---

{% for post in site.posts %}
  {% include post_excerpt.html %}
{% endfor %}