<ul>
  {% for post in site.posts %}
    <li>
      <a href="{{ post.url }}">{{ post.excerpt }}</a>
    </li>
  {% endfor %}
</ul>
