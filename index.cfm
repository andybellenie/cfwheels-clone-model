<h1>Clone Model 0.1 ALPHA </h1>
<h3>By Andy Bellenie</h3>
<p>This plugin allows rapid duplication of existing model objects and their associations. This is currently in Alpha and I'd welcome any suggestions for improvements. </p>
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
<p>If recurse is set to true then any related models set up as either a hasMany() or hasOne() association will also be cloned. If the associated model also has associations then they too will be cloned, and so on until the process encounters a model without any associations.</p>
<h2>Usage</h2>
<pre>
&lt;cffunction name="clone"&gt;
&nbsp;&nbsp;&nbsp;&lt;cfset foo = model(&quot;foo&quot;).findByKey(params.key)&gt;
&nbsp;&nbsp;&nbsp;&lt;cfset cloneOfFoo = foo.clone(recurse=true)&gt;
&lt;/cffunction&gt;
</pre>

<h2>Support</h2>
<p>If you have encounter any problems when using this plugin, please submit them using the issue tracker on github:<br />
<a href="http://github.com/andybellenie/CFWheels-Clone-Model/issues" target="_blank">http://github.com/andybellenie/CFWheels-Clone-Model/issues</a>
</p>