<ul>
  {% for post in site.posts %}
    <li>
      <a href="{{ post.url }}">{{ post.title }}</a>
      {{ post.excerpt }}
    </li>
  {% endfor %}
</ul>

<div id="disqus_thread"></div>

<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.0/jquery.min.js"></script>
<script src="http://code.jquery.com/jquery-1.10.1.min.js"></script>

<script src="../../comments/inlineDisqussions.js"></script>
<script src="../../js/disqus.js"></script>

                        </div>
                        <div class="col-md-4"></div>
                    </div>
                </div>
            </div>


            <div id="footer">
                <div class="container">
                    Built by <a href="https://github.com/oinkina">Oinkina</a> with
                    <a href="http://jaspervdj.be/hakyll">Hakyll</a>
                    using <a href="http://getbootstrap.com/">Bootstrap</a>,
                    <a href="http://www.mathjax.org/">MathJax</a>,
                    <a href="http://disqus.com/">Disqus</a>,
                    <a href="https://github.com/unconed/MathBox.js">MathBox.js</a>,
                    <a href="http://highlightjs.org/">Highlight.js</a>,
                    and <a href="http://ignorethecode.net/blog/2010/04/20/footnotes/">Footnotes.js</a>.
                </div>
            </div>
        </div>

    <!-- jQuery-->
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.0/jquery.min.js"></script>
    <script src="http://code.jquery.com/jquery-1.10.1.min.js"></script>

    <script src="../../bootstrap/js/bootstrap.min.js"></script>

    <script src="../../highlight/highlight.pack.js"></script>
    <script>hljs.initHighlightingOnLoad();</script>

    <script src="../../js/footnotes.js"></script>

    <script src="../../comments/inlineDisqussions.js"></script>

<noscript>Enable JavaScript for footnotes, Disqus comments, and other cool stuff.</noscript>