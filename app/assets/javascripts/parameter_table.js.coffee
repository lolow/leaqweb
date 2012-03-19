$(document).ready ->

  $('.check_all').click ->
    $(this).parents('table:eq(0)').find(':checkbox').attr('checked', this.checked)

  $('.add_pv').click ->
    form = $(this).parents('form:eq(0)')
    form.find('#do').attr('value','add_pv')
    form.submit()

  $('.delete_pv').click ->
    if confirm("Are you sure?")
       form = $(this).parents('form:eq(0)')
       form.find('#do').attr('value','delete_pv')
       form.submit()