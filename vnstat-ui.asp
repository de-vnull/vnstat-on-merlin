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
<script language="JavaScript" type="text/javascript" src="/js/jquery.js"></script>
<script language="JavaScript" type="text/javascript" src="/js/httpApi.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/moment.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/chart.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/hammerjs.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/chartjs-plugin-zoom.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/chartjs-plugin-annotation.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/chartjs-plugin-trendline.js"></script>
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
<script>

/**----------------------------------------**/
/** Modified by Martinski W. [2024-Sep-22] **/
/**----------------------------------------**/

var custom_settings;
function LoadCustomSettings()
{
	custom_settings = <% get_custom_settings(); %>;
	for (var prop in custom_settings){
		if(Object.prototype.hasOwnProperty.call(custom_settings, prop)){
			if(prop.indexOf('dnvnstat') !== -1 && prop.indexOf('dnvnstat_version') === -1){
				eval('delete custom_settings.'+prop)
			}
		}
	}
}

var maxNoCharts=12,currentNoCharts=0,ShowTrendlines=GetCookie("ShowTrendlines","string");""==ShowTrendlines&&(ShowTrendlines="0");var ShowLines=GetCookie("ShowLines","string"),ShowFill=GetCookie("ShowFill","string");""==ShowFill&&(ShowFill="origin");var DragZoom=!0,ChartPan=!1;Chart.defaults.global.defaultFontColor="#CCC",Chart.Tooltip.positioners.cursor=function(e,t){return t};var dataintervallist=["fiveminute","hour","day"],chartlist=["daily","weekly","monthly"],timeunitlist=["hour","day","day"],intervallist=[24,7,30],bordercolourlist=["#c5c5ce","#0ec009","#956222","#38959d"],backgroundcolourlist=["rgba(197,197,206,0.5)","rgba(14,192,9,0.5)","rgba(149,98,34,0.5)","rgba(56,149,157,0.5)"],trendcolourlist=["rgba(197,197,206,"+ShowTrendlines+")","rgba(14,192,9,"+ShowTrendlines+")","rgba(149,98,34,"+ShowTrendlines+")","rgba(56,149,157,"+ShowTrendlines+")"],chartobjlist=["Chart_DataUsage","Chart_CompareUsage"];function keyHandler(e){82==e.keyCode?($(document).off("keydown"),ResetZoom()):68==e.keyCode?($(document).off("keydown"),ToggleDragZoom(document.form.btnDragZoom)):70==e.keyCode?($(document).off("keydown"),ToggleFill()):76==e.keyCode&&($(document).off("keydown"),ToggleLines())}function UsageHint(){for(var e=document.getElementsByTagName("a"),t=0;t<e.length;t++)e[t].onmouseout=nd;return hinttext=thresholdstring,overlib(hinttext,0,0)}function Validate_AllowanceStartDay(e){e.name;var t=1*e.value;return t>28||t<1?($(e).addClass("invalid"),!1):($(e).removeClass("invalid"),!0)}function Validate_DataAllowance(e){e.name;var t=1*e.value;return t<0||0==e.value.length||NaN==t||"."==e.value?($(e).addClass("invalid"),!1):($(e).removeClass("invalid"),!0)}function Format_DataAllowance(e){e.name;var t=1*e.value;return!(t<0||0==e.value.length||NaN==t||"."==e.value)&&(e.value=parseFloat(e.value).toFixed(2),!0)}function ScaleDataAllowance(){"T"==document.form.dnvnstat_allowanceunit.value?document.form.dnvnstat_dataallowance.value=1*document.form.dnvnstat_dataallowance.value/1e3:"G"==document.form.dnvnstat_allowanceunit.value&&(document.form.dnvnstat_dataallowance.value=1*document.form.dnvnstat_dataallowance.value*1e3),Format_DataAllowance(document.form.dnvnstat_dataallowance)}function GetCookie(e,t){return null!=cookie.get("cookie_"+e)?cookie.get("cookie_"+e):"string"==t?"":"number"==t?0:void 0}function SetCookie(e,t){cookie.set("cookie_"+e,t,3650)}function ScriptUpdateLayout(){var e=GetVersionNumber("local"),t=GetVersionNumber("server");$("#dnvnstat_version_local").text(e),e!=t&&"N/A"!=t&&($("#dnvnstat_version_server").text("Updated version available: "+t),showhide("btnChkUpdate",!1),showhide("dnvnstat_version_server",!0),showhide("btnDoUpdate",!0))}function update_status(){$.ajax({url:"/ext/dn-vnstat/detect_update.js",dataType:"script",error:function(e){setTimeout(update_status,1e3)},success:function(){"InProgress"==updatestatus?setTimeout(update_status,1e3):(document.getElementById("imgChkUpdate").style.display="none",showhide("dnvnstat_version_server",!0),"None"!=updatestatus?($("#dnvnstat_version_server").text("Updated version available: "+updatestatus),showhide("btnChkUpdate",!1),showhide("btnDoUpdate",!0)):($("#dnvnstat_version_server").text("No update available"),showhide("btnChkUpdate",!0),showhide("btnDoUpdate",!1)))}})}function CheckUpdate(){showhide("btnChkUpdate",!1),document.formScriptActions.action_script.value="start_dn-vnstatcheckupdate",document.formScriptActions.submit(),document.getElementById("imgChkUpdate").style.display="",setTimeout(update_status,2e3)}function DoUpdate(){document.form.action_script.value="start_dn-vnstatdoupdate",document.form.action_wait.value=15,showLoading(),document.form.submit()}function GetVersionNumber(e){var t;return"local"==e?t=custom_settings.dnvnstat_version_local:"server"==e&&(t=custom_settings.dnvnstat_version_server),void 0===t||null==t?"N/A":t}function SaveConfig(){document.getElementById("amng_custom").value=JSON.stringify($("form").serializeObject()),document.form.action_script.value="start_dn-vnstatconfig",document.form.action_wait.value=15,showLoading(),document.form.submit()}function get_conf_file(){$.ajax({url:"/ext/dn-vnstat/config.htm",dataType:"text",error:function(e){setTimeout(get_conf_file,1e3)},success:function(data){var configdata=data.split("\n");configdata=configdata.filter(Boolean);for(var i=0;i<configdata.length;i++)"ENFORCEALLOWANCE"!=configdata[i].split("=")[0]&&(eval("document.form.dnvnstat_"+configdata[i].split("=")[0].toLowerCase()).value=configdata[i].split("=")[1].replace(/(\r\n|\n|\r)/gm,""));get_vnstatconf_file()}})}function get_vnstatconf_file(){$.ajax({url:"/ext/dn-vnstat/vnstatconf.htm",dataType:"text",error:function(e){setTimeout(get_vnstatconf_file,1e3)},success:function(data){var configdata=data.split("\n");configdata=configdata.filter(Boolean);for(var i=0;i<configdata.length;i++)configdata[i].startsWith("MonthRotate ")&&(eval("document.form.dnvnstat_"+configdata[i].split(" ")[0].toLowerCase()).value=configdata[i].split(" ")[1].replace(/(\r\n|\n|\r)/gm,""))}})}function loadVnStatOutput(){$.ajax({url:"/ext/dn-vnstat/vnstatoutput.htm",dataType:"text",error:function(e){setTimeout(loadVnStatOutput,5e3)},success:function(e){document.getElementById("VnStatOuput").innerHTML=e}})}function get_vnstatusage_file(){$.ajax({url:"/ext/dn-vnstat/vnstatusage.js",dataType:"script",error:function(e){setTimeout(get_vnstatusage_file,1e3)},success:function(){UpdateText()}})}function ShowHideDataUsageWarning(e){e?(document.getElementById("datausagewarning").style.display="",document.getElementById("scripttitle").style.marginLeft="166px"):(document.getElementById("datausagewarning").style.display="none",document.getElementById("scripttitle").style.marginLeft="0px")}function UpdateText(){$("#statstitle").html("The statistics and graphs on this page were last refreshed at: "+daterefeshed),$("#spandatausage").html(usagestring),ShowHideDataUsageWarning(usagethreshold)}function UpdateImages(){for(var e=["s","hg","d","t","m"],t=(new Date).getTime(),a=0;a<e.length;a++)document.getElementById("img_"+e[a]).style.backgroundImage="url(/ext/dn-vnstat/images/.vnstat_"+e[a]+".htm?cachebuster="+t+")"}function UpdateStats(){showhide("btnUpdateStats",!1),document.formScriptActions.action_script.value="start_dn-vnstat",document.formScriptActions.submit(),document.getElementById("vnstatupdate_text").innerHTML="Updating bandwidth usage and vnstat data...",showhide("imgVnStatUpdate",!0),showhide("vnstatupdate_text",!0),setTimeout(update_vnstat,5e3)}function update_vnstat(){$.ajax({url:"/ext/dn-vnstat/detect_vnstat.js",dataType:"script",error:function(e){setTimeout(update_vnstat,1e3)},success:function(){"InProgress"==vnstatstatus?setTimeout(update_vnstat,1e3):"LOCKED"==vnstatstatus?(document.getElementById("vnstatupdate_text").innerHTML="vnstat update already in progress",showhide("imgVnStatUpdate",!1),showhide("vnstatupdate_text",!0),showhide("btnUpdateStats",!0)):"Done"==vnstatstatus&&(get_vnstatusage_file(),UpdateImages(),loadVnStatOutput(),currentNoCharts=0,RedrawAllCharts(),document.getElementById("vnstatupdate_text").innerHTML="",showhide("imgVnStatUpdate",!1),showhide("vnstatupdate_text",!1),showhide("btnUpdateStats",!0))}})}function AddEventHandlers(){$(".collapsible-jquery").off("click").on("click",(function(){$(this).siblings().toggle("fast",(function(){"none"==$(this).css("display")?SetCookie($(this).siblings()[0].id,"collapsed"):SetCookie($(this).siblings()[0].id,"expanded")}))})),$(".collapsible-jquery").each((function(e,t){"collapsed"==GetCookie($(this)[0].id,"string")?$(this).siblings().toggle(!1):$(this).siblings().toggle(!0)}))}function SetCurrentPage(){document.form.next_page.value=window.location.pathname.substring(1),document.form.current_page.value=window.location.pathname.substring(1)}function initial(){SetCurrentPage(),LoadCustomSettings(),ScriptUpdateLayout(),show_menu(),get_conf_file(),AddEventHandlers(),get_vnstatusage_file(),UpdateImages(),loadVnStatOutput(),$("#Time_Format").val(GetCookie("Time_Format","number")),RedrawAllCharts()}function reload(){location.reload(!0)}function Draw_Chart_NoData(e,t){document.getElementById("divChart_"+e).width="730",document.getElementById("divChart_"+e).height="500",document.getElementById("divChart_"+e).style.width="730px",document.getElementById("divChart_"+e).style.height="500px";var a=document.getElementById("divChart_"+e).getContext("2d");a.save(),a.textAlign="center",a.textBaseline="middle",a.font="normal normal bolder 48px Arial",a.fillStyle="white",a.fillText(t,365,250),a.restore()}function Draw_Chart(e){var t=$("#"+e+"_Unit option:selected").text(),a="Received",n="Sent",o=2;"B"!=t&&"KB"!=t||(o=0);var i=getChartPeriod($("#"+e+"_Period option:selected").val()),r=getChartInterval($("#"+e+"_Interval option:selected").val()),l=getChartUnitMultiplier($("#"+e+"_Unit option:selected").val()),s=timeunitlist[$("#"+e+"_Period option:selected").val()],d=intervallist[$("#"+e+"_Period option:selected").val()],u=moment(),c=null,m=moment().startOf("hour").subtract(d,s+"s").subtract(30,"minutes"),g="bar",f=window[e+"_"+r+"_"+i].slice();if(null!=f)if(0!=f.length){for(var h=[],v=[],p=0;p<f.length;p++)h[f[p].Metric]||(v.push(f[p].Metric),h[f[p].Metric]=1);var y=f.filter((function(e){return e.Metric==a})).map((function(e){return{x:e.Time,y:e.Value/l}})),b=f.filter((function(e){return e.Metric==n})).map((function(e){return{x:e.Time,y:e.Value/l}})),x=window["Chart_"+e],C=getTimeFormat($("#Time_Format option:selected").val(),"axis"),S=getTimeFormat($("#Time_Format option:selected").val(),"tooltip");"fiveminute"==r&&(g="line"),"hour"==r&&(u=c=moment().startOf("hour").add(1,"hours")),"day"==r&&(c=moment().endOf("day").subtract(9,"hours"),m=moment().startOf("day").subtract(d-1,s+"s").subtract(12,"hours"),u=c),"daily"==i&&"day"==r&&(s="day",d=1,c=moment().endOf("day").subtract(9,"hours"),m=moment().startOf("day").subtract(12,"hours"),u=c),null!=x&&x.destroy();var w=document.getElementById("divChart_"+e).getContext("2d"),_={segmentShowStroke:!1,segmentStrokeColor:"#000",animationEasing:"easeOutQuart",animationSteps:100,maintainAspectRatio:!1,animateScale:!0,hover:{mode:"point"},legend:{display:!0,position:"top",reverse:!1,onClick:function(e,t){var a=t.datasetIndex,n=this.chart,o=n.getDatasetMeta(a);if(o.hidden=null===o.hidden?!n.data.datasets[a].hidden:null,"line"==ShowLines){var i="";if(1!=o.hidden&&(i="line"),"Received"==n.data.datasets[a].label)for(var r=0;r<3;r++)n.options.annotation.annotations[r].type=i;else if("Sent"==n.data.datasets[a].label)for(r=3;r<6;r++)n.options.annotation.annotations[r].type=i}n.update()}},title:{display:!0,text:"Data Usage"},tooltips:{callbacks:{title:function(e,t){return"day"==r?moment(e[0].xLabel,"X").format("YYYY-MM-DD"):moment(e[0].xLabel,"X").format(S)},label:function(e,a){var n=t;return round(a.datasets[e.datasetIndex].data[e.index].y,o).toFixed(o)+" "+n}},itemSort:function(e,t){return t.datasetIndex-e.datasetIndex},mode:"point",position:"cursor",intersect:!0},scales:{xAxes:[{type:"time",gridLines:{display:!0,color:"#282828"},ticks:{min:m,max:c,display:!0},time:{parser:"X",unit:s,stepSize:1,displayFormats:C}}],yAxes:[{type:getChartScale($("#"+e+"_Scale option:selected").val()),gridLines:{display:!1,color:"#282828"},scaleLabel:{display:!1,labelString:t},id:"left-y-axis",position:"left",ticks:{display:!0,beginAtZero:!0,labels:{index:["min","max"],removeEmptyLines:!0},userCallback:LogarithmicFormatter}}]},plugins:{zoom:{pan:{enabled:ChartPan,mode:"xy",rangeMin:{x:m,y:0},rangeMax:{x:u}},zoom:{enabled:!0,drag:DragZoom,mode:"xy",rangeMin:{x:m,y:0},rangeMax:{x:u},speed:.1}}},annotation:{drawTime:"afterDatasetsDraw",annotations:[{type:ShowLines,mode:"horizontal",scaleID:"left-y-axis",value:getAverage(y),borderColor:bordercolourlist[0],borderWidth:1,borderDash:[5,5],label:{backgroundColor:"rgba(0,0,0,0.3)",fontFamily:"sans-serif",fontSize:10,fontStyle:"bold",fontColor:"#fff",xPadding:6,yPadding:6,cornerRadius:6,position:"center",enabled:!0,xAdjust:0,yAdjust:0,content:"Avg. Received="+round(getAverage(y),o).toFixed(o)+t}},{type:ShowLines,mode:"horizontal",scaleID:"left-y-axis",value:getLimit(y,"y","max",!0),borderColor:bordercolourlist[0],borderWidth:1,borderDash:[5,5],label:{backgroundColor:"rgba(0,0,0,0.3)",fontFamily:"sans-serif",fontSize:10,fontStyle:"bold",fontColor:"#fff",xPadding:6,yPadding:6,cornerRadius:6,position:"right",enabled:!0,xAdjust:15,yAdjust:0,content:"Max. Received="+round(getLimit(y,"y","max",!0),o).toFixed(o)+t}},{type:ShowLines,mode:"horizontal",scaleID:"left-y-axis",value:getLimit(y,"y","min",!0),borderColor:bordercolourlist[0],borderWidth:1,borderDash:[5,5],label:{backgroundColor:"rgba(0,0,0,0.3)",fontFamily:"sans-serif",fontSize:10,fontStyle:"bold",fontColor:"#fff",xPadding:6,yPadding:6,cornerRadius:6,position:"left",enabled:!0,xAdjust:15,yAdjust:0,content:"Min. Received="+round(getLimit(y,"y","min",!0),o).toFixed(o)+t}},{type:ShowLines,mode:"horizontal",scaleID:"left-y-axis",value:getAverage(b),borderColor:bordercolourlist[1],borderWidth:1,borderDash:[5,5],label:{backgroundColor:"rgba(0,0,0,0.3)",fontFamily:"sans-serif",fontSize:10,fontStyle:"bold",fontColor:"#fff",xPadding:6,yPadding:6,cornerRadius:6,position:"center",enabled:!0,xAdjust:0,yAdjust:0,content:"Avg. Sent="+round(getAverage(b),o).toFixed(o)+t}},{type:ShowLines,mode:"horizontal",scaleID:"left-y-axis",value:getLimit(b,"y","max",!0),borderColor:bordercolourlist[1],borderWidth:1,borderDash:[5,5],label:{backgroundColor:"rgba(0,0,0,0.3)",fontFamily:"sans-serif",fontSize:10,fontStyle:"bold",fontColor:"#fff",xPadding:6,yPadding:6,cornerRadius:6,position:"right",enabled:!0,xAdjust:15,yAdjust:0,content:"Max. Sent="+round(getLimit(b,"y","max",!0),o).toFixed(o)+t}},{type:ShowLines,mode:"horizontal",scaleID:"left-y-axis",value:getLimit(b,"y","min",!0),borderColor:bordercolourlist[1],borderWidth:1,borderDash:[5,5],label:{backgroundColor:"rgba(0,0,0,0.3)",fontFamily:"sans-serif",fontSize:10,fontStyle:"bold",fontColor:"#fff",xPadding:6,yPadding:6,cornerRadius:6,position:"left",enabled:!0,xAdjust:15,yAdjust:0,content:"Min. Sent="+round(getLimit(b,"y","min",!0),o).toFixed(o)+t}}]}},D={datasets:getDataSets(f,v,l)};x=new Chart(w,{type:g,options:_,data:D}),window["Chart_"+e]=x}else Draw_Chart_NoData(e,"No data to display");else Draw_Chart_NoData(e,"No data to display")}function Draw_Chart_Summary(e){var t=$("#"+e+"_Unit option:selected").text(),a="Received",n="Sent",o=2;"B"!=t&&"KB"!=t||(o=0);var i=getChartUnitMultiplier($("#"+e+"_Unit option:selected").val()),r=window[e+"_WeekSummary"].slice();if(null!=r)if(0!=r.length){for(var l=[],s=[],d=0;d<r.length;d++)l[r[d].Metric]||(s.push(r[d].Metric),l[r[d].Metric]=1);var u=r.filter((function(e){return e.Metric==a})).map((function(e){return e.Value/i})),c=r.filter((function(e){return e.Metric==n})).map((function(e){return e.Value/i}));l=[];var m=[];for(d=0;d<r.length;d++)l[r[d].Time]||(m.push(r[d].Time),l[r[d].Time]=1);m.reverse(),r.reverse();var g=window["Chart_"+e];null!=g&&g.destroy();var f=document.getElementById("divChart_"+e).getContext("2d"),h={segmentShowStroke:!1,segmentStrokeColor:"#000",animationEasing:"easeOutQuart",animationSteps:100,maintainAspectRatio:!1,animateScale:!0,hover:{mode:"point"},legend:{display:!0,position:"top",reverse:!1,onClick:function(e,t){var a=t.datasetIndex,n=this.chart,o=n.getDatasetMeta(a);if(o.hidden=null===o.hidden?!n.data.datasets[a].hidden:null,"line"==ShowLines){var i="";if(1!=o.hidden&&(i="line"),"Received"==n.data.datasets[a].label)for(var r=0;r<3;r++)n.options.annotation.annotations[r].type=i;else if("Sent"==n.data.datasets[a].label)for(r=3;r<6;r++)n.options.annotation.annotations[r].type=i}n.update()}},title:{display:!0,text:"Summary Usage"},tooltips:{callbacks:{title:function(e,t){return t.datasets[e[0].datasetIndex].label},label:function(e,a){var n=t;return round(a.datasets[e.datasetIndex].data[e.index],o).toFixed(o)+" "+n}},itemSort:function(e,t){return t.datasetIndex-e.datasetIndex},mode:"point",position:"cursor",intersect:!0},scales:{xAxes:[{type:"category",gridLines:{display:!0,color:"#282828"},ticks:{display:!0}}],yAxes:[{type:getChartScale($("#"+e+"_Scale option:selected").val()),gridLines:{display:!1,color:"#282828"},scaleLabel:{display:!1,labelString:t},id:"left-y-axis",position:"left",ticks:{display:!0,beginAtZero:!0,labels:{index:["min","max"],removeEmptyLines:!0},userCallback:LogarithmicFormatter}}]},plugins:{zoom:{pan:{enabled:ChartPan,mode:"xy",rangeMin:{y:0}},zoom:{enabled:!0,drag:DragZoom,mode:"xy",rangeMin:{y:0},speed:.1}}},annotation:{drawTime:"afterDatasetsDraw",annotations:[{type:ShowLines,mode:"horizontal",scaleID:"left-y-axis",value:getAverage(u),borderColor:bordercolourlist[0],borderWidth:1,borderDash:[5,5],label:{backgroundColor:"rgba(0,0,0,0.3)",fontFamily:"sans-serif",fontSize:10,fontStyle:"bold",fontColor:"#fff",xPadding:6,yPadding:6,cornerRadius:6,position:"center",enabled:!0,xAdjust:0,yAdjust:0,content:"Avg. Received="+round(getAverage(u),o).toFixed(o)+t}},{type:ShowLines,mode:"horizontal",scaleID:"left-y-axis",value:getLimit(u,"y","max",!0),borderColor:bordercolourlist[0],borderWidth:1,borderDash:[5,5],label:{backgroundColor:"rgba(0,0,0,0.3)",fontFamily:"sans-serif",fontSize:10,fontStyle:"bold",fontColor:"#fff",xPadding:6,yPadding:6,cornerRadius:6,position:"right",enabled:!0,xAdjust:15,yAdjust:0,content:"Max. Received="+round(getLimit(u,"y","max",!0),o).toFixed(o)+t}},{type:ShowLines,mode:"horizontal",scaleID:"left-y-axis",value:getLimit(u,"y","min",!0),borderColor:bordercolourlist[0],borderWidth:1,borderDash:[5,5],label:{backgroundColor:"rgba(0,0,0,0.3)",fontFamily:"sans-serif",fontSize:10,fontStyle:"bold",fontColor:"#fff",xPadding:6,yPadding:6,cornerRadius:6,position:"left",enabled:!0,xAdjust:15,yAdjust:0,content:"Min. Received="+round(getLimit(u,"y","min",!0),o).toFixed(o)+t}},{type:ShowLines,mode:"horizontal",scaleID:"left-y-axis",value:getAverage(c),borderColor:bordercolourlist[1],borderWidth:1,borderDash:[5,5],label:{backgroundColor:"rgba(0,0,0,0.3)",fontFamily:"sans-serif",fontSize:10,fontStyle:"bold",fontColor:"#fff",xPadding:6,yPadding:6,cornerRadius:6,position:"center",enabled:!0,xAdjust:0,yAdjust:0,content:"Avg. Sent="+round(getAverage(c),o).toFixed(o)+t}},{type:ShowLines,mode:"horizontal",scaleID:"left-y-axis",value:getLimit(c,"y","max",!0),borderColor:bordercolourlist[1],borderWidth:1,borderDash:[5,5],label:{backgroundColor:"rgba(0,0,0,0.3)",fontFamily:"sans-serif",fontSize:10,fontStyle:"bold",fontColor:"#fff",xPadding:6,yPadding:6,cornerRadius:6,position:"right",enabled:!0,xAdjust:15,yAdjust:0,content:"Max. Sent="+round(getLimit(c,"y","max",!0),o).toFixed(o)+t}},{type:ShowLines,mode:"horizontal",scaleID:"left-y-axis",value:getLimit(c,"y","min",!0),borderColor:bordercolourlist[1],borderWidth:1,borderDash:[5,5],label:{backgroundColor:"rgba(0,0,0,0.3)",fontFamily:"sans-serif",fontSize:10,fontStyle:"bold",fontColor:"#fff",xPadding:6,yPadding:6,cornerRadius:6,position:"left",enabled:!0,xAdjust:15,yAdjust:0,content:"Min. Sent="+round(getLimit(c,"y","min",!0),o).toFixed(o)+t}}]}},v={labels:m,datasets:getDataSets_Summary(r,s,i)};g=new Chart(f,{type:"bar",options:h,data:v}),window["Chart_"+e]=g}else Draw_Chart_NoData(e,"No data to display");else Draw_Chart_NoData(e,"No data to display")}function Draw_Chart_Compare(e){var t=$("#"+e+"_Unit option:selected").text(),a="Received",n="Sent",o=2;"B"!=t&&"KB"!=t||(o=0);var i=getChartUnitMultiplier($("#"+e+"_Unit option:selected").val()),r=window[e+"_WeekThis"].slice();if(null!=r)if(0!=r.length){for(var l=[],s=[],d=0;d<r.length;d++)l[r[d].Metric]||(s.push(r[d].Metric),l[r[d].Metric]=1);var u=[];baseDate=new Date;for(d=0;d<7;d++){if(r.filter((function(e){return e.Time==baseDate.getDay()})).length>0)for(var c=0;c<2;c++)u.push(r.filter((function(e){return e.Time==baseDate.getDay()}))[c]);else(p={Metric:"Received"}).Time=baseDate.getDay(),p.Value=0,u.push(p),(p={}).Metric="Sent",p.Time=baseDate.getDay(),p.Value=0,u.push(p);baseDate.setDate(baseDate.getDate()-1)}(r=u).reverse();var m=r.filter((function(e){return e.Metric==a})).map((function(e){return e.Value/i})),g=r.filter((function(e){return e.Metric==n})).map((function(e){return e.Value/i})),f=window[e+"_WeekPrev"].slice();if(null!=f)if(0!=f.length){var h=f.filter((function(e){return e.Metric==a})).map((function(e){return e.Value/i})),v=f.filter((function(e){return e.Metric==n})).map((function(e){return e.Value/i}));u=[],baseDate=new Date;for(d=0;d<7;d++){var p;if(f.filter((function(e){return e.Time==baseDate.getDay()})).length>0)for(c=0;c<2;c++)u.push(f.filter((function(e){return e.Time==baseDate.getDay()}))[c]);else(p={Metric:"Received"}).Time=baseDate.getDay(),p.Value=0,u.push(p),(p={}).Metric="Sent",p.Time=baseDate.getDay(),p.Value=0,u.push(p);baseDate.setDate(baseDate.getDate()-1)}(f=u).reverse();var y=m.concat(h),b=g.concat(v),x=[];baseDate=new Date;for(d=0;d<7;d++)x.push(baseDate.toLocaleDateString(navigator.language,{weekday:"long"})),baseDate.setDate(baseDate.getDate()-1);x.reverse();var C=window["Chart_"+e];null!=C&&C.destroy();var S=document.getElementById("divChart_"+e).getContext("2d"),w={segmentShowStroke:!1,segmentStrokeColor:"#000",animationEasing:"easeOutQuart",animationSteps:100,maintainAspectRatio:!1,animateScale:!0,hover:{mode:"point"},legend:{display:!0,position:"top",reverse:!1,onClick:function(e,t){var a=t.datasetIndex,n=this.chart,o=n.getDatasetMeta(a);if(o.hidden=null===o.hidden?!n.data.datasets[a].hidden:null,"line"==ShowLines){var i="";if(1!=o.hidden&&(i="line"),"Received"==n.data.datasets[a].label)for(var r=0;r<3;r++)n.options.annotation.annotations[r].type=i;else if("Sent"==n.data.datasets[a].label)for(r=3;r<6;r++)n.options.annotation.annotations[r].type=i}n.update()}},title:{display:!0,text:"Compare Usage"},tooltips:{callbacks:{title:function(e,t){return t.datasets[e[0].datasetIndex].label},label:function(e,a){var n=t;return round(a.datasets[e.datasetIndex].data[e.index],o).toFixed(o)+" "+n}},itemSort:function(e,t){return t.datasetIndex-e.datasetIndex},mode:"point",position:"cursor",intersect:!0},scales:{xAxes:[{type:"category",gridLines:{display:!0,color:"#282828"},ticks:{display:!0}}],yAxes:[{type:getChartScale($("#"+e+"_Scale option:selected").val()),gridLines:{display:!1,color:"#282828"},scaleLabel:{display:!1,labelString:t},id:"left-y-axis",position:"left",ticks:{display:!0,beginAtZero:!0,labels:{index:["min","max"],removeEmptyLines:!0},userCallback:LogarithmicFormatter}}]},plugins:{zoom:{pan:{enabled:ChartPan,mode:"xy",rangeMin:{y:0}},zoom:{enabled:!0,drag:DragZoom,mode:"xy",rangeMin:{y:0},speed:.1}}},annotation:{drawTime:"afterDatasetsDraw",annotations:[{type:ShowLines,mode:"horizontal",scaleID:"left-y-axis",value:getAverage(y),borderColor:bordercolourlist[0],borderWidth:1,borderDash:[5,5],label:{backgroundColor:"rgba(0,0,0,0.3)",fontFamily:"sans-serif",fontSize:10,fontStyle:"bold",fontColor:"#fff",xPadding:6,yPadding:6,cornerRadius:6,position:"center",enabled:!0,xAdjust:0,yAdjust:0,content:"Avg. Received="+round(getAverage(y),o).toFixed(o)+t}},{type:ShowLines,mode:"horizontal",scaleID:"left-y-axis",value:getLimit(y,"y","max",!0),borderColor:bordercolourlist[0],borderWidth:1,borderDash:[5,5],label:{backgroundColor:"rgba(0,0,0,0.3)",fontFamily:"sans-serif",fontSize:10,fontStyle:"bold",fontColor:"#fff",xPadding:6,yPadding:6,cornerRadius:6,position:"right",enabled:!0,xAdjust:15,yAdjust:0,content:"Max. Received="+round(getLimit(y,"y","max",!0),o).toFixed(o)+t}},{type:ShowLines,mode:"horizontal",scaleID:"left-y-axis",value:getLimit(y,"y","min",!0),borderColor:bordercolourlist[0],borderWidth:1,borderDash:[5,5],label:{backgroundColor:"rgba(0,0,0,0.3)",fontFamily:"sans-serif",fontSize:10,fontStyle:"bold",fontColor:"#fff",xPadding:6,yPadding:6,cornerRadius:6,position:"left",enabled:!0,xAdjust:15,yAdjust:0,content:"Min. Received="+round(getLimit(y,"y","min",!0),o).toFixed(o)+t}},{type:ShowLines,mode:"horizontal",scaleID:"left-y-axis",value:getAverage(b),borderColor:bordercolourlist[1],borderWidth:1,borderDash:[5,5],label:{backgroundColor:"rgba(0,0,0,0.3)",fontFamily:"sans-serif",fontSize:10,fontStyle:"bold",fontColor:"#fff",xPadding:6,yPadding:6,cornerRadius:6,position:"center",enabled:!0,xAdjust:0,yAdjust:0,content:"Avg. Sent="+round(getAverage(b),o).toFixed(o)+t}},{type:ShowLines,mode:"horizontal",scaleID:"left-y-axis",value:getLimit(b,"y","max",!0),borderColor:bordercolourlist[1],borderWidth:1,borderDash:[5,5],label:{backgroundColor:"rgba(0,0,0,0.3)",fontFamily:"sans-serif",fontSize:10,fontStyle:"bold",fontColor:"#fff",xPadding:6,yPadding:6,cornerRadius:6,position:"right",enabled:!0,xAdjust:15,yAdjust:0,content:"Max. Sent="+round(getLimit(b,"y","max",!0),o).toFixed(o)+t}},{type:ShowLines,mode:"horizontal",scaleID:"left-y-axis",value:getLimit(b,"y","min",!0),borderColor:bordercolourlist[1],borderWidth:1,borderDash:[5,5],label:{backgroundColor:"rgba(0,0,0,0.3)",fontFamily:"sans-serif",fontSize:10,fontStyle:"bold",fontColor:"#fff",xPadding:6,yPadding:6,cornerRadius:6,position:"left",enabled:!0,xAdjust:15,yAdjust:0,content:"Min. Sent="+round(getLimit(b,"y","min",!0),o).toFixed(o)+t}}]}},_={labels:x,datasets:getDataSets_Compare(r,f,s,i)};C=new Chart(S,{type:"bar",options:w,data:_}),window["Chart_"+e]=C}else Draw_Chart_NoData(e,"No data to display");else Draw_Chart_NoData(e,"No data to display")}else Draw_Chart_NoData(e,"No data to display");else Draw_Chart_NoData(e,"No data to display")}function getDataSets(e,t,a){for(var n=[],o=0;o<t.length;o++){var i=e.filter((function(e){return e.Metric==t[o]})).map((function(e){return{x:e.Time,y:e.Value/a}}));n.push({label:t[o],data:i,yAxisID:"left-y-axis",borderWidth:1,pointRadius:1,lineTension:0,fill:ShowFill,backgroundColor:backgroundcolourlist[o],borderColor:bordercolourlist[o],trendlineLinear:{style:trendcolourlist[o],lineStyle:"dotted",width:4}})}return n}function getDataSets_Summary(e,t,a){for(var n=[],o=0;o<t.length;o++){var i=e.filter((function(e){return e.Metric==t[o]})).map((function(e){return e.Value/a}));n.push({label:t[o],data:i,yAxisID:"left-y-axis",borderWidth:1,pointRadius:1,lineTension:0,fill:ShowFill,backgroundColor:backgroundcolourlist[o],borderColor:bordercolourlist[o],trendlineLinear:{style:trendcolourlist[o],lineStyle:"dotted",width:4}})}return n}function getDataSets_Compare(e,t,a,n){for(var o=[],i=0;i<a.length;i++){var r=e.filter((function(e){return e.Metric==a[i]})).map((function(e){return e.Value/n}));o.push({label:"Current 7 days - "+a[i],data:r,yAxisID:"left-y-axis",borderWidth:1,pointRadius:1,lineTension:0,fill:ShowFill,backgroundColor:backgroundcolourlist[i],borderColor:bordercolourlist[i],trendlineLinear:{style:trendcolourlist[i],lineStyle:"dotted",width:4}})}for(i=0;i<a.length;i++){r=t.filter((function(e){return e.Metric==a[i]})).map((function(e){return e.Value/n}));o.push({label:"Previous 7 days - "+a[i],data:r,yAxisID:"left-y-axis",borderWidth:1,pointRadius:1,lineTension:0,fill:ShowFill,backgroundColor:backgroundcolourlist[i+2],borderColor:bordercolourlist[i+2],trendlineLinear:{style:trendcolourlist[i+2],lineStyle:"dotted",width:4}})}return o}function LogarithmicFormatter(e,t,a){var n=this.options.scaleLabel.labelString,o=2;if("B"!=n&&"KB"!=n||(o=0),"logarithmic"!=this.type)return isNaN(e)?e+" "+n:round(e,o).toFixed(o)+" "+n;var i=this.options.ticks.labels||{},r=i.index||["min","max"],l=i.significand||[1,2,5],s=e/Math.pow(10,Math.floor(Chart.helpers.log10(e))),d=!0===i.removeEmptyLines?void 0:"",u="";return 0===t?u="min":t===a.length-1&&(u="max"),"all"===i||-1!==l.indexOf(s)||-1!==r.indexOf(t)||-1!==r.indexOf(u)?0===e?"0 "+n:isNaN(e)?e+" "+n:round(e,o).toFixed(o)+" "+n:d}function getLimit(e,t,a,n){var o,i=0;return o=(o="x"==t?e.map((function(e){return e.x})):e.map((function(e){return void 0===e.y||null==e.y||isNaN(e.y)?e:e.y}))).filter((function(e){return!isNaN(e)})),i="max"==a?Math.max.apply(Math,o):Math.min.apply(Math,o),"max"==a&&0==i&&0==n&&(i=1),i}function getAverage(e){for(var t=0,a=0,n=0;n<e.length;n++)void 0===e[n].y||null==e[n].y||isNaN(e[n].y)?isNaN(e[n])?(a+=1,t+=0):t+=1*e[n]:t+=1*e[n].y;return t/(e.length-a)}function round(e,t){return Number(Math.round(e+"e"+t)+"e-"+t)}function ToggleTrendlines(){"0"==ShowTrendlines?(ShowTrendlines="0.8",SetCookie("ShowTrendlines","0.8")):(ShowTrendlines="0",SetCookie("ShowTrendlines","0")),trendcolourlist=["rgba(197,197,206,"+ShowTrendlines+")","rgba(14,192,9,"+ShowTrendlines+")","rgba(149,98,34,"+ShowTrendlines+")","rgba(56,149,157,"+ShowTrendlines+")"];for(var e=0;e<chartobjlist.length;e++){var t=window[chartobjlist[e]];if(null==t)return;for(var a=0;a<t.data.datasets.length;a++)t.data.datasets[a].trendlineLinear.style=trendcolourlist[a];t.update()}}function ToggleLines(){""==ShowLines?(ShowLines="line",SetCookie("ShowLines","line")):(ShowLines="",SetCookie("ShowLines",""));for(var e=0;e<chartobjlist.length;e++){var t=window[chartobjlist[e]];if(null==t)return;for(var a=0;a<t.options.annotation.annotations.length;a++)t.options.annotation.annotations[a].type=ShowLines;t.update()}}function ToggleFill(){"origin"==ShowFill?(ShowFill="false",SetCookie("ShowFill","false")):(ShowFill="origin",SetCookie("ShowFill","origin"));for(var e=0;e<chartobjlist.length;e++){var t=window[chartobjlist[e]];if(null==t)return;t.data.datasets[0].fill=ShowFill,t.data.datasets[1].fill=ShowFill,t.update()}}function ToggleDragZoom(e){var t=!0,a=!1,n="";-1!=e.value.indexOf("On")?(t=!1,a=!0,DragZoom=!1,ChartPan=!0,n="Drag Zoom Off"):(t=!0,a=!1,DragZoom=!0,ChartPan=!1,n="Drag Zoom On");for(var o=0;o<chartobjlist.length;o++){var i=window[chartobjlist[o]];if(null==i)return;i.options.plugins.zoom.zoom.drag=t,i.options.plugins.zoom.pan.enabled=a,i.update(),e.value=n}}function ResetZoom(){for(var e=0;e<chartobjlist.length;e++){var t=window[chartobjlist[e]];if(null==t)return;t.resetZoom()}}function RedrawAllCharts(){$("#DataUsage_Interval").val(GetCookie("DataUsage_Interval","number")),changePeriod(document.getElementById("DataUsage_Interval")),$("#DataUsage_Period").val(GetCookie("DataUsage_Period","number")),$("#DataUsage_Unit").val(GetCookie("DataUsage_Unit","number")),$("#DataUsage_Scale").val(GetCookie("DataUsage_Scale","number")),Draw_Chart_NoData("DataUsage","Data loading..."),Draw_Chart_NoData("CompareUsage","Data loading...");for(var e=0;e<chartlist.length;e++)for(var t=0;t<dataintervallist.length;t++)d3.csv("/ext/dn-vnstat/csv/DataUsage_"+dataintervallist[t]+"_"+chartlist[e]+".htm").then(SetGlobalDataset.bind(null,"DataUsage_"+dataintervallist[t]+"_"+chartlist[e]));$("#CompareUsage_Interval").val(GetCookie("CompareUsage_Interval","number")),$("#CompareUsage_Unit").val(GetCookie("CompareUsage_Unit","number")),$("#CompareUsage_Scale").val(GetCookie("CompareUsage_Scale","number")),d3.csv("/ext/dn-vnstat/csv/WeekThis.htm").then(SetGlobalDataset.bind(null,"CompareUsage_WeekThis")),d3.csv("/ext/dn-vnstat/csv/WeekPrev.htm").then(SetGlobalDataset.bind(null,"CompareUsage_WeekPrev")),d3.csv("/ext/dn-vnstat/csv/WeekSummary.htm").then(SetGlobalDataset.bind(null,"CompareUsage_WeekSummary"))}function SetGlobalDataset(e,t){window[e]=t,++currentNoCharts==maxNoCharts&&(Draw_Chart("DataUsage"),"week"==getSummaryInterval($("#CompareUsage_Interval option:selected").val())?Draw_Chart_Summary("CompareUsage"):"day"==getSummaryInterval($("#CompareUsage_Interval option:selected").val())&&Draw_Chart_Compare("CompareUsage"))}function getTimeFormat(e,t){var a;return"axis"==t?0==e?a={millisecond:"HH:mm:ss.SSS",second:"HH:mm:ss",minute:"HH:mm",hour:"HH:mm"}:1==e&&(a={millisecond:"h:mm:ss.SSS A",second:"h:mm:ss A",minute:"h:mm A",hour:"h A"}):"tooltip"==t&&(0==e?a="YYYY-MM-DD HH:mm:ss":1==e&&(a="YYYY-MM-DD h:mm:ss A")),a}function getChartPeriod(e){var t="daily";return 0==e?t="daily":1==e?t="weekly":2==e&&(t="monthly"),t}function getChartUnitMultiplier(e){return Math.pow(1e3,e)}function getChartScale(e){var t="";return 0==e?t="linear":1==e&&(t="logarithmic"),t}function getChartInterval(e){var t="fiveminute";return 0==e?t="fiveminute":1==e?t="hour":2==e&&(t="day"),t}function getSummaryInterval(e){var t="day";return 0==e?t="day":1==e&&(t="week"),t}function changeAllCharts(e){value=1*e.value,SetCookie(e.id,value),Draw_Chart("DataUsage"),"week"==getSummaryInterval($("#"+name+"_Interval option:selected").val())?Draw_Chart_Compare("CompareUsage"):"day"==getSummaryInterval($("#"+name+"_Interval option:selected").val())&&Draw_Chart_Summary("CompareUsage")}function changeChart(e){value=1*e.value,name=e.id.substring(0,e.id.lastIndexOf("_")),SetCookie(e.id,value),"DataUsage"==name?Draw_Chart(name):"CompareUsage"==name&&"week"==getSummaryInterval($("#"+name+"_Interval option:selected").val())?Draw_Chart_Summary(name):"CompareUsage"==name&&"day"==getSummaryInterval($("#"+name+"_Interval option:selected").val())&&Draw_Chart_Compare(name)}function changePeriod(e){value=1*e.value,name=e.id.substring(0,e.id.indexOf("_")),2==value?$('select[id="'+name+'_Period"] option:contains(24)').text("Today"):$('select[id="'+name+'_Period"] option:contains("Today")').text("Last 24 hours")}$(document).keydown((function(e){keyHandler(e)})),$(document).keyup((function(e){$(document).keydown((function(e){keyHandler(e)}))})),$.fn.serializeObject=function(){var e=custom_settings,t=this.serializeArray();return $.each(t,(function(){void 0!==e[this.name]&&-1!=this.name.indexOf("dnvnstat")&&-1==this.name.indexOf("version")?(e[this.name].push||(e[this.name]=[e[this.name]]),e[this.name].push(this.value||"")):-1!=this.name.indexOf("dnvnstat")&&-1==this.name.indexOf("version")&&(e[this.name]=this.value||"")})),e};

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
<div class="formfonttitle" id="scripttitle" style="text-align:center;margin-left:166px;">vnStat-on-Merlin</div>
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
<th width="20%">Data usage for current cycle
<br />
<a href="https://github.com/de-vnull/vnstat-on-merlin/blob/main/more-info.md#Units" target="_blank" style="color:#FFCC00;">More info</a>
</th>
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
<div id="img_hg" class="vnstat" style="background-image:url('/ext/dn-vnstat/images/.vnstat_hg.htm');">
<img style="visibility:hidden;" src="/ext/dn-vnstat/images/vnstat_hg.png" alt="Hourly" />
</div>
</td></tr>
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
<input type="button" onclick="ToggleTrendlines();" value="Toggle Trendlines" class="button_gen" name="btnToggleTrendlines">
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
<div style="background-color:#2f3e44;border-radius:10px;width:730px;height:500px;padding-left:5px;"><canvas id="divChart_DataUsage" height="500" /></div>
</td>
</tr>
</table>


<div style="line-height:10px;">&nbsp;</div>
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
<thead class="collapsible-jquery" id="chart_CompareUsage">
<tr>
<td colspan="2">Compare Usage (click to expand/collapse)</td>
</tr>
</thead>
<tr class="even">
<th width="40%">Data interval</th>
<td>
<select style="width:150px" class="input_option" onchange="changeChart(this)" id="CompareUsage_Interval">
<option value="0">Days</option>
<option value="1">Weeks</option>
</select>
</td>
</tr>
<tr class="even">
<th width="40%">Unit for data usage</th>
<td>
<select style="width:150px" class="input_option" onchange="changeChart(this)" id="CompareUsage_Unit">
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
<select style="width:150px" class="input_option" onchange="changeChart(this)" id="CompareUsage_Scale">
<option value="0">Linear</option>
<option value="1">Logarithmic</option>
</select>
</td>
</tr>
<tr>
<td colspan="2" align="center" style="padding: 0px;">
<div style="background-color:#2f3e44;border-radius:10px;width:730px;height:500px;padding-left:5px;"><canvas id="divChart_CompareUsage" height="500" /></div>
</td>
</tr>
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
<p align="right"><small><i>vnStat-on-Merlin: concept by dev_null & implemented by Jack Yaz - <a href="https://github.com/de-vnull/vnstat-on-merlin" target="_blank" style="color:#FFCC00;">vnStat-on-Merlin Github</a></i></small></td>
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
