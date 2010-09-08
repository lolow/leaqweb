$(document).ready(function() {
    $('#add_commodity_flow').click(function() {
        return !$('#sel_avail_commodity option:selected').clone().appendTo('#sel_flow_commodity');
    });
    $('#remove_commodity_flow').click(function() {
        return !$('#sel_flow_commodity option:selected').remove();
    });
    $('#cancel').click(function() {
        $.unblockUI();
        return false;
    });
});
function add_flow(flows_path,flow_type,tech_id){
    $('#sel_flow_commodity').html("");
    $('#flow_editor_title').text('New ' + flow_type);
    $('#flow_editor_button').attr('value','Add');
    $('#flow_editor_button').click(function() {
        var com = $('#sel_flow_commodity option');
        var s = "";
        for(var i = 0; i < com.length; i++) {
            s += com[i].text + ",";
        }
        $.ajax({
            url:flows_path,
            type:'POST',
            data:{
                'commodities':s.substring(0,s.length-1),
                'technology_id': tech_id,
                'type':flow_type
            },
            async:false
        });
        location.reload();
    });
    $.blockUI({
        message: $('#flow_editor'),
        css: {
            width: '500px',
            border: '0px',
            background: 'none'
        }
    });
}
function edit_flow(flow_path,flow_type,id){
    $.getJSON(flow_path + '.js', function(j){
        var options = "";
        var c = j.flow.commodities;
        for(var i = 0; i < c.length; i++) {
            options += '<option>' + c[i].commodity.name + '</option>';
        }
        $('#sel_flow_commodity').html(options);
    })
    $('#flow_editor_title').text('Edit '+flow_type+' (' + id + ')');
    $('#flow_editor_button').attr('value','Update');
    $('#flow_editor_button').click(function() {
        var com = $('#sel_flow_commodity option');
        var s = "";
        for(var i = 0; i < com.length; i++) {
            s += com[i].text + ",";
        }
        $.ajax({
            url:flow_path,
            type:'PUT',
            data:{
                'commodities':s.substring(0,s.length-1)
                },
            async:false
        });
        location.reload();
    });
    $.blockUI({
        message: $('#flow_editor'),
        css: {
            width: '500px',
            border: '0px',
            background: 'none'
        }
    });
}