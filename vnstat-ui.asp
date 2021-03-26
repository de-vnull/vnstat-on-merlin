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

var $j = jQuery.noConflict(); //avoid conflicts on John's fork (state.js)

function UsageHint(){
	var tag_name= document.getElementsByTagName('a');
	for(var i=0;i<tag_name.length;i++){
		tag_name[i].onmouseout=nd;
	}
	hinttext=thresholdstring;
	return overlib(hinttext, 0, 0);
}

function Validate_AllowanceStartDay(forminput){
	var inputname = forminput.name;
	var inputvalue = forminput.value*1;
	
	if(inputvalue > 31 || inputvalue < 1){
		$j(forminput).addClass("invalid");
		return false;
	}
	else{
		$j(forminput).removeClass("invalid");
		return true;
	}
}

function Validate_DataAllowance(forminput){
	var inputname = forminput.name;
	var inputvalue = forminput.value*1;
	
	if(inputvalue < 0 || forminput.value.length == 0 || inputvalue == NaN || forminput.value == "."){
		$j(forminput).addClass("invalid");
		return false;
	}
	else{
		$j(forminput).removeClass("invalid");
		return true;
	}
}

function Format_DataAllowance(forminput){
	var inputname = forminput.name;
	var inputvalue = forminput.value*1;
	
	if(inputvalue < 0 || forminput.value.length == 0 || inputvalue == NaN || forminput.value == "."){
		return false;
	}
	else{
		forminput.value=parseFloat(forminput.value).toFixed(2);
		return true;
	}
}

function ScaleDataAllowance(){
	if(document.form.dnvnstat_allowanceunit.value == "T"){
		document.form.dnvnstat_dataallowance.value = document.form.dnvnstat_dataallowance.value*1 / 1000;
	}
	else if(document.form.dnvnstat_allowanceunit.value == "G"){
		document.form.dnvnstat_dataallowance.value = document.form.dnvnstat_dataallowance.value*1 * 1000;
	}
	Format_DataAllowance(document.form.dnvnstat_dataallowance);
}

function GetCookie(cookiename,returntype){
	var s;
	if ((s = cookie.get("cookie_"+cookiename)) != null){
		return cookie.get("cookie_"+cookiename);
	}
	else{
		if(returntype == "string"){
			return "";
		}
		else if(returntype == "number"){
			return 0;
		}
	}
}

function SetCookie(cookiename,cookievalue){
	cookie.set("cookie_"+cookiename, cookievalue, 10 * 365);
}

function ScriptUpdateLayout(){
	var localver = GetVersionNumber("local");
	var serverver = GetVersionNumber("server");
	$j("#dnvnstat_version_local").text(localver);
	
	if(localver != serverver && serverver != "N/A"){
		$j("#dnvnstat_version_server").text("Updated version available: "+serverver);
		showhide("btnChkUpdate", false);
		showhide("dnvnstat_version_server", true);
		showhide("btnDoUpdate", true);
	}
}

function update_status(){
	$j.ajax({
		url: '/ext/dn-vnstat/detect_update.js',
		dataType: 'script',
		timeout: 3000,
		error: function(xhr){
			setTimeout(update_status, 1000);
		},
		success: function(){
			if(updatestatus == "InProgress"){
				setTimeout(update_status, 1000);
			}
			else{
				document.getElementById("imgChkUpdate").style.display = "none";
				showhide("dnvnstat_version_server", true);
				if(updatestatus != "None"){
					$j("#dnvnstat_version_server").text("Updated version available: "+updatestatus);
					showhide("btnChkUpdate", false);
					showhide("btnDoUpdate", true);
				}
				else{
					$j("#dnvnstat_version_server").text("No update available");
					showhide("btnChkUpdate", true);
					showhide("btnDoUpdate", false);
				}
			}
		}
	});
}

function CheckUpdate(){
	showhide("btnChkUpdate", false);
	document.formScriptActions.action_script.value = "start_dn-vnstatcheckupdate";
	document.formScriptActions.submit();
	document.getElementById("imgChkUpdate").style.display = "";
	setTimeout(update_status, 2000);
}

function DoUpdate(){
	document.form.action_script.value = "start_dn-vnstatdoupdate";
	document.form.action_wait.value = 10;
	showLoading();
	document.form.submit();
}

function GetVersionNumber(versiontype){
	var versionprop;
	if(versiontype == "local"){
		versionprop = custom_settings.dnvnstat_version_local;
	}
	else if(versiontype == "server"){
		versionprop = custom_settings.dnvnstat_version_server;
	}
	
	if(typeof versionprop == 'undefined' || versionprop == null){
		return "N/A";
	}
	else{
		return versionprop;
	}
}

$j.fn.serializeObject = function(){
	var o = custom_settings;
	var a = this.serializeArray();
	$j.each(a, function(){
		if (o[this.name] !== undefined && this.name.indexOf("dnvnstat") != -1 && this.name.indexOf("version") == -1){
			if (!o[this.name].push){
				o[this.name] = [o[this.name]];
			}
			o[this.name].push(this.value || '');
		} else if (this.name.indexOf("dnvnstat") != -1 && this.name.indexOf("version") == -1){
			o[this.name] = this.value || '';
		}
	});
	return o;
};

function SaveConfig(){
	document.getElementById('amng_custom').value = JSON.stringify($j('form').serializeObject());
	document.form.action_script.value = "start_dn-vnstatconfig";
	document.form.action_wait.value = 15;
	showLoading();
	document.form.submit();
}

function get_conf_file(){
	$j.ajax({
		url: '/ext/dn-vnstat/config.htm',
		dataType: 'text',
		timeout: 1000,
		error: function(xhr){
			setTimeout(get_conf_file, 1000);
		},
		success: function(data){
			var configdata=data.split("\n");
			configdata = configdata.filter(Boolean);
			for (var i = 0; i < configdata.length; i++){
				eval("document.form.dnvnstat_"+configdata[i].split("=")[0].toLowerCase()).value = configdata[i].split("=")[1].replace(/(\r\n|\n|\r)/gm,"");
			}
			get_vnstatconf_file();
		}
	});
}

function get_vnstatconf_file(){
	$j.ajax({
		url: '/ext/dn-vnstat/vnstatconf.htm',
		dataType: 'text',
		timeout: 1000,
		error: function(xhr){
			setTimeout(get_vnstatconf_file, 1000);
		},
		success: function(data){
			var configdata=data.split("\n");
			configdata = configdata.filter(Boolean);
			for (var i = 0; i < configdata.length; i++){
				if(configdata[i].startsWith("MonthRotate")){
					eval("document.form.dnvnstat_"+configdata[i].split(" ")[0].toLowerCase()).value = configdata[i].split(" ")[1].replace(/(\r\n|\n|\r)/gm,"");
				}
			}
		}
	});
}

function loadVnStatOutput(){
	$j.ajax({
		url: '/ext/dn-vnstat/vnstatoutput.htm',
		dataType: 'text',
		error: function(xhr){
			setTimeout(loadVnStatOutput, 5000);
		},
		success: function(data){
			document.getElementById("VnStatOuput").innerHTML=data;
		}
	});
}

function ShowHideDataUsageWarning(showusage){
	if(showusage){
		document.getElementById("datausagewarning").style.display = "";
		document.getElementById("scripttitle").style.marginLeft = "166px";
	}
	else{
		document.getElementById("datausagewarning").style.display = "none";
		document.getElementById("scripttitle").style.marginLeft = "0px";
	}
}

function UpdateText(){
	$j("#statstitle").html("The statistics and graphs on this page were last refreshed at: " + daterefeshed);
	$j("#spandatausage").html(usagestring);
	$j("#spanrealdatausage").html(realusagestring);
	ShowHideDataUsageWarning(usagethreshold);
}

function UpdateImages(){
	var images=["s","h","d","t","m"];
	for(var index = 0; index < images.length; index++){
		document.getElementById("img_"+images[index]).style.backgroundImage="url(/ext/dn-vnstat/images/.vnstat_"+images[index]+".htm?cachebuster="+new Date().getTime()+")";
	}
}

function UpdateStats(){
	showhide("btnUpdateStats", false);
	document.formScriptActions.action_script.value="start_dn-vnstat";
	document.formScriptActions.submit();
	document.getElementById("vnstatupdate_text").innerHTML = "Updating bandwidth usage and vnstat data...";
	showhide("imgVnStatUpdate", true);
	showhide("vnstatupdate_text", true);
	setTimeout(update_vnstat, 2000);
}

function update_vnstat(){
	$j.ajax({
		url: '/ext/dn-vnstat/detect_vnstat.js',
		dataType: 'script',
		timeout: 1000,
		error: function(xhr){
			setTimeout(update_vnstat, 1000);
		},
		success: function(){
			if(vnstatstatus == "InProgress"){
				setTimeout(update_vnstat, 1000);
			}
			else if(vnstatstatus == "Done"){
				reload_js('/ext/dn-vnstat/vnstatusage.js');
				UpdateText();
				UpdateImages();
				document.getElementById("vnstatupdate_text").innerHTML = "";
				showhide("imgVnStatUpdate", false);
				showhide("vnstatupdate_text", false);
				showhide("btnUpdateStats", true);
			}
		}
	});
}

function reload_js(src){
	$j('script[src="' + src + '"]').remove();
	$j('<script>').attr('src', src+'?cachebuster='+ new Date().getTime()).appendTo('head');
}

function AddEventHandlers(){
	$j(".collapsible-jquery").off('click').on('click', function(){
		$j(this).siblings().toggle("fast",function(){
			if($j(this).css("display") == "none"){
				SetCookie($j(this).siblings()[0].id,"collapsed");
			}
			else{
				SetCookie($j(this).siblings()[0].id,"expanded");
			}
		})
	});
	
	$j(".collapsible-jquery").each(function(index,element){
		if(GetCookie($j(this)[0].id,"string") == "collapsed"){
			$j(this).siblings().toggle(false);
		}
		else{
			$j(this).siblings().toggle(true);
		}
	});
}

function SetCurrentPage(){
	document.form.next_page.value = window.location.pathname.substring(1);
	document.form.current_page.value = window.location.pathname.substring(1);
}

function initial(){
	SetCurrentPage();
	LoadCustomSettings();
	ScriptUpdateLayout();
	show_menu();
	loadVnStatOutput();
	get_conf_file();
	AddEventHandlers();
	UpdateText();
	UpdateImages();
}

function reload(){
	location.reload(true);
}
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
<div class="formfontdesc">vnstat and vnstati are Linux data usage reporting tools.</div>
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
&nbsp;of month&nbsp;<span style="color:#FFCC00;">(between 1 and 31, default: 1)</span>
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
<textarea cols="65" rows="35" wrap="off" readonly="readonly" id="VnStatOuput" class="textarea_log_table" style="width:738px;font-family:'Courier New', Courier, mono; font-size:11px;border: none;padding: 5px;text-align:center;">If you are seeing this message, it means you don't have a vntstat stats file from present on your router.
Please use option 1 at the dn-vnstat CLI menu to create it</textarea>
</td>
</tr>
</table>
<p align="right"><small><i>dev_null - https://github.com/de-vnull/vnstat-on-merlin</i></small></td>
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
