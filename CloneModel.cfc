<cfcomponent output="false" displayname="Clone Model" mixin="model">

	<!-----------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------
	Title:		Clone Model Plugin CF Wheels (http://cfwheels.org)
	
	Version:	1.0
	
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
		<cfset this.version = "1.0,1.0.2" />
		<cfreturn this />
	</cffunction>
	
	
	<cffunction name="clone" returntype="any" access="public" output="false" hint="Inserts a copy of the object if it passes callbacks. Returns the new object if it was successfully saved to the database, `false` if not."
		examples=
		'
			<!--- Inserts a copy of the user object into the database --->
			<cfset user = model("User").findByKey(params.key)>
			<cfset clonedUser = user.clone([recurse=true/false])>
		'
		categories="model-object,crud" chapters="cloning-records" functions="">
		<cfargument name="recurse" type="string" default="false" hint="Set to `true` to clone any models associated via hasMany() or hasOne().">
		<cfargument name="foreignKey" type="string" default="" hint="The foreign key in the child model to be cloned.">
		<cfargument name="foreignKeyValue" type="any" default="" hint="The foreign key in the child model to be cloned.">
		<cfargument name="validate" type="boolean" required="false" default="true" hint="Whether or not to run validation when cloning.">
		<cfargument name="callbacks" type="boolean" required="false" default="true" hint="Whether or not to run callbacks when cloning.">
		
		<cfset var loc = {}>
		
		<cfif this.isNew()>
			<cfset $throw(type="Wheels.CannotCloneNew", message="You cannot clone a new model.")>
		<cfelse>
			
			<!--- create a new instance of the model in memory --->
			<cfset loc.returnValue = Duplicate(this)>
			
			<!--- remove primary and logging keys --->
			<cfset StructDelete(loc.returnValue,loc.returnValue.primaryKey())>
			<cfset StructDelete(loc.returnValue,"createdAt")>
			<cfset StructDelete(loc.returnValue,"updatedAt")>
			<cfset StructDelete(loc.returnValue,"deletedAt")>
			
			<!--- if a foreign key and value has been provided then this is an associated model --->
			<cfif Len(arguments.foreignKey) and Len(arguments.foreignKeyValue)>
				<cfset loc.returnValue[arguments.foreignKey] = arguments.foreignKeyValue>
			</cfif>
			
			<cfif loc.returnValue.$callback(type="beforeValidationOnClone", execute=arguments.callbacks) and loc.returnValue.$validate("onSave") and loc.returnValue.$callback(type="beforeClone", execute=arguments.callbacks)>
				
				<!--- save the cloned model to the db --->
				<cfif loc.returnValue.$create(parameterize=true)>
					
					<cfset loc.returnValue.$callback(type="afterClone", execute=arguments.callbacks)>
					<cfset loc.returnValue.$updatePersistedProperties()>
				
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
					
				</cfif>
						
			</cfif>
		
		</cfif>
		
		<cfreturn loc.returnValue>
	</cffunction>
	
		
	<cffunction name="beforeValidationOnClone" returntype="void" access="public" output="false" mixin="model" hint="Registers method(s) that should be called before an object is validation upon cloning.">
		<cfargument name="methods" type="string" required="false" default="" hint="See documentation for @afterNew.">
		<cfif not StructKeyExists(variables.wheels.class.callbacks,"beforeValidationOnClone")>
			<cfset variables.wheels.class.callbacks.beforeValidationOnClone = ArrayNew(1)>
		</cfif>
		<cfset $registerCallback(type="beforeValidationOnClone", argumentCollection=arguments)>
	</cffunction>


	<cffunction name="beforeClone" returntype="void" access="public" output="false" mixin="model" hint="Registers method(s) that should be called before an object is cloned.">
		<cfargument name="methods" type="string" required="false" default="" hint="See documentation for @afterNew.">
		<cfif not StructKeyExists(variables.wheels.class.callbacks,"beforeClone")>
			<cfset variables.wheels.class.callbacks.beforeClone = ArrayNew(1)>
		</cfif>
		<cfset $registerCallback(type="beforeClone", argumentCollection=arguments)>
	</cffunction>


	<cffunction name="afterClone" returntype="void" access="public" output="false" mixin="model" hint="Registers method(s) that should be called after an object is cloned.">
		<cfargument name="methods" type="string" required="false" default="" hint="See documentation for @afterNew.">
		<cfif not StructKeyExists(variables.wheels.class.callbacks,"afterClone")>
			<cfset variables.wheels.class.callbacks.afterClone = ArrayNew(1)>
		</cfif>
		<cfset $registerCallback(type="afterClone", argumentCollection=arguments)>
	</cffunction>
	
	
	<!--- override internal $callback() function to allow the new callback types --->
	<cffunction name="$callback" returntype="boolean" access="public" output="false" mixin="model">
		<cfargument name="type" type="string" required="true">	
		<cfset var coreCallBackMethod = core.$callback>
		<cfif not StructKeyExists(variables.wheels.class.callbacks,arguments.type)>
			<cfset variables.wheels.class.callbacks[arguments.type] = ArrayNew(1)>
		</cfif>
		<cfreturn coreCallBackMethod(argumentCollection=arguments)>
	</cffunction>
	

</cfcomponent>