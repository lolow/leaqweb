$(document).ready(function() {
  $('.check_all').click(function () {
    $(this).parents('table:eq(0)').find(':checkbox').attr('checked', this.checked);
  });
  $('.add_pv').click(function () {
    var form = $(this).parents('form:eq(0)');
    form.find('#do').attr('value','add_pv');
    form.submit();
  });
  $('.delete_pv').click(function () {
    if (confirm("Are you sure?")) {
      var form = $(this).parents('form:eq(0)');
      form.find('#do').attr('value','delete_pv');
      form.submit();
    };
  })
} );