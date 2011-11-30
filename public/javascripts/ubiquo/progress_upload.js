  Event.observe(window, 'load',
  function() {
    try
    {
    //if (self.parent.frames.length != 0)
    //self.parent.location=document.location;
    }
    catch (Exception) {}
  }
);

$(document).observe('dom:loaded', function(){
$('asset_submit').observe('click', function() {


    $('progress').show();

    //add iframe and set form target to this iframe
    $$("body").first().insert({bottom: "<iframe name='progressFrame' style='display:none; width:0; height:0; position: absolute; top:30000px;'></iframe>"});    
    $(this).up('form').writeAttribute("target", "progressFrame");

    $(this).up('form').submit();


  var progress_bar = new Control.ProgressBar('progress_bar',{  
    interval: 0.15  
  }); 

    //update the progress bar
    var uuid = $('X-Progress-ID').value;
    new PeriodicalExecuter(
      function(){
  
        if(Ajax.activeRequestCount == 0){
          new Ajax.Request("/progress",{
            method: 'get',
            parameters: 'X-Progress-ID=' + uuid,
            onSuccess: function(xhr){
              var upload = xhr.responseText.evalJSON();
              if(upload.state == 'uploading'){
                upload.percent = Math.floor((upload.received / upload.size) * 100);
                $('numeric_bar').setStyle({width: upload.percent + "%"});
                $('numeric_bar').update(upload.percent + "%");
                progress_bar.setProgress(upload.percent);
                if(upload.percent == 100) {
                  $('processing_container').show();
                  $('uploading_container').hide();
                }
              }else if(upload.state == 'done'){
                document.location = '/ubiquo/assets';
              }
            }
          })
        }
      },2);

    return false; 

});
});
