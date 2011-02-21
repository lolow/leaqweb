$(document).ready(function() {
    $('#add_commodity').click(function() {
        return !$('#sel_avail_commodity option:selected').clone().appendTo('#components');
    });
    $('#remove_commodity').click(function() {
        return !$('#components option:selected').remove();
    });
});

function post_form(){
  $('#components').each(function(){
    $("#components option").attr("selected","selected");
  });
  $('#form_component').submit();
}