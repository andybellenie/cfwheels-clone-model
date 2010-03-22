<h1>Clone Model 1.0</h1>
<h3>By Andy Bellenie</h3>
<p>This plugin allows simple duplication of existing model objects and their associations.</p>
<h2>New Model Methods</h2>
<ul>
  <li>clone([recurse=true/false, exclude=&quot;foo,bar&quot;]) - returns the clone as an object</li>
</ul>

<h2>New Callbacks</h2>
<p>Wheels standard callbacks are not run during the cloning process,	so this plugin provides three new callback methods.</p>
<ul>
  <li>beforeValidationOnClone()</li>
	<li>beforeClone()</li>
	<li>afterClone() </li>
</ul>
<h2>Recursion</h2>
<p>If recurse is set to true then any related models set up as either a hasMany() or hasOne() association will also be cloned. If the associated model also has associations then they too will be cloned, and so on until the process encounters a model without any associations.</p>
<h2>Exclusions</h2>
<p>During recursion, you may not want to include all associated models. To skip certain models, pass them into the 'exclude' argument as a comma delimited string.</p>
<h2>Usage</h2>
<pre>
&lt;cffunction name="clone"&gt;
&nbsp;&nbsp;&nbsp;&lt;cfset objFoo = model(&quot;foo&quot;).findByKey(params.key)&gt;
&nbsp;&nbsp;&nbsp;&lt;cfset objCloneOfFoo = foo.clone(recurse=true, exclude=&quot;bar&quot;)&gt;
&lt;/cffunction&gt;
</pre>

<h2>Support</h2>
<p>If you have encounter any problems when using this plugin, please submit them using the issue tracker on github:<br />
<a href="http://github.com/andybellenie/CFWheels-Clone-Model/issues" target="_blank">http://github.com/andybellenie/CFWheels-Clone-Model/issues</a>
</p>