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
	
	if(inputvalue > 28 || inputvalue < 1){
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
	document.form.action_wait.value = 15;
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
	var datestring = new Date().getTime();
	for(var index = 0; index < images.length; index++){
		document.getElementById("img_"+images[index]).style.backgroundImage="url(/ext/dn-vnstat/images/.vnstat_"+images[index]+".htm?cachebuster="+datestring+")";
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
				loadVnStatOutput();
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
	get_conf_file();
	AddEventHandlers();
	UpdateText();
	UpdateImages();
	loadVnStatOutput();
}

function reload(){
	location.reload(true);
}
