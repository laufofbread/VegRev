/**
 * hashgrid (jQuery version)
 * http://github.com/dotjay/hashgrid
 * Version 7, 10 Jun 2011
 * Written by Jon Gibbins at Analog, http://analog.coop/
 *
 * Licensed under the Apache License, Version 2.0
 * Copyright 2011 Analog Coop Limited
 *
 * Contibutors:
 * Sean Coates, http://seancoates.com/
 * Phil Dokas, http://jetless.org/
 * Andrew Jaswa, http://andrewjaswa.com/
 */
var hashgrid=function(set){var options={id:'grid',modifierKey:null,showGridKey:'g',holdGridKey:'h',foregroundKey:'f',jumpGridsKey:'j',numberOfGrids:1,classPrefix:'grid-',cookiePrefix:'hashgrid'},classNumber=1,gridLines,gridWidth,i,line,lineHeight,numGridLines,overlay,overlayCookie,overlayEl,overlayOn=false,overlayVert,overlayZState='B',overlayZBackground=-1,overlayZForeground=9999,pageHeight,setKey,state,sticky=false,top;if(typeof set=='object'){for(setKey in set){options[setKey]=set[setKey];}}else if(typeof set=='string'){options.id=set;}if($('#'+options.id).length>0){$('#'+options.id).remove();}overlayEl=$('<div></div>');overlayEl.attr('id',options.id).css({display:'none','pointer-events':'none'});$("body").prepend(overlayEl);overlay=$('#'+options.id);if(overlay.css('z-index')=='auto')overlay.css('z-index',overlayZBackground);pageHeight=parseFloat($(document).height());overlay.height(pageHeight);overlay.append('<div id="'+options.id+'-horiz" class="horiz first-line">');top=overlay.css("top");overlay.css({top:"-999px",display:"block"});line=$('#'+options.id+'-horiz');lineHeight=line.outerHeight();overlay.css({display:"none",top:top});if(lineHeight<=0){return false;}numGridLines=Math.floor(pageHeight/lineHeight);gridLines='';for(i=numGridLines-1;i>=1;i--){gridLines+='<div class="horiz"></div>';}overlay.append(gridLines);overlay.append($('<div class="vert-container"></div>'));overlayVert=overlay.children('.vert-container');gridWidth=overlay.width();overlayVert.css({width:gridWidth,position:'absolute',top:0});overlayVert.append('<div class="vert first-line">&nbsp;</div>');gridLines='';for(i=0;i<30;i++){gridLines+='<div class="vert">&nbsp;</div>';}overlayVert.append(gridLines);overlayVert.children().height(pageHeight).css({display:'inline-block'});overlayCookie=readCookie(options.cookiePrefix+options.id);if(typeof overlayCookie=='string'){state=overlayCookie.split(',');state[2]=Number(state[2]);if((typeof state[2]=='number')&&!isNaN(state[2])){classNumber=state[2].toFixed(0);overlay.addClass(options.classPrefix+classNumber);}if(state[1]=='F'){overlayZState='F';overlay.css('z-index',overlayZForeground);}if(state[0]=='1'){overlayOn=true;sticky=true;showOverlay();}}else{overlay.addClass(options.classPrefix+classNumber);}$(document).bind('keydown',keydownHandler);$(document).bind('keyup',keyupHandler);function getModifier(e){if(options.modifierKey==null)return true;var m=true;switch(options.modifierKey){case'ctrl':m=(e.ctrlKey?e.ctrlKey:false);break;case'alt':m=(e.altKey?e.altKey:false);break;case'shift':m=(e.shiftKey?e.shiftKey:false);break;}return m;}function getKey(e){var k=false,c=(e.keyCode?e.keyCode:e.which);if(c==13)k='enter';else k=String.fromCharCode(c).toLowerCase();return k;}function saveState(){createCookie(options.cookiePrefix+options.id,(sticky?'1':'0')+','+overlayZState+','+classNumber,1);}function showOverlay(){overlay.show();overlayVert.css({width:overlay.width()});overlayVert.children('.vert').each(function(){$(this).css('display','inline-block');if($(this).offset().top>0){$(this).hide();}});}function keydownHandler(e){var k,m,source=e.target.tagName.toLowerCase();if((source=='input')||(source=='textarea')||(source=='select')){return true;}m=getModifier(e);if(!m){return true;}k=getKey(e);if(!k){return true;}switch(k){case options.showGridKey:if(!overlayOn){showOverlay();overlayOn=true;}else if(sticky){overlay.hide();overlayOn=false;sticky=false;saveState();}break;case options.holdGridKey:if(overlayOn&&!sticky){sticky=true;saveState();}break;case options.foregroundKey:if(overlayOn){if(overlay.css('z-index')==overlayZForeground){overlay.css('z-index',overlayZBackground);overlayZState='B';}else{overlay.css('z-index',overlayZForeground);overlayZState='F';}saveState();}break;case options.jumpGridsKey:if(overlayOn&&(options.numberOfGrids>1)){overlay.removeClass(options.classPrefix+classNumber);classNumber++;if(classNumber>options.numberOfGrids)classNumber=1;overlay.addClass(options.classPrefix+classNumber);showOverlay();if(/webkit/.test(navigator.userAgent.toLowerCase())){forceRepaint();}saveState();}break;}return true;}function keyupHandler(e){var k,m=getModifier(e);if(!m){return true;}k=getKey(e);if(k&&(k==options.showGridKey)&&!sticky){overlay.hide();overlayOn=false;}return true;}function createCookie(name,value,days){var date,expires="";if(days){date=new Date();date.setTime(date.getTime()+(days*24*60*60*1000));expires="; expires="+date.toGMTString();}document.cookie=name+"="+value+expires+"; path=/";}function readCookie(name){var c,ca=document.cookie.split(';'),i=0,len=ca.length,nameEQ=name+"=";for(;i<len;i++){c=ca[i];while(c.charAt(0)==' '){c=c.substring(1,c.length);}if(c.indexOf(nameEQ)==0){return c.substring(nameEQ.length,c.length);}}return null;}function eraseCookie(name){createCookie(name,"",-1);}function forceRepaint(){var ss=document.styleSheets[0];try{ss.addRule('.xxxxxx','position: relative');ss.removeRule(ss.rules.length-1);}catch(e){}}return{};};