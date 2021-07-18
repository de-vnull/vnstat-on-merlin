var $j = jQuery.noConflict(); //avoid conflicts on John's fork (state.js)
var maxNoCharts = 12;
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
var bordercolourlist= ['#c5c5ce','#0ec009','#956222','#38959d'];
var backgroundcolourlist = ['rgba(197,197,206,0.5)','rgba(14,192,9,0.5)','rgba(149,98,34,0.5)','rgba(56,149,157,0.5)'];
var chartobjlist = ['Chart_DataUsage','Chart_CompareUsage'];

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

function get_vnstatusage_file(){
	$j.ajax({
		url: '/ext/dn-vnstat/vnstatusage.js',
		dataType: 'script',
		error: function(xhr){
			setTimeout(get_vnstatusage_file,1000);
		},
		success: function(){
			UpdateText();
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
	var images=['s','hg','d','t','m'];
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
			else if(vnstatstatus == 'LOCKED'){
				document.getElementById('vnstatupdate_text').innerHTML = 'vnstat update already in progress';
				showhide('imgVnStatUpdate',false);
				showhide('vnstatupdate_text',true);
				showhide('btnUpdateStats',true);
			}
			else if(vnstatstatus == 'Done'){
				get_vnstatusage_file();
				UpdateImages();
				loadVnStatOutput();
				currentNoCharts = 0;
				RedrawAllCharts();
				document.getElementById('vnstatupdate_text').innerHTML = '';
				showhide('imgVnStatUpdate',false);
				showhide('vnstatupdate_text',false);
				showhide('btnUpdateStats',true);
			}
		}
	});
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
	get_vnstatusage_file();
	UpdateImages();
	loadVnStatOutput();
	$j('#Time_Format').val(GetCookie('Time_Format','number'));
	RedrawAllCharts();
}

function reload(){
	location.reload(true);
}

function Draw_Chart_NoData(txtchartname,texttodisplay){
	document.getElementById('divChart_'+txtchartname).width='730';
	document.getElementById('divChart_'+txtchartname).height='500';
	document.getElementById('divChart_'+txtchartname).style.width='730px';
	document.getElementById('divChart_'+txtchartname).style.height='500px';
	var ctx = document.getElementById('divChart_'+txtchartname).getContext('2d');
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
	var chartxaxismin = moment().startOf('hour').subtract(numunitx,txtunitx+'s').subtract(30,'minutes');
	var charttype = 'bar';
	var dataobject = window[txtchartname+'_'+chartinterval+'_'+chartperiod];
	if(typeof dataobject === 'undefined' || dataobject === null){ Draw_Chart_NoData(txtchartname,'No data to display'); return; }
	if(dataobject.length == 0){ Draw_Chart_NoData(txtchartname,'No data to display'); return; }
	
	var unique = [];
	var chartTrafficTypes = [];
	for(let i = 0; i < dataobject.length; i++){
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
	
	var objchartname=window['Chart_'+txtchartname];
	
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
	
	if(objchartname != undefined) objchartname.destroy();
	var ctx = document.getElementById('divChart_'+txtchartname).getContext('2d');
	var chartOptions = {
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
	var chartDataset = {
		datasets: getDataSets(dataobject,chartTrafficTypes,chartunitmultiplier)
	};
	objchartname = new Chart(ctx,{
		type: charttype,
		options: chartOptions,
		data: chartDataset
	});
	window['Chart_'+txtchartname]=objchartname;
}


function Draw_Chart_Summary(txtchartname){
	var txtunity = $j('#'+txtchartname+'_Unit option:selected').text();
	var txttitle = 'Summary Usage';
	var metric0 = 'Received';
	var metric1 = 'Sent';
	
	var decimals = 2;
	if(txtunity == 'B' || txtunity == 'KB'){
		decimals = 0;
	}
	
	var chartunitmultiplier = getChartUnitMultiplier($j('#'+txtchartname+'_Unit option:selected').val());
	var charttype = 'bar';
	var dataobject0 = window[txtchartname+'_WeekSummary'];
	if(typeof dataobject0 === 'undefined' || dataobject0 === null){ Draw_Chart_NoData(txtchartname,'No data to display'); return; }
	if(dataobject0.length == 0){ Draw_Chart_NoData(txtchartname,'No data to display'); return; }
	
	var unique = [];
	var chartTrafficTypes = [];
	for(let i = 0; i < dataobject0.length; i++){
		if(!unique[dataobject0[i].Metric]){
			chartTrafficTypes.push(dataobject0[i].Metric);
			unique[dataobject0[i].Metric] = 1;
		}
	}
	
	var chartData0 = dataobject0.filter(function(item){
		return item.Metric == metric0;
	}).map(function(d){return d.Value/chartunitmultiplier});
	
	var chartData1 = dataobject0.filter(function(item){
		return item.Metric == metric1;
	}).map(function(d){return d.Value/chartunitmultiplier});
	
	chartData0.reverse();
	chartData1.reverse();
	
	unique = [];
	var chartLabels = [];
	for(let i = 0; i < dataobject0.length; i++){
		if(!unique[dataobject0[i].Time]){
			chartLabels.push(dataobject0[i].Time);
			unique[dataobject0[i].Time] = 1;
		}
	}
	
	chartLabels.reverse();
	
	var objchartname=window['Chart_'+txtchartname];
	
	if(objchartname != undefined) objchartname.destroy();
	var ctx = document.getElementById('divChart_'+txtchartname).getContext('2d');
	var chartOptions = {
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
						return data.datasets[tooltipItem[0].datasetIndex].label;
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
				type: 'category',
				gridLines: { display: true,color: '#282828' },
				ticks: {
					display: true
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
						y: 0
					}
				},
				zoom: {
					enabled: true,
					drag: DragZoom,
					mode: 'xy',
					rangeMin: {
						y: 0
					},
					speed: 0.1
				}
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
	var chartDataset = {
		labels: chartLabels,
		datasets: getDataSets(dataobject0,chartTrafficTypes,chartunitmultiplier)
	};
	objchartname = new Chart(ctx,{
		type: charttype,
		options: chartOptions,
		data: chartDataset
	});
	window['Chart_'+txtchartname]=objchartname;
}

function Draw_Chart_Compare(txtchartname){
	var txtunity = $j('#'+txtchartname+'_Unit option:selected').text();
	var txttitle = 'Compare Usage';
	var metric0 = 'Received';
	var metric1 = 'Sent';
	
	var decimals = 2;
	if(txtunity == 'B' || txtunity == 'KB'){
		decimals = 0;
	}
	
	var chartunitmultiplier = getChartUnitMultiplier($j('#'+txtchartname+'_Unit option:selected').val());
	var txtunitx = 'day';
	var zoompanxaxismax = moment().endOf('day');
	var chartxaxismax = moment().endOf('day');
	var chartxaxismin = moment().endOf('day').subtract(7,'days').subtract(12,'hours');
	var charttype = 'bar';
	var dataobject0 = window[txtchartname+'_WeekThis'];
	if(typeof dataobject0 === 'undefined' || dataobject0 === null){ Draw_Chart_NoData(txtchartname,'No data to display'); return; }
	if(dataobject0.length == 0){ Draw_Chart_NoData(txtchartname,'No data to display'); return; }
	
	var dataobject1 = window[txtchartname+'_WeekPrev'];
	
	var unique = [];
	var chartTrafficTypes = [];
	for(let i = 0; i < dataobject0.length; i++){
		if(!unique[dataobject0[i].Metric]){
			chartTrafficTypes.push(dataobject0[i].Metric);
			unique[dataobject0[i].Metric] = 1;
		}
	}
	
	var chartData0 = dataobject0.filter(function(item){
		return item.Metric == metric0;
	}).map(function(d){return {x: d.Time,y: (d.Value/chartunitmultiplier)}});
	
	var chartData1 = dataobject0.filter(function(item){
		return item.Metric == metric1;
	}).map(function(d){return {x: d.Time,y: (d.Value/chartunitmultiplier)}});
	
	var chartData2 = dataobject1.filter(function(item){
		return item.Metric == metric0;
	}).map(function(d){return {x: d.Time,y: (d.Value/chartunitmultiplier)}});
	
	var chartData3 = dataobject1.filter(function(item){
		return item.Metric == metric1;
	}).map(function(d){return {x: d.Time,y: (d.Value/chartunitmultiplier)}});
	
	var chartDataRx = chartData0.concat(chartData2);
	var chartDataTx = chartData1.concat(chartData3);
	
	var objchartname=window['Chart_'+txtchartname];
	
	if(objchartname != undefined) objchartname.destroy();
	var ctx = document.getElementById('divChart_'+txtchartname).getContext('2d');
	var chartOptions = {
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
						return data.datasets[tooltipItem[0].datasetIndex].label;
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
					displayFormats: {day: 'dddd'}
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
				value: getAverage(chartDataRx),
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
					content: 'Avg. '+metric0+'='+round(getAverage(chartDataRx),decimals).toFixed(decimals)+txtunity,
				}
			},
			{
				//id: 'maxline',
				type: ShowLines,
				mode: 'horizontal',
				scaleID: 'left-y-axis',
				value: getLimit(chartDataRx,'y','max',true),
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
					content: 'Max. '+metric0+'='+round(getLimit(chartDataRx,'y','max',true),decimals).toFixed(decimals)+txtunity,
				}
			},
			{
				//id: 'minline',
				type: ShowLines,
				mode: 'horizontal',
				scaleID: 'left-y-axis',
				value: getLimit(chartDataRx,'y','min',true),
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
					content: 'Min. '+metric0+'='+round(getLimit(chartDataRx,'y','min',true),decimals).toFixed(decimals)+txtunity,
				}
			},
			{
				//id: 'avgline',
				type: ShowLines,
				mode: 'horizontal',
				scaleID: 'left-y-axis',
				value: getAverage(chartDataTx),
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
					content: 'Avg. '+metric1+'='+round(getAverage(chartDataTx),decimals).toFixed(decimals)+txtunity,
				}
			},
			{
				//id: 'maxline',
				type: ShowLines,
				mode: 'horizontal',
				scaleID: 'left-y-axis',
				value: getLimit(chartDataTx,'y','max',true),
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
					content: 'Max. '+metric1+'='+round(getLimit(chartDataTx,'y','max',true),decimals).toFixed(decimals)+txtunity,
				}
			},
			{
				//id: 'minline',
				type: ShowLines,
				mode: 'horizontal',
				scaleID: 'left-y-axis',
				value: getLimit(chartDataTx,'y','min',true),
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
					content: 'Min. '+metric1+'='+round(getLimit(chartDataTx,'y','min',true),decimals).toFixed(decimals)+txtunity,
				}
			}
		]}
	};
	var chartDataset = {
		datasets: getDataSets_Compare(dataobject0,dataobject1,chartTrafficTypes,chartunitmultiplier)
	};
	objchartname = new Chart(ctx,{
		type: charttype,
		options: chartOptions,
		data: chartDataset
	});
	window['Chart_'+txtchartname]=objchartname;
}

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

function getDataSets_Compare(objdata0,objdata1,objTrafficTypes,chartunitmultiplier){
	var datasets = [];
	
	for(var i = 0; i < objTrafficTypes.length; i++){
		var traffictypedata = objdata0.filter(function(item){
			return item.Metric == objTrafficTypes[i];
		}).map(function(d){return {x: d.Time,y: (d.Value/chartunitmultiplier)}});
		
		datasets.push({ label: 'Current 7 days - '+objTrafficTypes[i],data: traffictypedata,yAxisID: 'left-y-axis',borderWidth: 1,pointRadius: 1,lineTension: 0,fill: ShowFill,backgroundColor: backgroundcolourlist[i],borderColor: bordercolourlist[i]});
	}
	for(var i = 0; i < objTrafficTypes.length; i++){
		var traffictypedata = objdata1.filter(function(item){
			return item.Metric == objTrafficTypes[i];
		}).map(function(d){return {x: d.Time,y: (d.Value/chartunitmultiplier)}});
		
		datasets.push({ label: 'Previous 7 days - '+objTrafficTypes[i],data: traffictypedata,yAxisID: 'left-y-axis',borderWidth: 1,pointRadius: 1,lineTension: 0,fill: ShowFill,backgroundColor: backgroundcolourlist[i+2],borderColor: bordercolourlist[i+2]});
	}
	
	return datasets;
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

function getLimit(datasetname,axis,maxmin,isannotation){
	var limit = 0;
	var values;
	if(axis == 'x'){
		values = datasetname.map(function(o){ return o.x } );
	}
	else{
		values = datasetname.map(function(o){
			if(typeof o.y === 'undefined' || o.y == null || isNaN(o.y)){
				return o;
			}
			else{
				return o.y;
			}
		});
	}
	
	values = values.filter(function(item){return ! isNaN(item);});
	
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
	var modifier = 0;
	
	for(var i = 0; i < datasetname.length; i++){
		if(typeof datasetname[i].y === 'undefined' || datasetname[i].y == null || isNaN(datasetname[i].y)){
			if(isNaN(datasetname[i])){
				modifier=modifier+1;
				total += 0;
			}
			else{
				total += (datasetname[i]*1);
			}
		}
		else{
			total += (datasetname[i].y*1);
		}
	}
	var avg = total / (datasetname.length - modifier);
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
	
	for(var i = 0; i < chartobjlist.length; i++){
		var chartobj = window[chartobjlist[i]];
		if(typeof chartobj === 'undefined' || chartobj === null){ return; }
		for(var i2 = 0; i2 < chartobj.options.annotation.annotations.length; i2++){
			chartobj.options.annotation.annotations[i2].type=ShowLines;
		}
		chartobj.update();
	}
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
	
	for(var i = 0; i < chartobjlist.length; i++){
		var chartobj = window[chartobjlist[i]];
		if(typeof chartobj === 'undefined' || chartobj === null){ return; }
		chartobj.data.datasets[0].fill=ShowFill;
		chartobj.data.datasets[1].fill=ShowFill;
		chartobj.update();
	}
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
	
	for(var i = 0; i < chartobjlist.length; i++){
		var chartobj = window[chartobjlist[i]];
		if(typeof chartobj === 'undefined' || chartobj === null){ return; }
		chartobj.options.plugins.zoom.zoom.drag = drag;
		chartobj.options.plugins.zoom.pan.enabled = pan;
		chartobj.update();
		button.value = buttonvalue;
	}
}

function ResetZoom(){
	for(var i = 0; i < chartobjlist.length; i++){
		var chartobj = window[chartobjlist[i]];
		if(typeof chartobj === 'undefined' || chartobj === null){ return; }
		chartobj.resetZoom();
	}
}

function RedrawAllCharts(){
	$j('#DataUsage_Interval').val(GetCookie('DataUsage_Interval','number'));
	changePeriod(document.getElementById('DataUsage_Interval'));
	$j('#DataUsage_Period').val(GetCookie('DataUsage_Period','number'));
	$j('#DataUsage_Unit').val(GetCookie('DataUsage_Unit','number'));
	$j('#DataUsage_Scale').val(GetCookie('DataUsage_Scale','number'));
	Draw_Chart_NoData('DataUsage','Data loading...');
	Draw_Chart_NoData('CompareUsage','Data loading...');
	for(var i = 0; i < chartlist.length; i++){
		for(var i2 = 0; i2 < dataintervallist.length; i2++){
			d3.csv('/ext/dn-vnstat/csv/DataUsage_'+dataintervallist[i2]+'_'+chartlist[i]+'.htm').then(SetGlobalDataset.bind(null,'DataUsage_'+dataintervallist[i2]+'_'+chartlist[i]));
		}
	}
	$j('#CompareUsage_Interval').val(GetCookie('CompareUsage_Interval','number'));
	$j('#CompareUsage_Unit').val(GetCookie('CompareUsage_Unit','number'));
	$j('#CompareUsage_Scale').val(GetCookie('CompareUsage_Scale','number'));
	d3.csv('/ext/dn-vnstat/csv/WeekThis.htm').then(SetGlobalDataset.bind(null,'CompareUsage_WeekThis'));
	d3.csv('/ext/dn-vnstat/csv/WeekPrev.htm').then(SetGlobalDataset.bind(null,'CompareUsage_WeekPrev'));
	d3.csv('/ext/dn-vnstat/csv/WeekSummary.htm').then(SetGlobalDataset.bind(null,'CompareUsage_WeekSummary'));
}

function SetGlobalDataset(txtchartname,dataobject){
	window[txtchartname] = dataobject;
	currentNoCharts++;
	if(currentNoCharts == maxNoCharts){
		Draw_Chart('DataUsage');
		if(getSummaryInterval($j('#CompareUsage_Interval option:selected').val()) == 'week'){
			Draw_Chart_Summary('CompareUsage');
		}
		else if(getSummaryInterval($j('#CompareUsage_Interval option:selected').val()) == 'day'){
			Draw_Chart_Compare('CompareUsage');
		}
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

function getSummaryInterval(layout){
	var charttype = 'day';
	if(layout == 0) charttype = 'day';
	else if(layout == 1) charttype = 'week';
	return charttype;
}

function changeAllCharts(e){
	value = e.value * 1;
	SetCookie(e.id,value);
	Draw_Chart('DataUsage');
	if(getSummaryInterval($j('#'+name+'_Interval option:selected').val()) == 'week'){
		Draw_Chart_Compare('CompareUsage');
	}
	else if(getSummaryInterval($j('#'+name+'_Interval option:selected').val()) == 'day'){
		Draw_Chart_Summary('CompareUsage');
	}
}

function changeChart(e){
	value = e.value * 1;
	name = e.id.substring(0,e.id.lastIndexOf('_'));
	SetCookie(e.id,value);
	if(name == 'DataUsage'){
		Draw_Chart(name);
	}
	else if(name == 'CompareUsage' && getSummaryInterval($j('#'+name+'_Interval option:selected').val()) == 'week'){
		Draw_Chart_Summary(name);
	}
	else if(name == 'CompareUsage' && getSummaryInterval($j('#'+name+'_Interval option:selected').val()) == 'day'){
		Draw_Chart_Compare(name);
	}
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
