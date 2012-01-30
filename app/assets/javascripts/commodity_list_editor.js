$(document).ready(function() {
    $('#add_commodity').click(function() {
        $('#avail_commodity option:selected').clone().appendTo('#commodity_list');
        //remove duplicates
        map = {};
        $('#commodity_list option').each(function(){
            var value = $(this).text();
            if (map[value] == null){
                map[value] = true;
            } else {
                $(this).remove();
            }
        });
        nb_selected();
        // Sort by name
        $("#commodity_list").html($("#commodity_list option").sort(function (a, b) {
          return a.text == b.text ? 0 : a.text < b.text ? -1 : 1;
        }));
    });
    $('#remove_commodity').click(function() {
        !$('#commodity_list option:selected').remove();
        return nb_selected();
    });
    // Flow Editor
    $('#flow_editor_cancel').click(function() {
        $.unblockUI();
        return false;
    });

});

function nb_selected(){
    $("#nb_commodity").html("Commodity selected ("+$('#commodity_list option').size()+")");
    return true;
}

function fill_avail_commodities(commodities_path,filter){
    var options = "";
    $.getJSON(commodities_path + '.js', {'filter':filter}, function(j){
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
        $('#avail_commodity').html(options);
    })

}

function fill_aggregate(aggregate_path){
    $.getJSON(aggregate_path + '.js', function(j){
      var options = "";
      var c = j.aggregate.commodities;
      for(var i = 0; i < c.length; i++) {
        options += '<option>' + c[i].name + '</option>';
      }
      $('#commodity_list').html(options);
      nb_selected();
      $("#commodity_list").html($("#commodity_list option").sort(function (a, b) {
        return a.text == b.text ? 0 : a.text < b.text ? -1 : 1;
      }));
    });
  }

// Flow Editor

function add_flow(flows_path,commodities_path,flow_type,tech_id){
    fill_avail_commodities(commodities_path);
    $('#commodity_list').html('');
    $('#filter_commodity').val('');
    $('#flow_editor_title').text('New ' + flow_type);
    $('#flow_apply').text('Add');
    $('#flow_apply').click(function() {
        var com = $('#commodity_list option');
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
            width: '600px',
            border: '0px',
            background: 'none'
        }
    });
}
function edit_flow(flow_path,commodities_path,flow_type,id){
    fill_avail_commodities(commodities_path);
    $('#filter_commodity').val('');
    $.getJSON(flow_path + '.js', function(j){
        var options = "";
        var c = j.flow.commodities;
        for(var i = 0; i < c.length; i++) {
            options += '<option>' + c[i].name + '</option>';
        }
        $('#commodity_list').html(options);
    });
    $('#flow_editor_title').text('Edit '+flow_type+' (' + id + ')');
    $('#flow_apply').text('Update');
    $('#flow_apply').click(function() {
        var com = $('#commodity_list option');
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