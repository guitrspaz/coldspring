/**
* @name: coldspring.monolith.MonolithLogger
* @hint: Logs coldspring errors for CoursePlus
* @author: Chris Schroeder (schroeder@jhu.edu)
* @copyright: Johns Hopkins University
* @created: Sunday, 04/30/2017 08:45:42 AM
* @modified: Sunday, 04/30/2017 08:45:42 AM
*/

component
	displayname="MonolithLogger"
	output="false"
	accessors="true"
{
	property name="coldspringLog" getter="true" setter="true" type="string";
	public coldspring.monolith.MonolithLogger function init(String coldspringLog='ColdSpringFactoryErrors'){
		this.setcoldspringLog(arguments.coldspringLog);
		return this;
	}

	public Void function ThrowError(
		String logName=this.getcoldspringLog() hint="name of log to write to",
		Any extendedInfo='',
		String message hint="if it exists, message gets added to the log text just before the args",
		Any detail='',
		String logType="information" hint="this directly reflects the type attribute for cflog",
		String type,
		Boolean throwOnError=true,
		Boolean logOnError=true
	){
		if( arguments.logOnError ){
			LogError(argumentCollection=arguments);
		}
		if( arguments.throwOnError ){
			throw(
				message=( structKeyExists( arguments,'message' ) )?arguments.message:'',
				detail=( structKeyExists( arguments,'detail' ) && isSimpleValue(arguments.detail) )?Trim(arguments.detail):( structKeyExists( arguments,'detail' ) && !isSimpleValue(arguments.detail) )?SerializeJSON(arguments.detail):'',
				extendedInfo=( StructKeyExists(arguments,'detail') && isSimpleValue(arguments.extendedInfo) )?Trim(arguments.extendedInfo):( StructKeyExists(arguments,'detail') && !isSimpleValue(arguments.extendedInfo) )?SerializeJSON(arguments.extendedInfo):'',
				type=( structKeyExists(arguments,'type') )?arguments.type:'unknown'
			);
		}
	}

	/**
	* @name:	MonolithLogger.getStackTrace
	* @hint:	I get the stackTrace and tagContext for an error
	* @date:	Sunday, 04/30/2017 09:08:15 AM
	* @author:	Chris Schroeder (schroeder@jhu.edu)
	*/
	private struct function getStackTrace(){
		var errorStruct={
			stackTrace={},
			start=Now()
		};
		try{
			Throw("This is thrown to gain access to the strack trace.","StackTrace");
		} catch( Any e ){
			if( structKeyExists( e,'stackTrace' ) ){
				errorStruct.stackTrace=e.StackTrace;
			}
			if( structKeyExists( e,'tagContext' ) ){
				errorStruct.tagContext=e.TagContext;
			}
		}
		errorStruct.end=Now();
		errorStruct.diff=DateDiff('s',errorStruct.start,errorStruct.end);
		return errorStruct;
	}

	/**
	* @name:	MonolithLogger.LogError
	* @hint:	I write coldspring errors to a log
	* @date:	Sunday, 04/30/2017 08:55:16 AM
	* @author:	Chris Schroeder (schroeder@jhu.edu)
	*/
	private void function LogError(
		String logName=this.getcoldspringLog() hint="name of log to write to",
		Any extendedInfo,
		String message hint="if it exists, message gets added to the log text just before the args",
		Any detail,
		String logType="information" hint="this directly reflects the type attribute for cflog",
		String type
	){
		//create text message
		var errorLog=( StructKeyExists(arguments,'logName') && Len(Trim(arguments.logName)) )?Trim(arguments.logName):this.getcoldspringLog();
		var logString={
			datestamp:DateTimeFormat(Now(),'full'),
			stackTrace:getStackTrace(),
			type:( StructKeyExists(arguments,'type') )?Trim(arguments.type):'unknown'
		};
		if( structKeyExists(arguments,'message') ){
			logString['message']=arguments.message;
		}
		if( StructKeyExists(arguments,'detail') ){
			logString['detail']=arguments.detail;
		}
		if( StructKeyExists(arguments,'extendedInfo') ){
			logString['extendedInfo']=arguments.extendedInfo;
		}

		//make sure there is a log type
		if( !( Len( Trim(arguments.logType) ) ) ){
			arguments.logType="information";
		}
		//serialize error struct
		WriteLog('Coldspring Error: '&SerializeJSON(logString),arguments.logType,'yes',errorLog);
	}
}