<h1>Clone Model 1.1</h1>
<h3>A plugin for <a href="http://cfwheels.org" target="_blank">Coldfusion on Wheels</a> by <a href="http://cfwheels.org/user/profile/24" target="_blank">Andy Bellenie</a></h3>
<p>This plugin allows rapid duplication of existing model objects and their associations.</p>
<h2>New Methods</h2>
<ul>
  <li>clone([recurse=true/false])</li>
</ul>

<h2>New Callbacks</h2>
<ul>
  <li>beforeClone()</li>
	<li>afterClone() </li>
</ul>
<h2>Recursion</h2>
<p>If recurse is set to true then any associated models set up as with either a hasMany() or a hasOne() association will also be cloned. If the associated model also has associations then they too will be cloned, and so on until the process encounters a model without any associations.</p>
<h2>Usage</h2>
<pre>
&lt;cffunction name="clone"&gt;
&nbsp;&nbsp;&nbsp;&lt;cfset foo = model(&quot;foo&quot;).findByKey(params.key)&gt;
&nbsp;&nbsp;&nbsp;&lt;cfset cloneOfFoo = foo.clone(recurse=true)&gt;
&lt;/cffunction&gt;
</pre>
<h2>Support</h2>
<p>I try to keep my plugins free from bugs and up to date with Wheels releases, but if you encounter a problem please log an issue using the tracker on github, where you can also browse my other plugins.<br />
<a href="https://github.com/andybellenie" target="_blank">https://github.com/andybellenie</a></p>