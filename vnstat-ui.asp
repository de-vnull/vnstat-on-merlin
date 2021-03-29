<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="X-UA-Compatible" content="IE=Edge"/>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta http-equiv="Pragma" content="no-cache">
<meta http-equiv="Expires" content="-1">
<meta http-equiv="CACHE-CONTROL" content="NO-CACHE">
<link rel="shortcut icon" href="images/favicon.png">
<link rel="icon" href="images/favicon.png">
<title>dn-vnstat</title>
<link rel="stylesheet" type="text/css" href="index_style.css">
<link rel="stylesheet" type="text/css" href="form_style.css">
<style>
p {
  font-weight: bolder;
}

thead.collapsible-jquery {
  color: white;
  padding: 0px;
  width: 100%;
  border: none;
  text-align: left;
  outline: none;
  cursor: pointer;
}

input.settingvalue {
  margin-left: 3px !important;
}

label.settingvalue {
  margin-right: 10px !important;
  vertical-align: top !important;
}

.invalid {
  background-color: darkred !important;
}

.removespacing {
  padding-left: 0px !important;
  margin-left: 0px !important;
  margin-bottom: 5px !important;
  text-align: center !important;
}

.usagehint {
  color: #FFFF00 !important;
}

div.vnstat {
  background-repeat: no-repeat !important;
  background-position: center !important;
}
</style>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/jquery.js"></script>
<script language="JavaScript" type="text/javascript" src="/state.js"></script>
<script language="JavaScript" type="text/javascript" src="/general.js"></script>
<script language="JavaScript" type="text/javascript" src="/popup.js"></script>
<script language="JavaScript" type="text/javascript" src="/help.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/detect.js"></script>
<script language="JavaScript" type="text/javascript" src="/tmhist.js"></script>
<script language="JavaScript" type="text/javascript" src="/tmmenu.js"></script>
<script language="JavaScript" type="text/javascript" src="/client_function.js"></script>
<script language="JavaScript" type="text/javascript" src="/validator.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/dn-vnstat/vnstatusage.js"></script>
<script>
var custom_settings;
function LoadCustomSettings(){
	custom_settings = <% get_custom_settings(); %>;
	for (var prop in custom_settings){
		if(Object.prototype.hasOwnProperty.call(custom_settings, prop)){
			if(prop.indexOf("dnvnstat") != -1 && prop.indexOf("dnvnstat_version") == -1){
				eval("delete custom_settings."+prop)
			}
		}
	}
}
var $j=jQuery.noConflict();function UsageHint(){for(var a=document.getElementsByTagName("a"),b=0;b<a.length;b++)a[b].onmouseout=nd;return hinttext=thresholdstring,overlib(hinttext,0,0)}function Validate_AllowanceStartDay(a){var b=a.name,c=1*a.value;return 28<c||1>c?($j(a).addClass("invalid"),!1):($j(a).removeClass("invalid"),!0)}function Validate_DataAllowance(a){var b=a.name,c=1*a.value;return 0>c||0==a.value.length||c==NaN||"."==a.value?($j(a).addClass("invalid"),!1):($j(a).removeClass("invalid"),!0)}function Format_DataAllowance(a){var b=a.name,c=1*a.value;return!(0>c||0==a.value.length||c==NaN||"."==a.value)&&(a.value=parseFloat(a.value).toFixed(2),!0)}function ScaleDataAllowance(){"T"==document.form.dnvnstat_allowanceunit.value?document.form.dnvnstat_dataallowance.value=1*document.form.dnvnstat_dataallowance.value/1e3:"G"==document.form.dnvnstat_allowanceunit.value&&(document.form.dnvnstat_dataallowance.value=1e3*(1*document.form.dnvnstat_dataallowance.value)),Format_DataAllowance(document.form.dnvnstat_dataallowance)}function GetCookie(a,b){var c;if(null!=(c=cookie.get("cookie_"+a)))return cookie.get("cookie_"+a);return"string"==b?"":"number"==b?0:void 0}function SetCookie(a,b){cookie.set("cookie_"+a,b,3650)}function ScriptUpdateLayout(){var a=GetVersionNumber("local"),b=GetVersionNumber("server");$j("#dnvnstat_version_local").text(a),a!=b&&"N/A"!=b&&($j("#dnvnstat_version_server").text("Updated version available: "+b),showhide("btnChkUpdate",!1),showhide("dnvnstat_version_server",!0),showhide("btnDoUpdate",!0))}function update_status(){$j.ajax({url:"/ext/dn-vnstat/detect_update.js",dataType:"script",timeout:3e3,error:function(){setTimeout(update_status,1e3)},success:function(){"InProgress"==updatestatus?setTimeout(update_status,1e3):(document.getElementById("imgChkUpdate").style.display="none",showhide("dnvnstat_version_server",!0),"None"==updatestatus?($j("#dnvnstat_version_server").text("No update available"),showhide("btnChkUpdate",!0),showhide("btnDoUpdate",!1)):($j("#dnvnstat_version_server").text("Updated version available: "+updatestatus),showhide("btnChkUpdate",!1),showhide("btnDoUpdate",!0)))}})}function CheckUpdate(){showhide("btnChkUpdate",!1),document.formScriptActions.action_script.value="start_dn-vnstatcheckupdate",document.formScriptActions.submit(),document.getElementById("imgChkUpdate").style.display="",setTimeout(update_status,2e3)}function DoUpdate(){document.form.action_script.value="start_dn-vnstatdoupdate",document.form.action_wait.value=15,showLoading(),document.form.submit()}function GetVersionNumber(a){var b;return"local"==a?b=custom_settings.dnvnstat_version_local:"server"==a&&(b=custom_settings.dnvnstat_version_server),"undefined"==typeof b||null==b?"N/A":b}$j.fn.serializeObject=function(){var b=custom_settings,c=this.serializeArray();return $j.each(c,function(){void 0!==b[this.name]&&-1!=this.name.indexOf("dnvnstat")&&-1==this.name.indexOf("version")?(!b[this.name].push&&(b[this.name]=[b[this.name]]),b[this.name].push(this.value||"")):-1!=this.name.indexOf("dnvnstat")&&-1==this.name.indexOf("version")&&(b[this.name]=this.value||"")}),b};function SaveConfig(){document.getElementById("amng_custom").value=JSON.stringify($j("form").serializeObject()),document.form.action_script.value="start_dn-vnstatconfig",document.form.action_wait.value=15,showLoading(),document.form.submit()}function get_conf_file(){$j.ajax({url:"/ext/dn-vnstat/config.htm",dataType:"text",timeout:1e3,error:function(){setTimeout(get_conf_file,1e3)},success:function(data){var configdata=data.split("\n");configdata=configdata.filter(Boolean);for(var i=0;i<configdata.length;i++)eval("document.form.dnvnstat_"+configdata[i].split("=")[0].toLowerCase()).value=configdata[i].split("=")[1].replace(/(\r\n|\n|\r)/gm,"");get_vnstatconf_file()}})}function get_vnstatconf_file(){$j.ajax({url:"/ext/dn-vnstat/vnstatconf.htm",dataType:"text",timeout:1e3,error:function(){setTimeout(get_vnstatconf_file,1e3)},success:function(data){var configdata=data.split("\n");configdata=configdata.filter(Boolean);for(var i=0;i<configdata.length;i++)configdata[i].startsWith("MonthRotate")&&(eval("document.form.dnvnstat_"+configdata[i].split(" ")[0].toLowerCase()).value=configdata[i].split(" ")[1].replace(/(\r\n|\n|\r)/gm,""))}})}function loadVnStatOutput(){$j.ajax({url:"/ext/dn-vnstat/vnstatoutput.htm",dataType:"text",error:function(){setTimeout(loadVnStatOutput,5e3)},success:function(a){document.getElementById("VnStatOuput").innerHTML=a}})}function ShowHideDataUsageWarning(a){a?(document.getElementById("datausagewarning").style.display="",document.getElementById("scripttitle").style.marginLeft="166px"):(document.getElementById("datausagewarning").style.display="none",document.getElementById("scripttitle").style.marginLeft="0px")}function UpdateText(){$j("#statstitle").html("The statistics and graphs on this page were last refreshed at: "+daterefeshed),$j("#spandatausage").html(usagestring),$j("#spanrealdatausage").html(realusagestring),ShowHideDataUsageWarning(usagethreshold)}function UpdateImages(){for(var a=["s","h","d","t","m"],b=new Date().getTime(),c=0;c<a.length;c++)document.getElementById("img_"+a[c]).style.backgroundImage="url(/ext/dn-vnstat/images/.vnstat_"+a[c]+".htm?cachebuster="+b+")"}function UpdateStats(){showhide("btnUpdateStats",!1),document.formScriptActions.action_script.value="start_dn-vnstat",document.formScriptActions.submit(),document.getElementById("vnstatupdate_text").innerHTML="Updating bandwidth usage and vnstat data...",showhide("imgVnStatUpdate",!0),showhide("vnstatupdate_text",!0),setTimeout(update_vnstat,2e3)}function update_vnstat(){$j.ajax({url:"/ext/dn-vnstat/detect_vnstat.js",dataType:"script",timeout:1e3,error:function(){setTimeout(update_vnstat,1e3)},success:function(){"InProgress"==vnstatstatus?setTimeout(update_vnstat,1e3):"Done"==vnstatstatus&&(reload_js("/ext/dn-vnstat/vnstatusage.js"),UpdateText(),UpdateImages(),loadVnStatOutput(),document.getElementById("vnstatupdate_text").innerHTML="",showhide("imgVnStatUpdate",!1),showhide("vnstatupdate_text",!1),showhide("btnUpdateStats",!0))}})}function reload_js(a){$j("script[src=\""+a+"\"]").remove(),$j("<script>").attr("src",a+"?cachebuster="+new Date().getTime()).appendTo("head")}function AddEventHandlers(){$j(".collapsible-jquery").off("click").on("click",function(){$j(this).siblings().toggle("fast",function(){"none"==$j(this).css("display")?SetCookie($j(this).siblings()[0].id,"collapsed"):SetCookie($j(this).siblings()[0].id,"expanded")})}),$j(".collapsible-jquery").each(function(){"collapsed"==GetCookie($j(this)[0].id,"string")?$j(this).siblings().toggle(!1):$j(this).siblings().toggle(!0)})}function SetCurrentPage(){document.form.next_page.value=window.location.pathname.substring(1),document.form.current_page.value=window.location.pathname.substring(1)}function initial(){SetCurrentPage(),LoadCustomSettings(),ScriptUpdateLayout(),show_menu(),get_conf_file(),AddEventHandlers(),UpdateText(),UpdateImages(),loadVnStatOutput()}function reload(){location.reload(!0)}
</script>
</head>
<body onload="initial();" onunload="return unload_body();">
<div id="TopBanner"></div>
<div id="Loading" class="popup_bg"></div>
<iframe name="hidden_frame" id="hidden_frame" src="about:blank" width="0" height="0" frameborder="0"></iframe>
<form method="post" name="form" id="ruleForm" action="/start_apply.htm" target="hidden_frame">
<input type="hidden" name="current_page" value="">
<input type="hidden" name="next_page" value="">
<input type="hidden" name="modified" value="0">
<input type="hidden" name="action_mode" value="apply">
<input type="hidden" name="action_script" value="start_dn-vnstat">
<input type="hidden" name="action_wait" value="45">
<input type="hidden" name="first_time" value="">
<input type="hidden" name="SystemCmd" value="">
<input type="hidden" name="preferred_lang" id="preferred_lang" value="<% nvram_get("preferred_lang"); %>">
<input type="hidden" name="firmver" value="<% nvram_get("firmver"); %>">
<input type="hidden" name="amng_custom" id="amng_custom" value="">
<table class="content" align="center" cellpadding="0" cellspacing="0">
<tr>
<td width="17">&nbsp;</td>
<td valign="top" width="202">
<div id="mainMenu"></div>
<div id="subMenu"></div></td>
<td valign="top">
<div id="tabMenu" class="submenuBlock"></div>
<table width="98%" border="0" align="left" cellpadding="0" cellspacing="0">
<tr>
<td valign="top">
<table width="760px" border="0" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTitle" id="FormTitle">
<tbody>
<tr bgcolor="#4D595D">
<td valign="top">
<div id="datausagewarning">
<div style="float:right;color:#FFFF00;font-weight:bold;font-size:14px;padding-top:2px;margin-right:10px;"><a class="hintstyle usagehint" href="javascript:void(0);" onclick="UsageHint();">Data usage warning</a></div>
<div style="height:30px;width:24px;overflow:hidden;float:right;"><a class="hintstyle usagehint" href="javascript:void(0);" onclick="UsageHint();"><img src="/images/New_ui/notification.png" style=""></a></div>
</div>
<div>&nbsp;</div>
<div class="formfonttitle" id="scripttitle" style="text-align:center;margin-left:166px;">Vnstat on Merlin</div>
<div id="statstitle" style="text-align:center;">This page last refreshed:</div>
<div style="margin:10px 0 10px 5px;" class="splitLine"></div>
<div class="formfontdesc">vnStat is a Linux data usage reporting tool.</div>
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" style="border:0px;" id="table_buttons">
<thead class="collapsible-jquery" id="scripttools">
<tr><td colspan="2">Utilities (click to expand/collapse)</td></tr>
</thead>
<tr>
<th width="20%">Version information</th>
<td>
<span id="dnvnstat_version_local" style="color:#FFFFFF;"></span>
&nbsp;&nbsp;&nbsp;
<span id="dnvnstat_version_server" style="display:none;">Update version</span>
&nbsp;&nbsp;&nbsp;
<input type="button" class="button_gen" onclick="CheckUpdate();" value="Check" id="btnChkUpdate">
<img id="imgChkUpdate" style="display:none;vertical-align:middle;" src="images/InternetScan.gif"/>
<input type="button" class="button_gen" onclick="DoUpdate();" value="Update" id="btnDoUpdate" style="display:none;">
&nbsp;&nbsp;&nbsp;
</td>
</tr>
<tr>
<th width="20%">Update stats</th>
<td>
<input type="button" onclick="UpdateStats();" value="Update stats" class="button_gen" name="btnUpdateStats" id="btnUpdateStats">
<img id="imgVnStatUpdate" style="display:none;vertical-align:middle;" src="images/InternetScan.gif"/>
&nbsp;&nbsp;&nbsp;
<span id="vnstatupdate_text" style="display:none;"></span>
</td>
</tr>
</table>
<div style="line-height:10px;">&nbsp;</div>
<table width="100%" border="1" align="center" cellpadding="2" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" style="border:0px;" id="table_config">
<thead class="collapsible-jquery" id="scriptconfig">
<tr><td colspan="2">Configuration (click to expand/collapse)</td></tr>
</thead>
<tr class="even" id="rowenabledailyemail">
<th width="40%">Enable daily summary emails</th>
<td class="settingvalue">
<input type="radio" name="dnvnstat_dailyemail" id="dnvnstat_dailyemail_html" class="input" value="html">
<label for="dnvnstat_dailyemail_html" class="settingvalue">HTML</label>
<input type="radio" name="dnvnstat_dailyemail" id="dnvnstat_dailyemail_text" class="input" value="text">
<label for="dnvnstat_dailyemail_text" class="settingvalue">Text</label>
<input type="radio" name="dnvnstat_dailyemail" id="dnvnstat_dailyemail_none" class="input" value="none" checked>
<label for="dnvnstat_dailyemail_none" class="settingvalue">Disabled</label>
</td>
</tr>
<tr class="even" id="rowenableusageemail">
<th width="40%">Enable data usage warning emails</th>
<td class="settingvalue">
<input type="radio" name="dnvnstat_usageemail" id="dnvnstat_usageemail_true" class="input" value="true">
<label for="dnvnstat_usageemail_true" class="settingvalue">Enabled</label>
<input type="radio" name="dnvnstat_usageemail" id="dnvnstat_usageemail_false" class="input" value="false" checked>
<label for="dnvnstat_usageemail_false" class="settingvalue">Disabled</label>
</td>
</tr>
<tr class="even" id="rowdataallowance">
<th width="40%">Bandwidth allowance for data usage warnings
<br />
<a href="https://github.com/de-vnull/vnstat-on-merlin/blob/main/more-info.md#Data-limits" target="_blank" style="color:#FFCC00;">More info</a>
</th>
<td class="settingvalue">
<input autocomplete="off" type="text" maxlength="8" class="input_12_table removespacing" name="dnvnstat_dataallowance" value="1200.00" onkeypress="return validator.isNumberFloat(this, event)" onkeyup="Validate_DataAllowance(this)" onblur="Validate_DataAllowance(this);Format_DataAllowance(this)" />
&nbsp;<span id="spandefaultallowance" style="color:#FFCC00;">(0: unlimited)</span>
</td>
</tr>
<tr class="even" id="rowallowanceunit">
<th width="40%">Unit for bandwidth allowance</th>
<td class="settingvalue">
<input type="radio" name="dnvnstat_allowanceunit" id="dnvnstat_allowanceunit_g" class="input" value="G" onchange="ScaleDataAllowance();" checked>
<label for="dnvnstat_allowanceunit_g" id="label_allowanceunit_g" class="settingvalue">GB</label>
<input type="radio" name="dnvnstat_allowanceunit" id="dnvnstat_allowanceunit_t" class="input" value="T" onchange="ScaleDataAllowance();">
<label for="dnvnstat_allowanceunit_t" id="label_allowanceunit_t" class="settingvalue">TB</label>
</td>
</tr>
<tr class="even" id="rowmonthrotate">
<th width="40%">Start day for bandwidth allowance cycle<br />
<a href="https://github.com/de-vnull/vnstat-on-merlin/blob/main/more-info.md#MonthRotate" target="_blank" style="color:#FFCC00;">More info</a>
</th>
<td class="settingvalue">Day&nbsp;
<input autocomplete="off" type="text" maxlength="2" class="input_3_table removespacing" name="dnvnstat_monthrotate" value="1" onkeypress="return validator.isNumber(this, event)" onkeyup="Validate_AllowanceStartDay(this)" onblur="Validate_AllowanceStartDay(this)" />
&nbsp;of month&nbsp;<span style="color:#FFCC00;">(between 1 and 28, default: 1)</span>
</td>
</tr>
<tr class="apply_gen" valign="top" height="35px">
<td colspan="2" style="background-color:rgb(77, 89, 93);">
<input type="button" onclick="SaveConfig();" value="Save" class="button_gen" name="button">
</td>
</tr>
</table>
<div style="line-height:10px;">&nbsp;</div>
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
<thead class="collapsible-jquery" id="thead_monthly">
<tr><td colspan="2">Monthly usage (click to expand/collapse)</td></tr>
</thead>
<tr>
<th width="20%">Data usage for current cycle</th>
<td>
<span id="spandatausage" style="color:#FFFFFF;"></span>
<br />
<span id="spanrealdatausage" style="color:#FFFFFF;font-style:italic;"></span>&nbsp;&nbsp;<a href="https://github.com/de-vnull/vnstat-on-merlin/blob/main/more-info.md#Units" target="_blank" style="color:#FFCC00;">More info</a>
</td>
</tr>
<tr><td colspan="2" align="center" style="padding: 0px;">
<div id="img_m" class="vnstat" style="background-image:url('/ext/dn-vnstat/images/.vnstat_m.htm');">
<img style="visibility:hidden;" src="/ext/dn-vnstat/images/vnstat_m.png" alt="Monthly"/>
</div>
</td></tr>
</table>
<div style="line-height:10px;">&nbsp;</div>
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
<thead class="collapsible-jquery" id="thead_daily">
<tr><td colspan="2">Daily usage (click to expand/collapse)</td></tr>
</thead>
<tr><td colspan="2" align="center" style="padding: 0px;">
<div id="img_d" class="vnstat" style="background-image:url('/ext/dn-vnstat/images/.vnstat_d.htm');">
<img style="visibility:hidden;" src="/ext/dn-vnstat/images/vnstat_d.png" alt="Daily"/>
</div>
</td></tr>
</table>
<div style="line-height:10px;">&nbsp;</div>
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
<thead class="collapsible-jquery" id="thead_hourly">
<tr><td colspan="2">Hourly usage (click to expand/collapse)</td></tr>
</thead>
<tr><td colspan="2" align="center" style="padding: 0px;">
<div id="img_h" class="vnstat" style="background-image:url('/ext/dn-vnstat/images/.vnstat_h.htm');">
<img style="visibility:hidden;" src="/ext/dn-vnstat/images/vnstat_h.png" alt="Hourly" />
</div>
</td></tr>
</table>
<div style="line-height:10px;">&nbsp;</div>
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
<thead class="collapsible-jquery" id="thead_summary">
<tr><td colspan="2">Summary of all usage (click to expand/collapse)</td></tr>
</thead>
<tr><td colspan="2" align="center" style="padding: 0px;">
<div id="img_s" class="vnstat" style="background-image:url('/ext/dn-vnstat/images/.vnstat_s.htm');">
<img style="visibility:hidden;" src="/ext/dn-vnstat/images/vnstat_s.png" alt="Summary" />
</div>
</td></tr>
</table>
<div style="line-height:10px;">&nbsp;</div>
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
<thead class="collapsible-jquery" id="thead_top10">
<tr><td colspan="2">Top 10 usage (click to expand/collapse)</td></tr>
</thead>
<tr><td colspan="2" align="center" style="padding: 0px;">
<div id="img_t" class="vnstat" style="background-image:url('/ext/dn-vnstat/images/.vnstat_t.htm');">
<img style="visibility:hidden;" src="/ext/dn-vnstat/images/vnstat_t.png" alt="Top10" />
</div>
</td></tr>
</table>
<div style="line-height:10px;">&nbsp;</div>
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
<thead class="collapsible-jquery" id="thead_cli">
<tr><td colspan="2">vnstat CLI (click to expand/collapse)</td></tr>
</thead>
<tr>
<td colspan="2" style="padding: 0px;">
<textarea cols="65" rows="35" wrap="off" readonly="readonly" id="VnStatOuput" class="textarea_log_table" style="width:738px;font-family:'Courier New',Courier,mono;font-size:11px;border:none;padding:5px;text-align:center;">If you are seeing this message, it means you don't have a vntstat stats file present on your router.
Please use option 1 at the dn-vnstat CLI menu to create it</textarea>
</td>
</tr>
</table>
<p align="right"><small><i>dev_null & Jack Yaz - https://github.com/de-vnull/vnstat-on-merlin</i></small></td>
</tr>
</tbody>
</table>
</td>
</tr>
</table>
</td>
</tr>
</table>
</form>
<form method="post" name="formScriptActions" action="/start_apply.htm" target="hidden_frame">
<input type="hidden" name="productid" value="<% nvram_get("productid"); %>">
<input type="hidden" name="current_page" value="">
<input type="hidden" name="next_page" value="">
<input type="hidden" name="action_mode" value="apply">
<input type="hidden" name="action_script" value="">
<input type="hidden" name="action_wait" value="">
</form>
<div id="footer"></div>
</body>
</html>
