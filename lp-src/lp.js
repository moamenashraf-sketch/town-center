/* Town Center ad pages: UTM capture, tracking, validated form submit. No libraries. */
(function(){
  'use strict';
  var C=window.TC_CONFIG||{}, P=window.TC_PAGE||{slug:'master',lang:'ar',errors:{}};
  var dl=window.dataLayer=window.dataLayer||[];
  function el(id){return document.getElementById(id);}
  function push(o){dl.push(o);}
  function eventId(){return 'evt_'+Date.now().toString(36)+Math.random().toString(36).slice(2,10);}

  /* ---- UTM / click-id capture (persisted for the session) ---- */
  var KEYS=['utm_source','utm_medium','utm_campaign','utm_content','utm_term','gclid','fbclid','sc_click_id'];
  var store={};
  try{store=JSON.parse(sessionStorage.getItem('tc_params')||'{}')||{};}catch(e){store={};}
  try{
    var q=new URLSearchParams(location.search);
    KEYS.forEach(function(k){var v=q.get(k);if(v){store[k]=v.slice(0,200);}});
    sessionStorage.setItem('tc_params',JSON.stringify(store));
  }catch(e){}
  var form=el('leadForm');
  KEYS.forEach(function(k){var i=form&&form.elements[k];if(i&&store[k]){i.value=store[k];}});

  /* ---- Tracking: nothing loads while an ID is empty ---- */
  function loadScript(src){var s=document.createElement('script');s.async=true;s.src=src;document.head.appendChild(s);}
  var mode='none';
  if(C.GTM_ID){
    mode='gtm';
    push({'gtm.start':Date.now(),event:'gtm.js'});
    loadScript('https://www.googletagmanager.com/gtm.js?id='+encodeURIComponent(C.GTM_ID));
  }else{
    if(C.GA4_ID||C.GADS_ID){
      mode='direct';
      window.gtag=function(){dl.push(arguments);};
      loadScript('https://www.googletagmanager.com/gtag/js?id='+encodeURIComponent(C.GA4_ID||C.GADS_ID));
      gtag('js',new Date());
      if(C.GA4_ID){gtag('config',C.GA4_ID);}
      if(C.GADS_ID){gtag('config',C.GADS_ID);}
    }
    if(C.META_PIXEL_ID){
      mode='direct';
      (function(f,b,e,v,n,t,s){if(f.fbq)return;n=f.fbq=function(){n.callMethod?n.callMethod.apply(n,arguments):n.queue.push(arguments);};if(!f._fbq)f._fbq=n;n.push=n;n.loaded=!0;n.version='2.0';n.queue=[];t=b.createElement(e);t.async=!0;t.src=v;s=b.getElementsByTagName(e)[0];s.parentNode.insertBefore(t,s);})(window,document,'script','https://connect.facebook.net/en_US/fbevents.js');
      fbq('init',C.META_PIXEL_ID);fbq('track','PageView');
    }
    if(C.SNAP_PIXEL_ID){
      mode='direct';
      (function(e,t,n){if(e.snaptr)return;var a=e.snaptr=function(){a.handleRequest?a.handleRequest.apply(a,arguments):a.queue.push(arguments);};a.queue=[];var s='script',r=t.createElement(s);r.async=!0;r.src=n;var u=t.getElementsByTagName(s)[0];u.parentNode.insertBefore(r,u);})(window,document,'https://sc-static.net/scevent.min.js');
      snaptr('init',C.SNAP_PIXEL_ID);snaptr('track','PAGE_VIEW');
    }
    if(C.LINKEDIN_ID){
      mode='direct';
      window._linkedin_data_partner_ids=window._linkedin_data_partner_ids||[];
      window._linkedin_data_partner_ids.push(C.LINKEDIN_ID);
      loadScript('https://snap.licdn.com/li.lms-analytics/insight.min.js');
    }
  }

  /* lp_view: category only, never personal data */
  push({event:'lp_view',category:P.slug,language:P.lang});

  /* ---- form_start (first interaction) ---- */
  var started=false;
  function onStart(){if(started)return;started=true;push({event:'form_start',category:P.slug,language:P.lang});}
  if(form){form.addEventListener('focusin',onStart);form.addEventListener('input',onStart);}

  /* ---- Validation ---- */
  var E=P.errors||{};
  function normDigits(s){return String(s).replace(/[٠-٩]/g,function(d){return d.charCodeAt(0)-0x0660;}).replace(/[۰-۹]/g,function(d){return d.charCodeAt(0)-0x06F0;});}
  function normMobile(s){return normDigits(s).replace(/[\s\-().‎‏]/g,'');}
  function validMobile(s){return /^(05\d{8}|\+9665\d{8})$/.test(normMobile(s));}
  function setErr(id,msg,input){
    var p=el('e-'+id);if(!p)return;
    if(msg){p.textContent=msg;p.hidden=false;}else{p.hidden=true;p.textContent='';}
    if(input){if(msg){input.setAttribute('aria-invalid','true');}else{input.removeAttribute('aria-invalid');}}
  }
  function validate(){
    var f=form.elements,first=null,ok=true;
    function bad(id,msg,input){setErr(id,msg,input);ok=false;if(!first)first=input;}
    ['name','business'].forEach(function(n){
      if(!f[n].value.trim()){bad(n,E.required,f[n]);}else{setErr(n,'',f[n]);}
    });
    if(!f.mobile.value.trim()){bad('mobile',E.required,f.mobile);}
    else if(!validMobile(f.mobile.value)){bad('mobile',E.mobile,f.mobile);}
    else{setErr('mobile','',f.mobile);}
    ['category','branches','area','opening'].forEach(function(n){
      if(!f[n].value){bad(n,E.required,f[n]);}else{setErr(n,'',f[n]);}
    });
    if(!form.querySelector('input[name=cr]:checked')){bad('cr',E.required,form.querySelector('input[name=cr]'));}else{setErr('cr','');}
    if(!f.consent.checked){bad('consent',E.consent,f.consent);}else{setErr('consent','',f.consent);}
    if(first){first.focus();}
    return ok;
  }

  /* ---- Submit ---- */
  function showThanks(demo){
    form.hidden=true;
    var t=el('thanks');t.hidden=false;
    if(demo){el('thanksDemo').hidden=false;}
    t.focus();
    var sec=el('form');if(sec&&sec.scrollIntoView){sec.scrollIntoView({block:'start'});}
  }
  function conversions(id,data){
    /* Non-personal data only: category, branches, opening. */
    push({event:'form_submit_success',category:P.slug,language:P.lang,branches:data.branches,opening:data.opening,event_id:id});
    if(mode==='direct'){
      try{
        if(C.GADS_ID&&C.GADS_LABEL&&window.gtag){gtag('event','conversion',{send_to:C.GADS_ID+'/'+C.GADS_LABEL});}
        if(C.GA4_ID&&window.gtag){gtag('event','generate_lead',{category:P.slug});}
        if(C.META_PIXEL_ID&&window.fbq){fbq('track','Lead',{content_category:P.slug},{eventID:id});}
        if(C.SNAP_PIXEL_ID&&window.snaptr){snaptr('track','SIGN_UP');}
        if(C.LINKEDIN_CONVERSION_ID&&window.lintrk){window.lintrk('track',{conversion_id:Number(C.LINKEDIN_CONVERSION_ID)});}
      }catch(e){}
    }
  }
  if(form){
    form.addEventListener('submit',function(ev){
      ev.preventDefault();
      if(!validate())return;
      if(form.elements.website.value){return;} /* honeypot */
      var btn=el('submitBtn'),label=btn.textContent;
      var data={},fd=new FormData(form);
      fd.forEach(function(v,k){data[k]=v;});
      delete data.website;
      data.mobile=normMobile(data.mobile).replace(/^05/,'+9665');
      var id=eventId();
      data.event_id=id;data.page_url=location.href.split('?')[0];data.submitted_at=new Date().toISOString();
      data.consent_contact='yes';
      el('e-form').hidden=true;
      if(!C.FORM_ENDPOINT){conversions(id,data);showThanks(true);return;}
      btn.disabled=true;btn.textContent=P.sending||'…';
      fetch(C.FORM_ENDPOINT,{method:'POST',headers:{'Content-Type':'application/json','Accept':'application/json'},body:JSON.stringify(data)})
        .then(function(r){if(!r.ok)throw new Error(r.status);conversions(id,data);showThanks(false);})
        .catch(function(){var m=el('e-form');m.textContent=E.submit||'Error';m.hidden=false;btn.disabled=false;btn.textContent=label;});
    });
  }

  /* ---- Direct contact block (off by default) ---- */
  if(C.SHOW_DIRECT_CONTACT){
    var d=el('direct');
    if(d){
      d.innerHTML='<a href="tel:'+C.CONTACT_PHONE+'" data-track="call" dir="ltr">'+(C.CONTACT_PHONE_LABEL||C.CONTACT_PHONE)+'</a><a href="mailto:'+C.CONTACT_EMAIL+'" data-track="email">'+C.CONTACT_EMAIL+'</a>';
      d.hidden=false;
      d.addEventListener('click',function(e){var a=e.target.closest('a[data-track]');if(a){push({event:'contact_click',method:a.getAttribute('data-track'),category:P.slug});}});
    }
  }
  /* CTA click event */
  document.addEventListener('click',function(e){if(e.target.closest('[data-cta]')){push({event:'cta_click',category:P.slug});}});
})();
