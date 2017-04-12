﻿<!---
   Copyright 2011 Mark Mandel

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
 --->

<cfcomponent hint="test for the remote facetory bean" extends="unittests.AbstractTestCase" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="setup" hint="setup" access="public" returntype="void" output="false">
	<cfscript>
		super.setup();

		basicProxyPath = expandPath("/unittests/HelloProxy.cfc");
		onMMProxyPath = expandPath("/unittests/HelloProxyOnMM.cfc");
		onMMAOPProxyPath = expandPath("/unittests/HelloProxyOnMMAOP.cfc");

		if(fileExists(basicProxyPath))
		{
			fileDelete(basicProxyPath);
		}
		if(fileExists(onMMProxyPath))
		{
			fileDelete(onMMProxyPath);
		}
		if(fileExists(onMMAOPProxyPath))
		{
			fileDelete(onMMAOPProxyPath);
		}

		initFactory();
    </cfscript>
</cffunction>

<cffunction name="teardown" hint="teardown" access="public" returntype="any" output="false">
	<cfscript>
		if(fileExists(basicProxyPath))
		{
			fileDelete(basicProxyPath);
		}
			if(fileExists(onMMProxyPath))
		{
			fileDelete(onMMProxyPath);
		}
			if(fileExists(onMMAOPProxyPath))
		{
			fileDelete(onMMAOPProxyPath);
		}
	</cfscript>
</cffunction>

<cffunction name="testSimpleReturnString" hint="test just returning a string" access="public" returntype="void" output="false">
	<cfscript>
		var local = {};
		local.path = "/unittests/HelloProxy.cfc?method=sayHello&returnFormat=json";
    </cfscript>
    <cfhttp url="#local.path#" method="get" result="local.result">

	<cfscript>
		debug(local.result);
		assertEquals("hello", deserializeJSON(local.result.fileContent));
    </cfscript>
</cffunction>

<cffunction name="testAddOnMissingMethod" hint="test adding onMissingMethod" access="public" returntype="void" output="false">
	<cfscript>
		var local = {};
		local.path = "/unittests/HelloProxyOnMM.cfc?method=doThis&returnFormat=json";
    </cfscript>
    <cfhttp url="#local.path#" method="get" result="local.result">

	<cfscript>
		debug(local.result);
		assertEquals("Missing!", deserializeJSON(local.result.fileContent));
    </cfscript>

	<cfscript>
		local.path = "/unittests/HelloProxyOnMM.cfc?method=doThat&returnFormat=json";
    </cfscript>
    <cfhttp url="#local.path#" method="get" result="local.result">

	<cfscript>
		debug(local.result);
		assertEquals("Missing!", deserializeJSON(local.result.fileContent));
    </cfscript>
</cffunction>

<cffunction name="testAddingInterceptors" hint="test applying interceptors" access="public" returntype="void" output="false">
	<cfscript>
		var local = {};
		local.path = "/unittests/HelloProxyOnMMAOP.cfc?method=doThis&returnFormat=json";
    </cfscript>
    <cfhttp url="#local.path#" method="get" result="local.result">

	<cfscript>
		debug(local.result);
		assertEquals(reverse("Missing!"), deserializeJSON(local.result.fileContent));
    </cfscript>

	<cfscript>
		local.path = "/unittests/HelloProxyOnMMAOP.cfc?method=doThat&returnFormat=json";
    </cfscript>
    <cfhttp url="#local.path#" method="get" result="local.result">

	<cfscript>
		debug(local.result);
		assertEquals(reverse("Missing!"), deserializeJSON(local.result.fileContent));
    </cfscript>

	<cfscript>
		println("Saying Hello!");
		local.path = "/unittests/HelloProxyOnMMAOP.cfc?method=sayHello&returnFormat=json";
    </cfscript>
    <cfhttp url="#local.path#" method="get" result="local.result">

	<cfscript>
		debug(local.result);
		assertEquals(reverse("hello"), deserializeJSON(local.result.fileContent));
    </cfscript>

	<cfscript>
		str = "FooBar!";
		local.path = "/unittests/HelloProxyOnMMAOP.cfc?method=sayHello&str=#urlEncodedFormat(str)#&returnFormat=json";
    </cfscript>
    <cfhttp url="#local.path#" method="get" result="local.result">

	<cfscript>
		debug(local.result);
		assertEquals(reverse(str), deserializeJSON(local.result.fileContent));
    </cfscript>
</cffunction>

<cffunction name="println" hint="" access="private" returntype="void" output="false">
	<cfargument name="str" hint="" type="string" required="Yes">
	<cfscript>
		createObject("Java", "java.lang.System").out.println(arguments.str);
	</cfscript>
</cffunction>

<cffunction name="testTrustedSource" hint="test to see if trusted source regenerates the file or not" access="public" returntype="void" output="false">
	<cfscript>
		var local = {};
		local.path = expandPath("/unittests/HelloProxy.cfc");
		local.file = createObject("java","java.io.File").init(basicProxyPath);

		//gate
		assertTrue(local.file.exists());
		assertFalse(factory.getBean("&helloProxy").isTrustedSource());

		local.length = local.file.length();

		modifyRemoteProxy(local.path);

		assertNotEquals(local.length, local.file.length());

		//save the modified file length.
		local.length = local.file.length();

		//create a new factory, and overwrite
		initFactory();

		assertNotEquals(local.length, local.file.length(), "Should be different, as the file was reverted back to original");

		modifyRemoteProxy(local.path);
		local.length = local.file.length();

		//below should pass, as we don't set the file to read only.
		initFactory(true);

		//should be the same
		assertEquals(local.length, local.file.length());

		//gate
		assertTrue(factory.getBean("&helloProxy").isTrustedSource());

		//one more time for kicks.
		initFactory(true);
		//gate
		assertTrue(factory.getBean("&helloProxy").isTrustedSource());
    </cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="initFactory" hint="handy method for init'ing the factory I want." access="private" returntype="void" output="false">
	<cfargument name="trusted" hint="whether or not it's trusted source" type="boolean" required="no" default="false">
	<cfscript>
		factory = createObject("component", "coldspring.beans.xml.XmlBeanFactory").init(expandPath("/unittests/testBeans/aop-remoteFactoryBean.xml"), arguments);
    </cfscript>
</cffunction>

<cffunction name="modifyRemoteProxy" hint="replace the remote proxy file with something fun" access="private" returntype="void" output="false">
	<cfargument name="path" hint="the path to the file" type="string" required="true">
	<cfscript>
		var content = createUUID();
		content = repeatString(content, randRange(1, 100));
	</cfscript>
	<cffile action="write" file="#arguments.path#" output="#content#" />
</cffunction>

</cfcomponent>