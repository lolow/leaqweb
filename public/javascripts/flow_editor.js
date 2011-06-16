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
function fill_avail_commodities(commodities_path){
    var options = "";
    $.getJSON(commodities_path + '.js', function(j){
        options += '<optgroup label="Energy Carriers">'
        var c = j.enc;
        for(var i = 0; i < c.length; i++) {
          options += '<option>' + c[i] + '</option>';
        }
        options += '</optgroup>'
        options += '<optgroup label="Pollutants">'
        var c = j.poll;
        for(var i = 0; i < c.length; i++) {
          options += '<option>' + c[i] + '</option>';
        }
        options += '</optgroup>'
        options += '<optgroup label="Demands">'
        var c = j.dem;
        for(var i = 0; i < c.length; i++) {
          options += '<option>' + c[i] + '</option>';
        }
        options += '</optgroup>';
        $('#sel_avail_commodity').html(options);
    })

}
function add_flow(flows_path,commodities_path,flow_type,tech_id){
    fill_avail_commodities(commodities_path);
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
function edit_flow(flow_path,commodities_path,flow_type,id){
    fill_avail_commodities(commodities_path);
    $.getJSON(flow_path + '.js', function(j){
        var options = "";
        var c = j.flow.commodities;
        for(var i = 0; i < c.length; i++) {
            options += '<option>' + c[i].commodity.name + '</option>';
        }
        $('#sel_flow_commodity').html(options);
    });
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