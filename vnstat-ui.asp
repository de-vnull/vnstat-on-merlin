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
p{font-weight:bolder}thead.collapsible-jquery{color:#fff;padding:0;width:100%;border:none;text-align:left;outline:none;cursor:pointer}.SettingsTable{text-align:left}.SettingsTable input{text-align:left;margin-left:3px!important}.SettingsTable input.savebutton{text-align:center;margin-top:5px;margin-bottom:5px;border-right:solid 1px #000;border-left:solid 1px #000;border-bottom:solid 1px #000}.SettingsTable td.savebutton{border-right:solid 1px #000;border-left:solid 1px #000;border-bottom:solid 1px #000;background-color:#4d595d}.SettingsTable .cronbutton{text-align:center;min-width:50px;width:50px;height:23px;vertical-align:middle}.SettingsTable select{margin-left:3px!important}.SettingsTable label{margin-right:10px!important;vertical-align:top!important}.SettingsTable th{background-color:#1F2D35!important;background:#2F3A3E!important;border-bottom:none!important;border-top:none!important;font-size:12px!important;color:#fff!important;padding:4px!important;font-weight:bolder!important;padding:0!important}.SettingsTable th.sectionheader{padding-left:10px!important;border-right:solid 1px #000!important;border-left:solid 1px #000!important}.SettingsTable td{word-wrap:break-word!important;overflow-wrap:break-word!important;border-right:none;border-left:none}.SettingsTable span.settingname{background-color:#1F2D35!important;background:#2F3A3E!important}.SettingsTable td.settingname{border-right:solid 1px #000;border-left:solid 1px #000;background-color:#1F2D35!important;background:#2F3A3E!important;width:35%!important}.SettingsTable td.settingvalue{text-align:left!important;border-right:solid 1px #000}.SettingsTable th:first-child{border-left:none}.SettingsTable th:last-child{border-right:none}.SettingsTable .invalid{background-color:#8b0000!important}.SettingsTable .disabled{background-color:#CCC!important;color:#888!important}.removespacing{padding-left:0!important;margin-left:0!important;margin-bottom:5px!important;text-align:center!important}.usagehint{color:#FF0!important}div.vnstat{background-repeat:no-repeat!important;background-position:center!important}
</style>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/jquery.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/moment.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/chart.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/hammerjs.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/chartjs-plugin-zoom.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/chartjs-plugin-annotation.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/d3.js"></script>
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
			if(prop.indexOf('dnvnstat') != -1 && prop.indexOf('dnvnstat_version') == -1){
				eval('delete custom_settings.'+prop)
			}
		}
	}
}
var $j = jQuery.noConflict(); //avoid conflicts on John's fork (state.js)
var maxNoCharts = 9;
var currentNoCharts = 0;

var ShowLines = GetCookie('ShowLines','string');
var ShowFill = GetCookie('ShowFill','string');
if(ShowFill == ''){
	ShowFill = 'origin';
}

var DragZoom = true;
var ChartPan = false;

Chart.defaults.global.defaultFontColor = '#CCC';
Chart.Tooltip.positioners.cursor = function(chartElements,coordinates){
	return coordinates;
};

var dataintervallist = ['fiveminute','hour','day'];
var chartlist = ['daily','weekly','monthly'];
var timeunitlist = ['hour','day','day'];
var intervallist = [24,7,30];
var bordercolourlist= ['#fc8500','#42ecf5'];
var backgroundcolourlist = ['rgba(252,133,0,0.5)','rgba(66,236,245,0.5)'];

function keyHandler(e){
	if(e.keyCode == 82){
		$j(document).off('keydown');
		ResetZoom();
	}
	else if(e.keyCode == 68){
		$j(document).off('keydown');
		ToggleDragZoom(document.form.btnDragZoom);
	}
	else if(e.keyCode == 70){
		$j(document).off('keydown');
		ToggleFill();
	}
	else if(e.keyCode == 76){
		$j(document).off('keydown');
		ToggleLines();
	}
}

$j(document).keydown(function(e){keyHandler(e);});
$j(document).keyup(function(e){
	$j(document).keydown(function(e){
		keyHandler(e);
	});
});

function UsageHint(){
	var tag_name= document.getElementsByTagName('a');
	for(var i = 0; i<tag_name.length; i++){
		tag_name[i].onmouseout=nd;
	}
	hinttext=thresholdstring;
	return overlib(hinttext,0,0);
}

function Validate_AllowanceStartDay(forminput){
	var inputname = forminput.name;
	var inputvalue = forminput.value*1;
	
	if(inputvalue > 28 || inputvalue < 1){
		$j(forminput).addClass('invalid');
		return false;
	}
	else{
		$j(forminput).removeClass('invalid');
		return true;
	}
}

function Validate_DataAllowance(forminput){
	var inputname = forminput.name;
	var inputvalue = forminput.value*1;
	
	if(inputvalue < 0 || forminput.value.length == 0 || inputvalue == NaN || forminput.value == '.'){
		$j(forminput).addClass('invalid');
		return false;
	}
	else{
		$j(forminput).removeClass('invalid');
		return true;
	}
}

function Format_DataAllowance(forminput){
	var inputname = forminput.name;
	var inputvalue = forminput.value*1;
	
	if(inputvalue < 0 || forminput.value.length == 0 || inputvalue == NaN || forminput.value == '.'){
		return false;
	}
	else{
		forminput.value=parseFloat(forminput.value).toFixed(2);
		return true;
	}
}

function ScaleDataAllowance(){
	if(document.form.dnvnstat_allowanceunit.value == 'T'){
		document.form.dnvnstat_dataallowance.value = document.form.dnvnstat_dataallowance.value*1 / 1000;
	}
	else if(document.form.dnvnstat_allowanceunit.value == 'G'){
		document.form.dnvnstat_dataallowance.value = document.form.dnvnstat_dataallowance.value*1 * 1000;
	}
	Format_DataAllowance(document.form.dnvnstat_dataallowance);
}

function GetCookie(cookiename,returntype){
	if(cookie.get('cookie_'+cookiename) != null){
		return cookie.get('cookie_'+cookiename);
	}
	else{
		if(returntype == 'string'){
			return '';
		}
		else if(returntype == 'number'){
			return 0;
		}
	}
}

function SetCookie(cookiename,cookievalue){
	cookie.set('cookie_'+cookiename,cookievalue,10 * 365);
}

function ScriptUpdateLayout(){
	var localver = GetVersionNumber('local');
	var serverver = GetVersionNumber('server');
	$j('#dnvnstat_version_local').text(localver);
	
	if(localver != serverver && serverver != 'N/A'){
		$j('#dnvnstat_version_server').text('Updated version available: '+serverver);
		showhide('btnChkUpdate',false);
		showhide('dnvnstat_version_server',true);
		showhide('btnDoUpdate',true);
	}
}

function update_status(){
	$j.ajax({
		url: '/ext/dn-vnstat/detect_update.js',
		dataType: 'script',
		error: function(xhr){
			setTimeout(update_status,1000);
		},
		success: function(){
			if(updatestatus == 'InProgress'){
				setTimeout(update_status,1000);
			}
			else{
				document.getElementById('imgChkUpdate').style.display = 'none';
				showhide('dnvnstat_version_server',true);
				if(updatestatus != 'None'){
					$j('#dnvnstat_version_server').text('Updated version available: '+updatestatus);
					showhide('btnChkUpdate',false);
					showhide('btnDoUpdate',true);
				}
				else{
					$j('#dnvnstat_version_server').text('No update available');
					showhide('btnChkUpdate',true);
					showhide('btnDoUpdate',false);
				}
			}
		}
	});
}

function CheckUpdate(){
	showhide('btnChkUpdate',false);
	document.formScriptActions.action_script.value = 'start_dn-vnstatcheckupdate';
	document.formScriptActions.submit();
	document.getElementById('imgChkUpdate').style.display = '';
	setTimeout(update_status,2000);
}

function DoUpdate(){
	document.form.action_script.value = 'start_dn-vnstatdoupdate';
	document.form.action_wait.value = 15;
	showLoading();
	document.form.submit();
}

function GetVersionNumber(versiontype){
	var versionprop;
	if(versiontype == 'local'){
		versionprop = custom_settings.dnvnstat_version_local;
	}
	else if(versiontype == 'server'){
		versionprop = custom_settings.dnvnstat_version_server;
	}
	
	if(typeof versionprop == 'undefined' || versionprop == null){
		return 'N/A';
	}
	else{
		return versionprop;
	}
}

$j.fn.serializeObject = function(){
	var o = custom_settings;
	var a = this.serializeArray();
	$j.each(a,function(){
		if (o[this.name] !== undefined && this.name.indexOf('dnvnstat') != -1 && this.name.indexOf('version') == -1){
			if (!o[this.name].push){
				o[this.name] = [o[this.name]];
			}
			o[this.name].push(this.value || '');
		} else if (this.name.indexOf('dnvnstat') != -1 && this.name.indexOf('version') == -1){
			o[this.name] = this.value || '';
		}
	});
	return o;
};

function SaveConfig(){
	document.getElementById('amng_custom').value = JSON.stringify($j('form').serializeObject());
	document.form.action_script.value = 'start_dn-vnstatconfig';
	document.form.action_wait.value = 15;
	showLoading();
	document.form.submit();
}

function get_conf_file(){
	$j.ajax({
		url: '/ext/dn-vnstat/config.htm',
		dataType: 'text',
		error: function(xhr){
			setTimeout(get_conf_file,1000);
		},
		success: function(data){
			var configdata=data.split('\n');
			configdata = configdata.filter(Boolean);
			for (var i = 0; i < configdata.length; i++){
				eval('document.form.dnvnstat_'+configdata[i].split('=')[0].toLowerCase()).value = configdata[i].split('=')[1].replace(/(\r\n|\n|\r)/gm,'');
			}
			get_vnstatconf_file();
		}
	});
}

function get_vnstatconf_file(){
	$j.ajax({
		url: '/ext/dn-vnstat/vnstatconf.htm',
		dataType: 'text',
		error: function(xhr){
			setTimeout(get_vnstatconf_file,1000);
		},
		success: function(data){
			var configdata=data.split('\n');
			configdata = configdata.filter(Boolean);
			for (var i = 0; i < configdata.length; i++){
				if(configdata[i].startsWith('MonthRotate ')){
					eval('document.form.dnvnstat_'+configdata[i].split(' ')[0].toLowerCase()).value = configdata[i].split(' ')[1].replace(/(\r\n|\n|\r)/gm,'');
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
			setTimeout(loadVnStatOutput,5000);
		},
		success: function(data){
			document.getElementById('VnStatOuput').innerHTML=data;
		}
	});
}

function ShowHideDataUsageWarning(showusage){
	if(showusage){
		document.getElementById('datausagewarning').style.display = '';
		document.getElementById('scripttitle').style.marginLeft = '166px';
	}
	else{
		document.getElementById('datausagewarning').style.display = 'none';
		document.getElementById('scripttitle').style.marginLeft = '0px';
	}
}

function UpdateText(){
	$j('#statstitle').html('The statistics and graphs on this page were last refreshed at: '+daterefeshed);
	$j('#spandatausage').html(usagestring);
	ShowHideDataUsageWarning(usagethreshold);
}

function UpdateImages(){
	var images=['s','h','d','t','m'];
	var datestring = new Date().getTime();
	for(var index = 0; index < images.length; index++){
		document.getElementById('img_'+images[index]).style.backgroundImage='url(/ext/dn-vnstat/images/.vnstat_'+images[index]+'.htm?cachebuster='+datestring+')';
	}
}

function UpdateStats(){
	showhide('btnUpdateStats',false);
	document.formScriptActions.action_script.value='start_dn-vnstat';
	document.formScriptActions.submit();
	document.getElementById('vnstatupdate_text').innerHTML = 'Updating bandwidth usage and vnstat data...';
	showhide('imgVnStatUpdate',true);
	showhide('vnstatupdate_text',true);
	setTimeout(update_vnstat,2000);
}

function update_vnstat(){
	$j.ajax({
		url: '/ext/dn-vnstat/detect_vnstat.js',
		dataType: 'script',
		error: function(xhr){
			setTimeout(update_vnstat,1000);
		},
		success: function(){
			if(vnstatstatus == 'InProgress'){
				setTimeout(update_vnstat,1000);
			}
			else if(vnstatstatus == 'Done'){
				reload_js('/ext/dn-vnstat/vnstatusage.js');
				UpdateText();
				UpdateImages();
				loadVnStatOutput();
				document.getElementById('vnstatupdate_text').innerHTML = '';
				showhide('imgVnStatUpdate',false);
				showhide('vnstatupdate_text',false);
				showhide('btnUpdateStats',true);
			}
		}
	});
}

function reload_js(src){
	$j('script[src="'+src+'"]').remove();
	$j('<script>').attr('src',src+'?cachebuster='+ new Date().getTime()).appendTo('head');
}

function AddEventHandlers(){
	$j('.collapsible-jquery').off('click').on('click',function(){
		$j(this).siblings().toggle('fast',function(){
			if($j(this).css('display') == 'none'){
				SetCookie($j(this).siblings()[0].id,'collapsed');
			}
			else{
				SetCookie($j(this).siblings()[0].id,'expanded');
			}
		})
	});
	
	$j('.collapsible-jquery').each(function(index,element){
		if(GetCookie($j(this)[0].id,'string') == 'collapsed'){
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
	$j('#Time_Format').val(GetCookie('Time_Format','number'));
	RedrawAllCharts();
}

function reload(){
	location.reload(true);
}

function Draw_Chart_NoData(txtchartname,texttodisplay){
	document.getElementById('divLineChart_'+txtchartname).width='730';
	document.getElementById('divLineChart_'+txtchartname).height='500';
	document.getElementById('divLineChart_'+txtchartname).style.width='730px';
	document.getElementById('divLineChart_'+txtchartname).style.height='500px';
	var ctx = document.getElementById('divLineChart_'+txtchartname).getContext('2d');
	ctx.save();
	ctx.textAlign = 'center';
	ctx.textBaseline = 'middle';
	ctx.font = 'normal normal bolder 48px Arial';
	ctx.fillStyle = 'white';
	ctx.fillText(texttodisplay,365,250);
	ctx.restore();
}

function Draw_Chart(txtchartname){
	var txtunity = $j('#'+txtchartname+'_Unit option:selected').text();
	var txttitle = 'Data Usage';
	var metric0 = 'Received';
	var metric1 = 'Sent';
	
	var decimals = 2;
	if(txtunity == 'B' || txtunity == 'KB'){
		decimals = 0;
	}
	
	var chartperiod = getChartPeriod($j('#'+txtchartname+'_Period option:selected').val());
	var chartinterval = getChartInterval($j('#'+txtchartname+'_Interval option:selected').val());
	var chartunitmultiplier = getChartUnitMultiplier($j('#'+txtchartname+'_Unit option:selected').val());
	var txtunitx = timeunitlist[$j('#'+txtchartname+'_Period option:selected').val()];
	var numunitx = intervallist[$j('#'+txtchartname+'_Period option:selected').val()];
	var zoompanxaxismax = moment();
	var chartxaxismax = null;
	var chartxaxismin = moment().subtract(numunitx,txtunitx+'s');
	var charttype = 'bar';
	var dataobject = window[txtchartname+'_'+chartinterval+'_'+chartperiod];
	if(typeof dataobject === 'undefined' || dataobject === null){ Draw_Chart_NoData(txtchartname,'No data to display'); return; }
	if(dataobject.length == 0){ Draw_Chart_NoData(txtchartname,'No data to display'); return; }
	
	var unique = [];
	var chartTrafficTypes = [];
	for( let i = 0; i < dataobject.length; i++){
		if(!unique[dataobject[i].Metric]){
			chartTrafficTypes.push(dataobject[i].Metric);
			unique[dataobject[i].Metric] = 1;
		}
	}
	
	var chartData0 = dataobject.filter(function(item){
		return item.Metric == metric0;
	}).map(function(d){return {x: d.Time,y: (d.Value/chartunitmultiplier)}});
	
	var chartData1 = dataobject.filter(function(item){
		return item.Metric == metric1;
	}).map(function(d){return {x: d.Time,y: (d.Value/chartunitmultiplier)}});
	
	var objchartname=window['LineChart_'+txtchartname];
	
	var timeaxisformat = getTimeFormat($j('#Time_Format option:selected').val(),'axis');
	var timetooltipformat = getTimeFormat($j('#Time_Format option:selected').val(),'tooltip');
	
	if(chartinterval == 'fiveminute'){
		charttype = 'line';
	}
	
	if(chartinterval == 'hour'){
		chartxaxismax = moment().startOf('hour').add(1,'hours');
		zoompanxaxismax = chartxaxismax;
	}
	
	if(chartinterval == 'day'){
		chartxaxismax = moment().endOf('day').subtract(9,'hours');
		chartxaxismin = moment().startOf('day').subtract(numunitx-1,txtunitx+'s').subtract(12,'hours');
		zoompanxaxismax = chartxaxismax;
	}

	if(chartperiod == 'daily' && chartinterval == 'day'){
		txtunitx = 'day';
		numunitx = 1;
		chartxaxismax = moment().endOf('day').subtract(9,'hours');
		chartxaxismin = moment().startOf('day').subtract(12,'hours');
		zoompanxaxismax = chartxaxismax;
	}
	
	factor=0;
	if(txtunitx=='hour'){
		factor=60*60*1000;
	}
	else if(txtunitx=='day'){
		factor=60*60*24*1000;
	}
	if(objchartname != undefined) objchartname.destroy();
	var ctx = document.getElementById('divLineChart_'+txtchartname).getContext('2d');
	var lineOptions = {
		segmentShowStroke : false,
		segmentStrokeColor : '#000',
		animationEasing : 'easeOutQuart',
		animationSteps : 100,
		maintainAspectRatio: false,
		animateScale : true,
		hover: { mode: 'point' },
		legend: {
			display: true,
			position: 'top',
			reverse: false,
			onClick: function (e,legendItem){
				var index = legendItem.datasetIndex;
				var ci = this.chart;
				var meta = ci.getDatasetMeta(index);
				
				meta.hidden = meta.hidden === null ? !ci.data.datasets[index].hidden : null;
				
				if(ShowLines == 'line'){
					var annotationline = '';
					if(meta.hidden != true){
						annotationline = 'line';
					}
					
					if(ci.data.datasets[index].label == 'Received'){
						for(aindex = 0; aindex < 3; aindex++){
							ci.options.annotation.annotations[aindex].type=annotationline;
						}
					}
					else if(ci.data.datasets[index].label == 'Sent'){
						for(aindex = 3; aindex < 6; aindex++){
							ci.options.annotation.annotations[aindex].type=annotationline;
						}
					}
				}
				
				ci.update();
			}
		},
		title: { display: true,text: txttitle },
		tooltips: {
			callbacks: {
					title: function (tooltipItem,data){
						if(chartinterval == 'day'){
							return moment(tooltipItem[0].xLabel,'X').format('YYYY-MM-DD');
						}
						else{
							return moment(tooltipItem[0].xLabel,'X').format(timetooltipformat);
						}
					},
					label: function (tooltipItem,data){var txtunitytip=txtunity;return round(data.datasets[tooltipItem.datasetIndex].data[tooltipItem.index].y,decimals).toFixed(decimals)+' '+txtunitytip;}
				},
			itemSort: function(a,b){
				return b.datasetIndex - a.datasetIndex;
			},
			mode: 'point',
			position: 'cursor',
			intersect: true
		},
		scales: {
			xAxes: [{
				type: 'time',
				gridLines: { display: true,color: '#282828' },
				ticks: {
					min: chartxaxismin,
					max: chartxaxismax,
					display: true
				},
				time: {
					parser: 'X',
					unit: txtunitx,
					stepSize: 1,
					displayFormats: timeaxisformat
				}
			}],
			yAxes: [{
				type: getChartScale($j('#'+txtchartname+'_Scale option:selected').val()),
				gridLines: { display: false,color: '#282828' },
				scaleLabel: { display: false,labelString: txtunity },
				id: 'left-y-axis',
				position: 'left',
				ticks: {
					display: true,
					beginAtZero: true,
					labels: {
						index:  ['min','max'],
						removeEmptyLines: true,
					},
					userCallback: LogarithmicFormatter
				},
			}]
		},
		plugins: {
			zoom: {
				pan: {
					enabled: ChartPan,
					mode: 'xy',
					rangeMin: {
						x: chartxaxismin,
						y: 0
					},
					rangeMax: {
						x: zoompanxaxismax//,
						//y: getLimit(chartData,'y','max',false)+getLimit(chartData,'y','max',false)*0.1
					},
				},
				zoom: {
					enabled: true,
					drag: DragZoom,
					mode: 'xy',
					rangeMin: {
						x: chartxaxismin,
						y: 0
					},
					rangeMax: {
						x: zoompanxaxismax//,
						//y: getLimit(chartData,'y','max',false)+getLimit(chartData,'y','max',false)*0.1
					},
					speed: 0.1
				},
			},
		},
		annotation: {
			drawTime: 'afterDatasetsDraw',
			annotations: [{
				//id: 'avgline',
				type: ShowLines,
				mode: 'horizontal',
				scaleID: 'left-y-axis',
				value: getAverage(chartData0),
				borderColor: bordercolourlist[0],
				borderWidth: 1,
				borderDash: [5,5],
				label: {
					backgroundColor: 'rgba(0,0,0,0.3)',
					fontFamily: 'sans-serif',
					fontSize: 10,
					fontStyle: 'bold',
					fontColor: '#fff',
					xPadding: 6,
					yPadding: 6,
					cornerRadius: 6,
					position: 'center',
					enabled: true,
					xAdjust: 0,
					yAdjust: 0,
					content: 'Avg. '+metric0+'='+round(getAverage(chartData0),decimals).toFixed(decimals)+txtunity,
				}
			},
			{
				//id: 'maxline',
				type: ShowLines,
				mode: 'horizontal',
				scaleID: 'left-y-axis',
				value: getLimit(chartData0,'y','max',true),
				borderColor: bordercolourlist[0],
				borderWidth: 1,
				borderDash: [5,5],
				label: {
					backgroundColor: 'rgba(0,0,0,0.3)',
					fontFamily: 'sans-serif',
					fontSize: 10,
					fontStyle: 'bold',
					fontColor: '#fff',
					xPadding: 6,
					yPadding: 6,
					cornerRadius: 6,
					position: 'right',
					enabled: true,
					xAdjust: 15,
					yAdjust: 0,
					content: 'Max. '+metric0+'='+round(getLimit(chartData0,'y','max',true),decimals).toFixed(decimals)+txtunity,
				}
			},
			{
				//id: 'minline',
				type: ShowLines,
				mode: 'horizontal',
				scaleID: 'left-y-axis',
				value: getLimit(chartData0,'y','min',true),
				borderColor: bordercolourlist[0],
				borderWidth: 1,
				borderDash: [5,5],
				label: {
					backgroundColor: 'rgba(0,0,0,0.3)',
					fontFamily: 'sans-serif',
					fontSize: 10,
					fontStyle: 'bold',
					fontColor: '#fff',
					xPadding: 6,
					yPadding: 6,
					cornerRadius: 6,
					position: 'left',
					enabled: true,
					xAdjust: 15,
					yAdjust: 0,
					content: 'Min. '+metric0+'='+round(getLimit(chartData0,'y','min',true),decimals).toFixed(decimals)+txtunity,
				}
			},
			{
				//id: 'avgline',
				type: ShowLines,
				mode: 'horizontal',
				scaleID: 'left-y-axis',
				value: getAverage(chartData1),
				borderColor: bordercolourlist[1],
				borderWidth: 1,
				borderDash: [5,5],
				label: {
					backgroundColor: 'rgba(0,0,0,0.3)',
					fontFamily: 'sans-serif',
					fontSize: 10,
					fontStyle: 'bold',
					fontColor: '#fff',
					xPadding: 6,
					yPadding: 6,
					cornerRadius: 6,
					position: 'center',
					enabled: true,
					xAdjust: 0,
					yAdjust: 0,
					content: 'Avg. '+metric1+'='+round(getAverage(chartData1),decimals).toFixed(decimals)+txtunity,
				}
			},
			{
				//id: 'maxline',
				type: ShowLines,
				mode: 'horizontal',
				scaleID: 'left-y-axis',
				value: getLimit(chartData1,'y','max',true),
				borderColor: bordercolourlist[1],
				borderWidth: 1,
				borderDash: [5,5],
				label: {
					backgroundColor: 'rgba(0,0,0,0.3)',
					fontFamily: 'sans-serif',
					fontSize: 10,
					fontStyle: 'bold',
					fontColor: '#fff',
					xPadding: 6,
					yPadding: 6,
					cornerRadius: 6,
					position: 'right',
					enabled: true,
					xAdjust: 15,
					yAdjust: 0,
					content: 'Max. '+metric1+'='+round(getLimit(chartData1,'y','max',true),decimals).toFixed(decimals)+txtunity,
				}
			},
			{
				//id: 'minline',
				type: ShowLines,
				mode: 'horizontal',
				scaleID: 'left-y-axis',
				value: getLimit(chartData1,'y','min',true),
				borderColor: bordercolourlist[1],
				borderWidth: 1,
				borderDash: [5,5],
				label: {
					backgroundColor: 'rgba(0,0,0,0.3)',
					fontFamily: 'sans-serif',
					fontSize: 10,
					fontStyle: 'bold',
					fontColor: '#fff',
					xPadding: 6,
					yPadding: 6,
					cornerRadius: 6,
					position: 'left',
					enabled: true,
					xAdjust: 15,
					yAdjust: 0,
					content: 'Min. '+metric1+'='+round(getLimit(chartData1,'y','min',true),decimals).toFixed(decimals)+txtunity,
				}
			}
		]}
	};
	var lineDataset = {
		datasets: getDataSets(dataobject,chartTrafficTypes,chartunitmultiplier)
	};
	objchartname = new Chart(ctx,{
		type: charttype,
		options: lineOptions,
		data: lineDataset
	});
	window['LineChart_'+txtchartname]=objchartname;
}

function LogarithmicFormatter(tickValue,index,ticks){
	var unit = this.options.scaleLabel.labelString;
	var decimals = 2;
	if(unit == 'B' || unit == 'KB'){
		decimals = 0;
	}
	if(this.type != 'logarithmic'){
		if(! isNaN(tickValue)){
			return round(tickValue,decimals).toFixed(decimals)+' '+unit;
		}
		else{
			return tickValue+' '+unit;
		}
	}
	else{
		var labelOpts =  this.options.ticks.labels || {};
		var labelIndex = labelOpts.index || ['min','max'];
		var labelSignificand = labelOpts.significand || [1,2,5];
		var significand = tickValue / (Math.pow(10,Math.floor(Chart.helpers.log10(tickValue))));
		var emptyTick = labelOpts.removeEmptyLines === true ? undefined : '';
		var namedIndex = '';
		if(index === 0){
			namedIndex = 'min';
		}
		else if(index === ticks.length - 1){
			namedIndex = 'max';
		}
		if(labelOpts === 'all' || labelSignificand.indexOf(significand) !== -1 || labelIndex.indexOf(index) !== -1 || labelIndex.indexOf(namedIndex) !== -1){
			if(tickValue === 0){
				return '0'+' '+unit;
			}
			else{
				if(! isNaN(tickValue)){
					return round(tickValue,decimals).toFixed(decimals)+' '+unit;
				}
				else{
					return tickValue+' '+unit;
				}
			}
		}
		return emptyTick;
	}
};

function getDataSets(objdata,objTrafficTypes,chartunitmultiplier){
	var datasets = [];
	
	for(var i = 0; i < objTrafficTypes.length; i++){
		var traffictypedata = objdata.filter(function(item){
			return item.Metric == objTrafficTypes[i];
		}).map(function(d){return {x: d.Time,y: (d.Value/chartunitmultiplier)}});
		
		datasets.push({ label: objTrafficTypes[i],data: traffictypedata,yAxisID: 'left-y-axis',borderWidth: 1,pointRadius: 1,lineTension: 0,fill: ShowFill,backgroundColor: backgroundcolourlist[i],borderColor: bordercolourlist[i]});
	}
	return datasets;
}

function getLimit(datasetname,axis,maxmin,isannotation){
	var limit = 0;
	var values;
	if(axis == 'x'){
		values = datasetname.map(function(o){ return o.x } );
	}
	else{
		values = datasetname.map(function(o){ return o.y } );
	}
	
	if(maxmin == 'max'){
		limit=Math.max.apply(Math,values);
	}
	else{
		limit=Math.min.apply(Math,values);
	}
	if(maxmin == 'max' && limit == 0 && isannotation == false){
		limit = 1;
	}
	return limit;
}

function getAverage(datasetname){
	var total = 0;
	for(var i = 0; i < datasetname.length; i++){
		total += (datasetname[i].y*1);
	}
	var avg = total / datasetname.length;
	return avg;
}

function round(value,decimals){
	return Number(Math.round(value+'e'+decimals)+'e-'+decimals);
}

function ToggleLines(){
	if(ShowLines == ''){
		ShowLines = 'line';
		SetCookie('ShowLines','line');
	}
	else{
		ShowLines = '';
		SetCookie('ShowLines','');
	}
	
	var chartobj = window['LineChart_DataUsage'];
	if(typeof chartobj === 'undefined' || chartobj === null){ return; }
	var maxlines = 6;
	for(var i = 0; i < maxlines; i++){
		chartobj.options.annotation.annotations[i].type=ShowLines;
	}
	chartobj.update();
}

function ToggleFill(){
	if(ShowFill == 'origin'){
		ShowFill = 'false';
		SetCookie('ShowFill','false');
	}
	else{
		ShowFill = 'origin';
		SetCookie('ShowFill','origin');
	}
	
	var chartobj = window['LineChart_DataUsage'];
	if(typeof chartobj === 'undefined' || chartobj === null){ return; }
	chartobj.data.datasets[0].fill=ShowFill;
	chartobj.data.datasets[1].fill=ShowFill;
	chartobj.update();
}

function RedrawAllCharts(){
	$j('#DataUsage_Interval').val(GetCookie('DataUsage_Interval','number'));
	changePeriod(document.getElementById('DataUsage_Interval'));
	$j('#DataUsage_Period').val(GetCookie('DataUsage_Period','number'));
	$j('#DataUsage_Unit').val(GetCookie('DataUsage_Unit','number'));
	$j('#DataUsage_Scale').val(GetCookie('DataUsage_Scale','number'));
	Draw_Chart_NoData(metriclist[i]);
	for(var i = 0; i < chartlist.length; i++){
		for(var i2 = 0; i2 < dataintervallist.length; i2++){
			d3.csv('/ext/dn-vnstat/csv/DataUsage_'+dataintervallist[i2]+'_'+chartlist[i]+'.htm').then(SetGlobalDataset.bind(null,'DataUsage_'+dataintervallist[i2]+'_'+chartlist[i]));
		}
	}
}

function SetGlobalDataset(txtchartname,dataobject){
	window[txtchartname] = dataobject;
	currentNoCharts++;
	if(currentNoCharts == maxNoCharts){
		Draw_Chart('DataUsage');
	}
}

function getTimeFormat(value,format){
	var timeformat;
	
	if(format == 'axis'){
		if(value == 0){
			timeformat = {
				millisecond: 'HH:mm:ss.SSS',
				second: 'HH:mm:ss',
				minute: 'HH:mm',
				hour: 'HH:mm'
			}
		}
		else if(value == 1){
			timeformat = {
				millisecond: 'h:mm:ss.SSS A',
				second: 'h:mm:ss A',
				minute: 'h:mm A',
				hour: 'h A'
			}
		}
	}
	else if(format == 'tooltip'){
		if(value == 0){
			timeformat = 'YYYY-MM-DD HH:mm:ss';
		}
		else if(value == 1){
			timeformat = 'YYYY-MM-DD h:mm:ss A';
		}
	}
	
	return timeformat;
}

function getChartPeriod(period){
	var chartperiod = 'daily';
	if(period == 0) chartperiod = 'daily';
	else if(period == 1) chartperiod = 'weekly';
	else if(period == 2) chartperiod = 'monthly';
	return chartperiod;
}

function getChartUnitMultiplier(period){
	return Math.pow(1000,period);
}

function getChartScale(scale){
	var chartscale = '';
	if(scale == 0){
		chartscale = 'linear';
	}
	else if(scale == 1){
		chartscale = 'logarithmic';
	}
	return chartscale;
}

function getChartInterval(layout){
	var charttype = 'fiveminute';
	if(layout == 0) charttype = 'fiveminute';
	else if(layout == 1) charttype = 'hour';
	else if(layout == 2) charttype = 'day';
	return charttype;
}

function ResetZoom(){
	var chartobj = window['LineChart_DataUsage'];
	if(typeof chartobj === 'undefined' || chartobj === null){ return; }
	chartobj.resetZoom();
}

function ToggleDragZoom(button){
	var drag = true;
	var pan = false;
	var buttonvalue = '';
	if(button.value.indexOf('On') != -1){
		drag = false;
		pan = true;
		DragZoom = false;
		ChartPan = true;
		buttonvalue = 'Drag Zoom Off';
	}
	else{
		drag = true;
		pan = false;
		DragZoom = true;
		ChartPan = false;
		buttonvalue = 'Drag Zoom On';
	}
	
	var chartobj = window['LineChart_DataUsage'];
	if(typeof chartobj === 'undefined' || chartobj === null){ return; }
	chartobj.options.plugins.zoom.zoom.drag = drag;
	chartobj.options.plugins.zoom.pan.enabled = pan;
	chartobj.update();
	button.value = buttonvalue;
}

function changeAllCharts(e){
	value = e.value * 1;
	SetCookie(e.id,value);
	Draw_Chart('DataUsage');
}

function changeChart(e){
	value = e.value * 1;
	name = e.id.substring(0,e.id.lastIndexOf('_'));
	SetCookie(e.id,value);
	Draw_Chart(name);
}

function changePeriod(e){
	value = e.value * 1;
	name = e.id.substring(0,e.id.indexOf('_'));
	if(value == 2){
		$j('select[id="'+name+'_Period"] option:contains(24)').text('Today');
	}
	else{
		$j('select[id="'+name+'_Period"] option:contains("Today")').text('Last 24 hours');
	}
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
<table width="100%" border="1" align="center" cellpadding="2" cellspacing="0" bordercolor="#6b8fa3" class="FormTable SettingsTable" style="border:0px;" id="table_config">
<thead class="collapsible-jquery" id="scriptconfig">
<tr><td colspan="2">Configuration (click to expand/collapse)</td></tr>
</thead>
<tr class="even" id="rowenabledailyemail">
<td class="settingname">Enable daily summary emails</td>
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
<td class="settingname">Enable data usage warning emails</td>
<td class="settingvalue">
<input type="radio" name="dnvnstat_usageemail" id="dnvnstat_usageemail_true" class="input" value="true">
<label for="dnvnstat_usageemail_true" class="settingvalue">Enabled</label>
<input type="radio" name="dnvnstat_usageemail" id="dnvnstat_usageemail_false" class="input" value="false" checked>
<label for="dnvnstat_usageemail_false" class="settingvalue">Disabled</label>
</td>
</tr>
<tr class="even" id="rowdataallowance">
<td class="settingname">Bandwidth allowance for data usage warnings
<br />
<a href="https://github.com/de-vnull/vnstat-on-merlin/blob/main/more-info.md#Data-limits" target="_blank" style="color:#FFCC00;">More info</a>
</td>
<td class="settingvalue">
<input autocomplete="off" type="text" maxlength="8" class="input_12_table removespacing" name="dnvnstat_dataallowance" value="1200.00" onkeypress="return validator.isNumberFloat(this, event)" onkeyup="Validate_DataAllowance(this)" onblur="Validate_DataAllowance(this);Format_DataAllowance(this)" />
&nbsp;<span id="spandefaultallowance" style="color:#FFCC00;">(0: unlimited)</span>
</td>
</tr>
<tr class="even" id="rowallowanceunit">
<td class="settingname">Unit for bandwidth allowance</td>
<td class="settingvalue">
<input type="radio" name="dnvnstat_allowanceunit" id="dnvnstat_allowanceunit_g" class="input" value="G" onchange="ScaleDataAllowance();" checked>
<label for="dnvnstat_allowanceunit_g" id="label_allowanceunit_g">GB</label>
<input type="radio" name="dnvnstat_allowanceunit" id="dnvnstat_allowanceunit_t" class="input" value="T" onchange="ScaleDataAllowance();">
<label for="dnvnstat_allowanceunit_t" id="label_allowanceunit_t">TB</label>
</td>
</tr>
<tr class="even" id="rowmonthrotate">
<td class="settingname">Start day for bandwidth allowance cycle<br />
<a href="https://github.com/de-vnull/vnstat-on-merlin/blob/main/more-info.md#MonthRotate" target="_blank" style="color:#FFCC00;">More info</a>
</td>
<td class="settingvalue">Day&nbsp;
<input autocomplete="off" type="text" maxlength="2" class="input_3_table removespacing" name="dnvnstat_monthrotate" value="1" onkeypress="return validator.isNumber(this, event)" onkeyup="Validate_AllowanceStartDay(this)" onblur="Validate_AllowanceStartDay(this)" />
&nbsp;of month&nbsp;<span style="color:#FFCC00;">(between 1 and 28, default: 1)</span>
</td>
</tr>
<tr class="even" id="rowtimeoutput">
<td class="settingname">Time Output Mode<br/><span style="color:#FFCC00;background:#2F3A3E;">(for CSV export)</span></td>
<td class="settingvalue">
<input type="radio" name="dnvnstat_outputtimemode" id="dnvnstat_timeoutput_non-unix" class="input" value="non-unix" checked>
<label for="dnvnstat_timeoutput_non-unix">Non-Unix</label>
<input type="radio" name="dnvnstat_outputtimemode" id="dnvnstat_timeoutput_unix" class="input" value="unix">
<label for="dnvnstat_timeoutput_unix">Unix</label>
</td>
</tr>
<tr class="even" id="rowstorageloc">
<td class="settingname">Data Storage Location</td>
<td class="settingvalue">
<input type="radio" name="dnvnstat_storagelocation" id="dnvnstat_storageloc_jffs" class="input" value="jffs" checked>
<label for="dnvnstat_storageloc_jffs">JFFS</label>
<input type="radio" name="dnvnstat_storagelocation" id="dnvnstat_storageloc_usb" class="input" value="usb">
<label for="dnvnstat_storageloc_usb">USB</label>
</td>
</tr>
<tr class="apply_gen" valign="top" height="35px">
<td class="savebutton" colspan="2" style="background-color:rgb(77, 89, 93);">
<input type="button" onclick="SaveConfig();" value="Save" class="button_gen savebutton" name="button">
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
<td><span id="spandatausage" style="color:#FFFFFF;"></span></td>
</tr>
<tr>
<td colspan="2" align="center" style="padding: 0px;">
<div id="img_m" class="vnstat" style="background-image:url('/ext/dn-vnstat/images/.vnstat_m.htm');">
<img style="visibility:hidden;" src="/ext/dn-vnstat/images/vnstat_m.png" alt="Monthly"/>
</div>
</td>
</tr>
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
<div style="line-height:10px;">&nbsp;</div>
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" style="border:0px;" id="table_buttons2">
<thead class="collapsible-jquery" id="charttools">
<tr><td colspan="2">Chart Display Options (click to expand/collapse)</td></tr>
</thead>
<tr>
<th width="20%"><span style="color:#FFFFFF;background:#2F3A3E;">Time format</span><br /><span style="color:#FFCC00;background:#2F3A3E;">(for tooltips and Last 24h chart axis)</span></th>
<td>
<select style="width:100px" class="input_option" onchange="changeAllCharts(this)" id="Time_Format">
<option value="0">24h</option>
<option value="1">12h</option>
</select>
</td>
</tr>
<tr class="apply_gen" valign="top">
<td colspan="2" style="background-color:rgb(77, 89, 93);">
<input type="button" onclick="ToggleDragZoom(this);" value="Drag Zoom On" class="button_gen" name="btnDragZoom">
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<input type="button" onclick="ResetZoom();" value="Reset Zoom" class="button_gen" name="btnResetZoom">
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<input type="button" onclick="ToggleLines();" value="Toggle Lines" class="button_gen" name="btnToggleLines">
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<input type="button" onclick="ToggleFill();" value="Toggle Fill" class="button_gen" name="btnToggleFill">
</td>
</tr>
</table>
<div style="line-height:10px;">&nbsp;</div>
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
<thead class="collapsible-jquery" id="chart_DataUsage">
<tr>
<td colspan="2">Data Usage (click to expand/collapse)</td>
</tr>
</thead>
<tr class="even">
<th width="40%">Data interval</th>
<td>
<select style="width:150px" class="input_option" onchange="changeChart(this);changePeriod(this);" id="DataUsage_Interval">
<option value="0">5 minutes</option>
<option value="1">Hours</option>
<option value="2">Days</option>
</select>
</td>
</tr>
<tr class="even">
<th width="40%">Period to display</th>
<td>
<select style="width:150px" class="input_option" onchange="changeChart(this)" id="DataUsage_Period">
<option value="0">Last 24 hours</option>
<option value="1">Last 7 days</option>
<option value="2">Last 30 days</option>
</select>
</td>
</tr>
<tr class="even">
<th width="40%">Unit for data usage</th>
<td>
<select style="width:150px" class="input_option" onchange="changeChart(this)" id="DataUsage_Unit">
<option value="0">B</option>
<option value="1">KB</option>
<option value="2">MB</option>
<option value="3">GB</option>
<option value="4">TB</option>
</select>
</td>
</tr>
<tr class="even">
<th width="40%">Scale type</th>
<td>
<select style="width:150px" class="input_option" onchange="changeChart(this)" id="DataUsage_Scale">
<option value="0">Linear</option>
<option value="1">Logarithmic</option>
</select>
</td>
</tr>
<tr>
<td colspan="2" align="center" style="padding: 0px;">
<div style="background-color:#2f3e44;border-radius:10px;width:730px;height:500px;padding-left:5px;"><canvas id="divLineChart_DataUsage" height="500" /></div>
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
