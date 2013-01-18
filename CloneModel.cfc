<cfcomponent output="false" displayname="Clone Model" mixin="model">


	<cffunction name="init" access="public" output="false" returntype="any">
		<cfset this.version = "1.1,1.1.1,1.1.2,1.1.3,1.1.4,1.1.5,1.1.6,1.1.7,1.1.8" />
		<cfreturn this />
	</cffunction>
	
	
	<!--- PUBLIC METHODS --->
	
	<cffunction name="clone" returntype="boolean" mixin="model" hint="I create a duplicate of the current model and save it to the database.">
		<cfargument name="recurse" type="string" default="false" hint="Set to true to clone any models associated via hasMany() or hasOne().">
		<cfargument name="parameterize" type="any" default="true" hint="See documentation for @findAll.">
		<cfargument name="validate" type="boolean" default="true" hint="See documentation for @save.">
		<cfargument name="transaction" type="string" default="#application.wheels.transactionMode#" hint="See documentation for @save.">
		<cfargument name="callbacks" type="boolean" default="true" hint="See documentation for @save.">
		<cfif invokeWithTransaction(method="$clone", argumentCollection=arguments)>
			<cfreturn true>
		</cfif>
		<cfreturn false>
	</cffunction>


	<cffunction name="beforeValidationOnClone" returntype="void" access="public" output="false" mixin="model" hint="Registers method(s) that should be called before validation is run on an object to be cloned.">
		<cfargument name="methods" type="string" required="false" default="" hint="See documentation for @afterNew.">
		<cfset $registerCallback(type="beforeValidationOnClone", argumentCollection=arguments)>
	</cffunction>


	<cffunction name="beforeClone" returntype="void" access="public" output="false" mixin="model" hint="Registers method(s) that should be called before an object is cloned.">
		<cfargument name="methods" type="string" required="false" default="" hint="See documentation for @afterNew.">
		<cfset $registerCallback(type="beforeClone", argumentCollection=arguments)>
	</cffunction>


	<cffunction name="afterValidationOnClone" returntype="void" access="public" output="false" mixin="model" hint="Registers method(s) that should be called after validation is run on an object to be cloned.">
		<cfargument name="methods" type="string" required="false" default="" hint="See documentation for @afterNew.">
		<cfset $registerCallback(type="afterValidationOnClone", argumentCollection=arguments)>
	</cffunction>


	<cffunction name="afterClone" returntype="void" access="public" output="false" mixin="model" hint="Registers method(s) that should be called after an object is cloned.">
		<cfargument name="methods" type="string" required="false" default="" hint="See documentation for @afterNew.">
		<cfset $registerCallback(type="afterClone", argumentCollection=arguments)>
	</cffunction>


	<!--- PRIVATE METHODS --->
	
	<cffunction name="$clone" returntype="boolean" mixin="model">
		
		<cfset var loc = {}>
		
		<cfset loc.clone = Duplicate(this)>
		
		<!--- delete identity columns --->
		<cfdbinfo type="columns" table="#this.tableName()#" datasource="#variables.wheels.class.connection.datasource#" name="loc.properties">
		<cfloop query="loc.properties">
			<cfif loc.properties.is_primaryKey and loc.properties.type_name contains "identity">
				<cfset StructDelete(loc.clone, loc.properties.column_name)>
			</cfif>
		</cfloop>
		
		<!--- set any changed properties into the clone --->
		<cfset loc.clone.$setProperties(properties=StructNew(), argumentCollection=arguments, filterList="recurse,parameterize,validate,callbacks,transaction")>
		
		<!--- clear those properties to prevent them being copied into children during recursion --->
		<cfloop collection="#arguments#" item="loc.prop">
			<cfif not ListFindNoCase("recurse,parameterize,validate,callbacks,transaction", loc.prop)>
				<cfset StructDelete(arguments, loc.prop)>
			</cfif>
		</cfloop>

		<!--- run callbacks and validation --->
		<cfif loc.clone.$callback("beforeValidation", arguments.callbacks) and loc.clone.$callback("beforeValidationOnClone", arguments.callbacks) and loc.clone.$validate("onSave", arguments.validate) and loc.clone.$callback("afterValidationOnClone", arguments.callbacks) and loc.clone.$callback("beforeClone", arguments.callbacks)>

			<!--- save the cloned model to the db --->
			<cfif loc.clone.$create(parameterize=arguments.parameterize, reload=false)>
				
				<cfif arguments.recurse>
				
					<!--- for each hasMany()/hasOne() association, get the child models and run $clone() on them too --->
					<cfloop collection="#variables.wheels.class.associations#" item="loc.key">
						
						<cfif ListFindNoCase("hasMany,hasOne", variables.wheels.class.associations[loc.key].type) and variables.wheels.class.associations[loc.key].allowClone>
							
							<!--- load the expanded association in order to get the foreign key --->
							<cfset loc.expandedAssociation = this.$expandedAssociations(include=loc.key)>
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

								<!--- set the new foreign key --->								
								<cfset arguments[loc.expandedAssociation.foreignKey] = loc.clone.key()>
								
								<!--- clone the child --->
								<cfif not loc.child.$clone(argumentCollection=arguments)>
									<cfset loc.clone.$copyObjectErrors(loc.child)>
									<cfreturn false>
								</cfif>
								
							</cfloop>
							
						</cfif>
						
					</cfloop>
				</cfif>
				
			</cfif>
			
			<cfset this.$setProperties(properties=loc.clone.properties())>
			
			<cfif this.$callback("afterClone", arguments.callbacks)>
				<cfset this.$updatePersistedProperties()>
				<cfreturn true>
			</cfif>
			
		</cfif>
		
		<cfset this.$copyObjectErrors(loc.clone)>
		
		<cfreturn false>
	</cffunction>
	
	
	<cffunction name="$registerAssociation" returntype="void" output="false">
		<cfargument name="allowClone" type="boolean" default="true">
		<cfset var coreMethod = core.$registerAssociation>
		<cfset coreMethod(argumentCollection=arguments)>
	</cffunction>
	
	
	<cffunction name="$copyObjectErrors" returntype="void" output="false">
		<cfargument name="source" type="any" required="true">
		<cfloop array="#source.allErrors()#" index="stuError">
			<cfset this.addError(argumentCollection=stuError)>				
		</cfloop>
	</cffunction>
	

</cfcomponent>