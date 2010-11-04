<cfcomponent output="false" displayname="Clone Model" mixin="model">


	<cffunction name="init" access="public" output="false" returntype="any">
		<cfset this.version = "1.0,1.1" />
		<cfreturn this />
	</cffunction> 
	
	
	<!--- PUBLIC METHODS --->
	
	<cffunction name="clone" returntype="any" mixin="model" hint="I create a duplicate of the current model and save it to the database.">
		<cfargument name="recurse" type="string" default="false" hint="Set to true to clone any models associated via hasMany() or hasOne().">
		<cfargument name="callbacks" type="boolean" required="false" default="true" hint="Set to `false` to disable callbacks during cloning.">
		<cfargument name="transaction" type="string" default="commit" hint="See documentation for @save.">
		<cfargument name="isolation" type="string" default="read_committed" hint="See documentation for @save.">
		<cfargument name="$foreignKeys" type="struct" default="#StructNew()#" hint="">
		<cfif invokeWithTransaction(method="$clone", argumentCollection=arguments)>
			<cfreturn this>
		</cfif>
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


	<!--- PRIVATE METHODS --->
	
	<cffunction name="$clone" returntype="boolean" mixin="model">
		
		<cfset var loc = {}>

		<!--- loop over the properties of the current model and save them into a local struct --->
		<cfloop collection="#this.properties()#" item="loc.key">
			<cfif StructKeyExists(this,loc.key) and not ListFindNoCase(this.primaryKey(), loc.key)>
				<cfset loc.properties[loc.key] = this[loc.key]>
			</cfif>
		</cfloop>

		<!--- if a key/values have been provided then this is an associated model, set the keys --->
		<cfloop collection="#arguments.$foreignKeys#" item="loc.key">
			<cfset loc.properties[loc.key] = arguments.$foreignKeys[loc.key]>
		</cfloop>
				
		<!--- create a new instance of the model in memory - note that normal create/update/save callbacks are not run --->
		<cfset loc.returnValue = $createObjectFromRoot(path=application.wheels.modelComponentPath, fileName=Capitalize(variables.wheels.class.modelName), method="$initModelObject", name=variables.wheels.class.modelName, properties=loc.properties, persisted=true)>
		
		<!--- run the beforeClone() callback --->
		<cfif loc.returnValue.$callback("beforeClone", arguments.callbacks)>

			<!--- save the cloned model to the db --->
			<cfif loc.returnValue.$create(parameterize=true, reload=false)>
				
				<cfif arguments.recurse>
				
					<!--- for each hasMany()/hasOne() association, get the child models and run clone() on them too --->
					<cfloop collection="#variables.wheels.class.associations#" item="loc.key">
						
						<cfif ListFindNoCase("hasMany,hasOne", variables.wheels.class.associations[loc.key].type)>
							
							<!--- load the expanded association in order to get the foreign key --->
							<cfset loc.expandedAssociation = loc.returnValue.$expandedAssociations(include=loc.key)>
							<cfset loc.expandedAssociation = loc.expandedAssociation[1]>
							
							<cftry>	
								<cfset loc.target = Evaluate("this.#loc.key#(returnAs='objects')")>
								<cfcatch>
									<cfset loc.target = Evaluate("this.#loc.key#")>
								</cfcatch>
							</cftry>
							
							<cfset loc.children = ArrayNew(1)>
							<cfif IsArray(loc.target)>
								<cfset loc.children = loc.target>
							<cfelseif IsObject(loc.target)>
								<cfset ArrayAppend(loc.children, loc.target)>
							</cfif>

							<cfloop array="#loc.children#" index="loc.child">
								<cfif not loc.child.$clone(callbacks=arguments.callbacks, recurse=true, $foreignKeys=$getForeignKeyValues(child=loc.child, parent=loc.returnValue, foreignKeys=loc.expandedAssociation.foreignKey))>
									<cfset loc.returnValue.$copyObjectErrors(loc.child)>
									<cfreturn false>
								</cfif>
							</cfloop>
							
						</cfif>
						
					</cfloop>
				</cfif>
				
				<cfif loc.returnValue.$callback("afterClone", arguments.callbacks)>
					<cfset loc.returnValue.$updatePersistedProperties()>
					<cfset this = loc.returnValue> <!--- swap out the current model for the clone --->
					<cfreturn true>
				</cfif>
				
			</cfif>
			
		</cfif>
		
		<!--- beforeClone() callback must have failed, so return false --->
		<cfreturn false>
	</cffunction>
	
	
	<cffunction name="$getForeignKeyValues" returntype="struct" access="public">
		<cfargument name="child" type="any" required="true">
		<cfargument name="parent" type="any" required="true">
		<cfargument name="foreignKeys" type="string" required="true">
		
		<cfset var loc = {}>
		<cfset loc.returnValue = {}>
		<cfset loc.childKeys = arguments.child.primaryKeys()>
		<cfset loc.parentKeys = arguments.parent.primaryKeys()>
		
		<cfloop from="1" to="#ListLen(loc.childKeys)#" index="loc.i">
			<cfset loc.childKey = ListGetAt(loc.childKeys, loc.i)>
			<cfif ListFindNoCase(arguments.foreignKeys, loc.childKey)>
				<cfset loc.returnValue[loc.childKey] = arguments.parent.key()>
			<cfelse>
				<cfset loc.returnValue[loc.childKey] = arguments.child[loc.childKey]>
			</cfif>
		</cfloop>
		
		<cfreturn loc.returnValue>
	</cffunction>
	
	
	<cffunction name="$copyObjectErrors" returntype="void" output="false">
		<cfargument name="source" type="any" required="true">
		<cfloop array="#source.allErrors()#" index="stuError">
			<cfset this.addError(argumentCollection=stuError)>				
		</cfloop>
	</cffunction>



	<!--- 1.0.x COMPATIBILITY METHODS --->


	<cffunction name="invokeWithTransaction" returntype="boolean" access="public" output="false">
		<cfset var coreMethod = "">
		<cfif StructKeyExists(core, "invokeWithTransaction")>
			<cfset coreMethod = core.invokeWithTransaction>
			<cfreturn coreMethod(argumentCollection=arguments)>
		</cfif>
		<cfreturn this.$clone(argumentCollection=arguments)>
	</cffunction>


	<cffunction name="$registerCallback" returntype="void" access="public" output="false" hint="Override method to create a key for a new callback type">
		<cfargument name="type" type="string" required="true">
		<cfset var coreMethod = core.$registerCallback>
		<cfif not StructKeyExists(variables.wheels.class.callbacks, arguments.type)>
			<cfset variables.wheels.class.callbacks[arguments.type] = ArrayNew(1)>
		</cfif>
		<cfset coreMethod(argumentCollection=arguments)>
	</cffunction>
	 
	
	<cffunction name="$callbacks" returntype="any" access="public" output="false" hint="Override method to return a blank array if the callback type doesn't exist)">
		<cfargument name="type" type="string" required="false" default="">
		<cfset var coreMethod = core.$callbacks>
		<cfif Len(arguments.type) and not StructKeyExists(variables.wheels.class.callbacks, arguments.type)>
			<cfreturn ArrayNew(1)>
		</cfif>
		<cfreturn coreMethod(argumentCollection=arguments)>
	</cffunction>
	

</cfcomponent>