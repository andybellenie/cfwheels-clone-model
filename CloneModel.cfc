<cfcomponent output="false" displayname="Clone Model" mixin="model">

	<!-----------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------
	Title:		Clone Model Plugin CF Wheels (http://cfwheels.org)
	
	Version:	0.2 BETA
	
	Source:		http://github.com/andybellenie/CFWheels-Clone-Model
	
	Author:		Andy Bellenie
	
	Support:	Please use the GitHub's issue tracker to report any problems with this plugin
				http://github.com/andybellenie/CFWheels-Clone-Model/issues

	Usage:		Use clone() in your model to create a duplicate of it in the database. Set 
				the 'recurse' argument to true to also create duplicates of all
				associated models via the 'hasMany' or 'hasOne' association types.
				
				Example controller function:
				
				<cffunction name="clone">
				   <cfset foo = model("foo").findByKey(params.key)>
				   <cfset cloneOfFoo = foo.clone(recurse=true)>
				</cffunction>
							
	-------------------------------------------------------------------------------------
	------------------------------------------------------------------------------------>	
	
	<cffunction name="init" access="public" output="false" returntype="any">
		<cfset this.version = "1.0.1,1.1" />
		<cfreturn this />
	</cffunction> 
	
	
	<cffunction name="clone" returntype="any" access="public" output="false" hint="Inserts a copy of the object if it passes callbacks. Returns the new object if it was successfully saved to the database, `false` if not."
		examples=
		'
			<!--- Inserts a copy of the user object into the database --->
			<cfset user = model("User").findByKey(params.key)>
			<cfset newUser = user.clone()>
		'
		categories="model-object,crud" chapters="cloning-records" functions="">
		<cfargument name="recurse" type="string" default="false" hint="Set to true to clone any models associated via hasMany() or hasOne().">
		<cfargument name="foreignKey" type="string" default="" hint="The foreign key in the child model to be cloned.">
		<cfargument name="foreignKeyValue" type="any" default="" hint="The foreign key in the child model to be cloned.">
		
		<cfset var loc = {}>
		
		<cfif this.isNew()>
			<cfset $throw(type="Wheels.CannotCloneNew", message="You cannot clone a new model.")>
		<cfelse>
			
			<!--- loop over the properties of the current model and save them into a local struct --->
			<cfloop collection="#this.properties()#" item="loc.key">
				<cfif StructKeyExists(this,loc.key) and not ListFindNoCase("#this.primaryKey()#,createdAt,updatedAt,deletedAt",loc.key)>
					<cfset loc.properties[loc.key] = this[loc.key]>
				</cfif>
			</cfloop>
	
			<!--- if a foreign key and value has been provided then this is an associated model, set the keys --->
			<cfif Len(arguments.foreignKey) and Len(arguments.foreignKeyValue)>
				<cfset loc.properties[arguments.foreignKey] = arguments.foreignKeyValue>
			</cfif>
			
			<!--- create a new instance of the model in memory - note: built-in cfwheels callbacks are NOT run --->
			<cfset loc.returnValue = $createInstance(properties=loc.properties, persisted=false)>
			
			<!--- run the beforeClone() callback on the new model --->
			<cfif loc.returnValue.$callback("beforeClone")>
				
				<!--- save the cloned model to the db --->
				<cfif loc.returnValue.$create(parameterize=true)>
					
					<cfset loc.returnValue.$updatePersistedProperties()>
					
					<!--- run the afterClone() callback --->
					<cfset loc.returnValue.$callback("afterClone")>
									
					<cfif arguments.recurse>
					
						<!--- for each hasMany()/hasOne() association, get the associated models and clone them too --->
						<cfloop collection="#variables.wheels.class.associations#" item="loc.key">
							<cfif ListFindNoCase("hasMany,hasOne",variables.wheels.class.associations[loc.key].type)>
								<cfset loc.arrChildren = Evaluate("this.#loc.key#(returnAs='objects')")>
								<cfif ArrayLen(loc.arrChildren)>
									<!--- load the expanded association in order to get the foreign key --->
									<cfset loc.association = this.$expandedAssociations(include=loc.key)>
									<cfset loc.association = loc.association[1]>
									<cfloop from="1" to="#ArrayLen(loc.arrChildren)#" index="loc.i">
										<cfset loc.arrChildren[loc.i].clone(recurse=true,foreignKey=loc.association.foreignKey,foreignKeyValue=loc.returnValue[this.primaryKey()])>
									</cfloop>
								</cfif>
							</cfif>
						</cfloop>
					</cfif>
	
					<!--- return the cloned model --->
					<cfreturn loc.returnValue>
					
				</cfif>
						
			</cfif>
		
		</cfif>
		
		<!--- beforeClone() callback must have failed, so return false --->
		<cfreturn false>
		
	</cffunction>
	
		
	<cffunction name="beforeClone" returntype="void" access="public" output="false" mixin="model" hint="Registers method(s) that should be called before an object is cloned.">
		<cfargument name="methods" type="string" required="false" default="" hint="See documentation for @afterNew.">
		<cfset $registerCallback(type="beforeClone", argumentCollection=arguments)>
	</cffunction>


	<cffunction name="afterClone" returntype="void" access="public" output="false" mixin="model" hint="Registers method(s) that should be called after an object is cloned.">
		<cfargument name="methods" type="string" required="false" default="" hint="See documentation for @afterNew.">
		<cfset $registerCallback(type="afterClone", argumentCollection=arguments)>
	</cffunction>	


</cfcomponent>