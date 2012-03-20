$(document).ready ->

  $('.add_ddv').click ->
    form = $(this).parents('form:eq(0)')
    form.find('#do').attr('value','add_ddv')
    form.submit()

  $('.delete_ddv').click ->
    if confirm("Are you sure?")
       form = $(this).parents('form:eq(0)')
       form.find('#do').attr('value','delete_ddv')
       form.submit()